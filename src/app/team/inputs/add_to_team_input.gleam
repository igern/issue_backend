import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}

pub type AddToTeamInput {
  AddToTeamInput(profile_id: String)
}

pub fn from_dynamic(
  json: Dynamic,
) -> Result(AddToTeamInput, dynamic.DecodeErrors) {
  json
  |> dynamic.decode1(
    AddToTeamInput,
    dynamic.field("profile_id", dynamic.string),
  )
}

pub fn to_json(input: AddToTeamInput) -> Json {
  json.object([#("profile_id", json.string(input.profile_id))])
}
