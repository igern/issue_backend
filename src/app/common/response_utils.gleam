import gleam/dynamic
import gleam/json
import gleam/string
import wisp.{type Response}

pub fn map_service_errors(
  result: Result(a, ServiceError),
  next: fn(a) -> Response,
) -> Response {
  case result {
    Error(IssueNotFoundError) -> issue_not_found_error_response()
    Error(RefreshTokenExpiredError) -> refresh_token_expired_error_response()
    Error(RefreshTokenNotFoundError) -> refresh_token_not_found_error_response()
    Error(InvalidCredentialsError) -> invalid_credentials_response()
    Error(DatabaseError) -> database_error_response()
    Ok(a) -> next(a)
  }
}

pub type ServiceError {
  IssueNotFoundError
  RefreshTokenExpiredError
  RefreshTokenNotFoundError
  InvalidCredentialsError
  DatabaseError
}

pub fn invalid_credentials_response() {
  json_response(400, "invalid credentials")
}

pub fn database_error_response() {
  json_response(503, "database error")
}

pub fn refresh_token_not_found_error_response() {
  json_response(404, "refresh token not found")
}

pub fn refresh_token_expired_error_response() {
  json_response(400, "refresh token expired")
}

pub fn issue_not_found_error_response() {
  json_response(404, "issue not found")
}

pub fn or_400(
  result: Result(value, error),
  next: fn(value) -> Response,
) -> Response {
  case result {
    Ok(value) -> next(value)
    Error(_) -> wisp.bad_request()
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
  |> json.to_string_builder()
  |> wisp.json_response(code)
}
