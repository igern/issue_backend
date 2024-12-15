import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}

pub type CreateProfileInput {
  CreateProfileInput(name: String)
}

pub fn from_dynamic(
  json: Dynamic,
) -> Result(CreateProfileInput, dynamic.DecodeErrors) {
  json
  |> dynamic.decode1(CreateProfileInput, dynamic.field("name", dynamic.string))
}

pub fn to_json(input: CreateProfileInput) -> Json {
  json.object([#("name", json.string(input.name))])
}
