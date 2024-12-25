import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}
import gleam/option

pub type Issue {
  Issue(
    id: String,
    name: String,
    description: option.Option(String),
    creator_id: String,
    directory_id: String,
  )
}

pub fn decoder() {
  dynamic.decode5(
    Issue,
    dynamic.field("id", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("description", dynamic.optional(dynamic.string)),
    dynamic.field("creator_id", dynamic.string),
    dynamic.field("directory_id", dynamic.string),
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
    #("description", json.nullable(issue.description, json.string)),
    #("creator_id", json.string(issue.creator_id)),
    #("directory_id", json.string(issue.directory_id)),
  ])
}
