import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json.{type Json}

pub type CreateTeamInput {
  CreateTeamInput(name: String)
}

fn create_team_input_decoder() -> decode.Decoder(CreateTeamInput) {
  use name <- decode.field("name", decode.string)
  decode.success(CreateTeamInput(name:))
}

pub fn from_dynamic(
  json: Dynamic,
) -> Result(CreateTeamInput, List(decode.DecodeError)) {
  decode.run(json, create_team_input_decoder())
}

pub fn to_json(input: CreateTeamInput) -> Json {
  json.object([#("name", json.string(input.name))])
}
