import app/common/valid
import gleam/dynamic
import gleam/dynamic/decode
import gleam/json

pub type CreateDirectoryStatusInput {
  CreateDirectoryStatusInput(name: String)
}

fn create_directory_status_input_decoder() -> decode.Decoder(
  CreateDirectoryStatusInput,
) {
  use name <- decode.field("name", decode.string)
  decode.success(CreateDirectoryStatusInput(name:))
}

pub fn from_dynamic(
  json: dynamic.Dynamic,
) -> Result(CreateDirectoryStatusInput, List(decode.DecodeError)) {
  decode.run(json, create_directory_status_input_decoder())
}

pub fn to_json(
  create_directory_status_input: CreateDirectoryStatusInput,
) -> json.Json {
  json.object([#("name", json.string(create_directory_status_input.name))])
}

pub fn validate(input: CreateDirectoryStatusInput) {
  let valid_name = valid.validate_min_length(input.name, 2)

  valid.checks_to_validated(input, [#("name", valid_name)])
}
