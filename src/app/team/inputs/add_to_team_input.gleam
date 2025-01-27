import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json.{type Json}

pub type AddToTeamInput {
  AddToTeamInput(profile_id: String)
}

fn add_to_team_input_decoder() -> decode.Decoder(AddToTeamInput) {
  use profile_id <- decode.field("profile_id", decode.string)
  decode.success(AddToTeamInput(profile_id:))
}

pub fn from_dynamic(json: Dynamic) {
  decode.run(json, add_to_team_input_decoder())
}

pub fn to_json(input: AddToTeamInput) -> Json {
  json.object([#("profile_id", json.string(input.profile_id))])
}
