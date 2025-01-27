import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json.{type Json}

pub type CreateDirectoryInput {
  CreateDirectoryInput(name: String)
}

fn create_directory_input_decoder() -> decode.Decoder(CreateDirectoryInput) {
  use name <- decode.field("name", decode.string)
  decode.success(CreateDirectoryInput(name:))
}

pub fn from_dynamic(
  json: Dynamic,
) -> Result(CreateDirectoryInput, List(decode.DecodeError)) {
  decode.run(json, create_directory_input_decoder())
}

pub fn to_json(input: CreateDirectoryInput) -> Json {
  json.object([#("name", json.string(input.name))])
}
