import app/common/valid
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json.{type Json}

pub type LoginInput {
  LoginInput(email: String, password: String)
}

fn login_input_decoder() -> decode.Decoder(LoginInput) {
  use email <- decode.field("email", decode.string)
  use password <- decode.field("password", decode.string)
  decode.success(LoginInput(email:, password:))
}

pub fn from_dynamic(
  json: Dynamic,
) -> Result(LoginInput, List(decode.DecodeError)) {
  decode.run(json, login_input_decoder())
}

pub fn to_json(input: LoginInput) -> Json {
  json.object([
    #("email", json.string(input.email)),
    #("password", json.string(input.password)),
  ])
}

pub fn validate(input: LoginInput) {
  let valid_email = valid.validate_email(input.email)
  let valid_password = valid.validate_password(input.password)

  valid.checks_to_validated(input, [
    #("email", valid_email),
    #("password", valid_password),
  ])
}
