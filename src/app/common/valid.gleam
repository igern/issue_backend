import app/common/response_utils
import gleam/int
import gleam/list
import gleam/option
import gleam/string
import wisp
import youid/uuid

pub type Validated(a) =
  Result(Valid(a), Invalid(a))

pub opaque type Valid(a) {
  Valid(a)
}

pub opaque type Invalid(a) {
  Invalid(a, List(String))
}

pub fn inner(valid: Valid(a)) -> a {
  let Valid(inner) = valid
  inner
}

pub opaque type Check {
  Check(option.Option(String))
}

pub fn or_validation_error(
  validated_input: Validated(a),
  valid_callback: fn(Valid(a)) -> wisp.Response,
) {
  case validated_input {
    Error(Invalid(_, errors)) ->
      response_utils.json_response(400, string.join(errors, ", "))
    Ok(Valid(input)) -> valid_callback(Valid(input))
  }
}

pub fn checks_to_validated(input: a, checks: List(#(String, Check))) {
  let assert [_, ..] = checks as "Minimum 1 check required"
  let checks =
    list.fold(checks, [], fn(arr, current) {
      let #(field, check) = current
      case check {
        Check(option.Some(error)) -> [#(field, error), ..arr]
        Check(option.None) -> arr
      }
    })

  case list.length(checks) {
    0 -> Ok(Valid(input))
    _ -> {
      let errors =
        list.map(checks, fn(check) {
          let #(field, error) = check
          field <> ": " <> error
        })

      Error(Invalid(input, errors))
    }
  }
}

pub fn validate_min(input: Int, min: Int) -> Check {
  case input >= min {
    True -> Check(option.None)
    False -> Check(option.Some("must be atleast " <> int.to_string(min)))
  }
}

pub fn validate_email(input: String) -> Check {
  case string.contains(input, "@") {
    True -> Check(option.None)
    False -> Check(option.Some("invalid"))
  }
}

pub fn validate_password(input: String) -> Check {
  case string.length(input) >= 8 {
    True -> Check(option.None)
    False -> Check(option.Some("must be atleast 8 character"))
  }
}

pub fn validate_uuid(input: String) -> Check {
  case uuid.from_string(input) {
    Ok(_) -> Check(option.None)
    Error(_) -> Check(option.Some("invalid"))
  }
}

pub fn validate_min_length(input: String, min_length: Int) {
  case string.length(input) >= min_length {
    True -> Check(option.None)
    False ->
      Check(option.Some(
        "must be atleast " <> int.to_string(min_length) <> " characters long",
      ))
  }
}

pub fn validate_optional_min_length(
  input: option.Option(String),
  min_length: Int,
) {
  case input {
    option.Some(input) -> {
      case string.length(input) >= min_length {
        True -> Check(option.None)
        False ->
          Check(option.Some(
            "must be atleast "
            <> int.to_string(min_length)
            <> " characters long",
          ))
      }
    }
    option.None -> Check(option.None)
  }
}
