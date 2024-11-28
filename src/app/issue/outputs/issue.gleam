import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}

pub type Issue {
  Issue(id: Int, name: String, creator_id: Int)
}

pub fn decoder() {
  dynamic.decode3(
    Issue,
    dynamic.field("id", dynamic.int),
    dynamic.field("name", dynamic.string),
    dynamic.field("creator_id", dynamic.int),
  )
}

pub fn from_dynamic(json: Dynamic) -> Result(Issue, dynamic.DecodeErrors) {
  json
  |> decoder()
}

pub fn to_json(issue: Issue) -> Json {
  json.object([
    #("id", json.int(issue.id)),
    #("name", json.string(issue.name)),
    #("creator_id", json.int(issue.creator_id)),
  ])
}
