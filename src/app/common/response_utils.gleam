import gleam/dynamic
import gleam/json
import gleam/string
import sqlight
import wisp.{type Response}

pub fn map_service_errors(
  result: Result(a, ServiceError),
  next: fn(a) -> Response,
) -> Response {
  case result {
    Error(UserNotFoundError) -> user_not_found_error_response()
    Error(ProfileNotFoundError) -> profile_not_found_error_response()
    Error(IssueNotFoundError) -> issue_not_found_error_response()
    Error(RefreshTokenExpiredError) -> refresh_token_expired_error_response()
    Error(RefreshTokenNotFoundError) -> refresh_token_not_found_error_response()
    Error(InvalidCredentialsError) -> invalid_credentials_response()
    Error(DatabaseError(error)) -> {
      wisp.log_error(string.inspect(error))
      database_error_response()
    }
    Ok(a) -> next(a)
  }
}

pub type ServiceError {
  UserNotFoundError
  ProfileNotFoundError
  IssueNotFoundError
  RefreshTokenExpiredError
  RefreshTokenNotFoundError
  InvalidCredentialsError
  DatabaseError(sqlight.Error)
}

pub fn invalid_credentials_response() {
  json_response(400, "invalid credentials")
}

pub fn refresh_token_expired_error_response() {
  json_response(400, "refresh token expired")
}

pub fn missing_authorization_header_response() {
  json_response(401, "missing authorization header")
}

pub fn invalid_bearer_format_response() {
  json_response(401, "invalid bearer format")
}

pub fn invalid_jwt_response() {
  json_response(401, "invalid jwt")
}

pub fn profile_required_response() {
  json_response(403, "profile required")
}

pub fn can_not_delete_other_user_response() {
  json_response(403, "can not delete other user")
}

pub fn refresh_token_not_found_error_response() {
  json_response(404, "refresh token not found")
}

pub fn user_not_found_error_response() {
  json_response(404, "user not found")
}

pub fn issue_not_found_error_response() {
  json_response(404, "issue not found")
}

pub fn profile_not_found_error_response() {
  json_response(404, "profile not found")
}

pub fn database_error_response() {
  json_response(503, "database error")
}

pub fn or_response(
  result: Result(a, b),
  error: Response,
  handle: fn(a) -> Response,
) {
  case result {
    Ok(result) -> handle(result)
    Error(_) -> error
  }
}

pub fn or_decode_error(
  result: Result(value, dynamic.DecodeErrors),
  next: fn(value) -> Response,
) -> Response {
  case result {
    Ok(value) -> next(value)
    Error(decode_errors) -> {
      let assert [first_error, ..] = decode_errors
      let message = case first_error.path {
        [] ->
          "expected: " <> first_error.expected <> " got: " <> first_error.found
        _ -> "missing " <> string.concat(first_error.path)
      }
      json_response(400, message)
    }
  }
}

pub fn json_response(code: Int, message: String) {
  json.object([#("code", json.int(code)), #("message", json.string(message))])
  |> json.to_string_tree()
  |> wisp.json_response(code)
}
