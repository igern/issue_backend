import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}

pub type CreateDirectoryInput {
  CreateDirectoryInput(name: String)
}

pub fn from_dynamic(
  json: Dynamic,
) -> Result(CreateDirectoryInput, dynamic.DecodeErrors) {
  json
  |> dynamic.decode1(
    CreateDirectoryInput,
    dynamic.field("name", dynamic.string),
  )
}

pub fn to_json(input: CreateDirectoryInput) -> Json {
  json.object([#("name", json.string(input.name))])
}
