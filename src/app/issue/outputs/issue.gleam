import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}

pub type Issue {
  Issue(id: String, name: String, creator_id: String)
}

pub fn decoder() {
  dynamic.decode3(
    Issue,
    dynamic.field("id", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("creator_id", dynamic.string),
  )
}

pub fn from_dynamic(json: Dynamic) -> Result(Issue, dynamic.DecodeErrors) {
  json
  |> decoder()
}

pub fn to_json(issue: Issue) -> Json {
  json.object([
    #("id", json.string(issue.id)),
    #("name", json.string(issue.name)),
    #("creator_id", json.string(issue.creator_id)),
  ])
}
