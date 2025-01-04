import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}

pub type CreateTeamInput {
  CreateTeamInput(name: String)
}

pub fn from_dynamic(
  json: Dynamic,
) -> Result(CreateTeamInput, dynamic.DecodeErrors) {
  json
  |> dynamic.decode1(CreateTeamInput, dynamic.field("name", dynamic.string))
}

pub fn to_json(input: CreateTeamInput) -> Json {
  json.object([#("name", json.string(input.name))])
}
