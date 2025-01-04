import gleam/dynamic.{type Dynamic}
import gleam/json

pub type Team {
  Team(id: String, name: String, owner_id: String)
}

pub fn decoder() {
  dynamic.decode3(
    Team,
    dynamic.field("id", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("owner_id", dynamic.string),
  )
}

pub fn from_dynamic(json: Dynamic) -> Result(Team, dynamic.DecodeErrors) {
  json |> decoder()
}

pub fn to_json(team: Team) {
  json.object([
    #("id", json.string(team.id)),
    #("name", json.string(team.name)),
    #("owner_id", json.string(team.owner_id)),
  ])
}
