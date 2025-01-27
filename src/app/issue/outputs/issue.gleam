import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
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

pub fn decoder() -> decode.Decoder(Issue) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  use creator_id <- decode.field("creator_id", decode.string)
  use directory_id <- decode.field("directory_id", decode.string)
  decode.success(Issue(id:, name:, description:, creator_id:, directory_id:))
}

pub fn from_dynamic(json: Dynamic) -> Result(Issue, List(decode.DecodeError)) {
  decode.run(json, decoder())
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
