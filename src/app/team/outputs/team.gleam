import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json

pub type Team {
  Team(id: String, name: String, owner_id: String)
}

pub fn decoder() -> decode.Decoder(Team) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use owner_id <- decode.field("owner_id", decode.string)
  decode.success(Team(id:, name:, owner_id:))
}

pub fn from_dynamic(json: Dynamic) -> Result(Team, List(decode.DecodeError)) {
  decode.run(json, decoder())
}

pub fn to_json(team: Team) {
  json.object([
    #("id", json.string(team.id)),
    #("name", json.string(team.name)),
    #("owner_id", json.string(team.owner_id)),
  ])
}
