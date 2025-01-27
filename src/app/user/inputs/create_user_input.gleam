import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json.{type Json}

pub type CreateUserInput {
  CreateUserInput(email: String, password: String)
}

fn create_user_input_decoder() -> decode.Decoder(CreateUserInput) {
  use email <- decode.field("email", decode.string)
  use password <- decode.field("password", decode.string)
  decode.success(CreateUserInput(email:, password:))
}

pub fn from_dynamic(
  json: Dynamic,
) -> Result(CreateUserInput, List(decode.DecodeError)) {
  decode.run(json, create_user_input_decoder())
}

pub fn to_json(input: CreateUserInput) -> Json {
  json.object([
    #("email", json.string(input.email)),
    #("password", json.string(input.password)),
  ])
}
