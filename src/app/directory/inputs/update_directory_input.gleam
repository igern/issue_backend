import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json.{type Json}

pub type UpdateDirectoryInput {
  UpdateDirectoryInput(name: String)
}

fn update_directory_input_decoder() -> decode.Decoder(UpdateDirectoryInput) {
  use name <- decode.field("name", decode.string)
  decode.success(UpdateDirectoryInput(name:))
}

pub fn from_dynamic(json: Dynamic) {
  decode.run(json, update_directory_input_decoder())
}

pub fn to_json(input: UpdateDirectoryInput) -> Json {
  json.object([#("name", json.string(input.name))])
}
