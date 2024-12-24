import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}

pub type UpdateDirectoryInput {
  UpdateDirectoryInput(name: String)
}

pub fn from_dynamic(
  json: Dynamic,
) -> Result(UpdateDirectoryInput, dynamic.DecodeErrors) {
  json
  |> dynamic.decode1(
    UpdateDirectoryInput,
    dynamic.field("name", dynamic.string),
  )
}

pub fn to_json(input: UpdateDirectoryInput) -> Json {
  json.object([#("name", json.string(input.name))])
}
