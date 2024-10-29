import gleam/dynamic
import gleam/json
import gleam/string
import wisp.{type Response}

pub fn map_service_errors(
  result: Result(a, ServiceError),
  next: fn(a) -> Response,
) -> Response {
  case result {
    Error(InvalidCredentialsError) -> invalid_credentials_response()
    Error(DatabaseError) -> database_error_response()
    Ok(a) -> next(a)
  }
}

pub type ServiceError {
  InvalidCredentialsError
  DatabaseError
}

pub fn invalid_credentials_response() {
  json_response(400, "invalid credentials")
}

pub fn database_error_response() {
  json_response(503, "database error")
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
