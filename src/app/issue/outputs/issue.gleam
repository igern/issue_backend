import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}

pub type Issue {
  Issue(id: Int, name: String)
}

pub fn decoder() {
  dynamic.decode2(
    Issue,
    dynamic.field("id", dynamic.int),
    dynamic.field("name", dynamic.string),
  )
}

pub fn from_dynamic(json: Dynamic) -> Result(Issue, dynamic.DecodeErrors) {
  json
  |> decoder()
}

pub fn to_json(issue: Issue) -> Json {
  json.object([#("id", json.int(issue.id)), #("name", json.string(issue.name))])
}
