import app/common/valid
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json.{type Json}

pub type CreateProfileInput {
  CreateProfileInput(name: String)
}

fn create_profile_input_decoder() -> decode.Decoder(CreateProfileInput) {
  use name <- decode.field("name", decode.string)
  decode.success(CreateProfileInput(name:))
}

pub fn from_dynamic(
  json: Dynamic,
) -> Result(CreateProfileInput, List(decode.DecodeError)) {
  decode.run(json, create_profile_input_decoder())
}

pub fn to_json(input: CreateProfileInput) -> Json {
  json.object([#("name", json.string(input.name))])
}

pub fn validate(
  input: CreateProfileInput,
) -> valid.Validated(CreateProfileInput) {
  let valid_name = valid.validate_min_length(input.name, 2)

  valid.checks_to_validated(input, [#("name", valid_name)])
}
