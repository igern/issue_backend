import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}
import gleam/option

pub type CreateIssueInput {
  CreateIssueInput(
    name: String,
    description: option.Option(String),
    directory_id: String,
  )
}

pub fn from_dynamic(
  json: Dynamic,
) -> Result(CreateIssueInput, dynamic.DecodeErrors) {
  json
  |> dynamic.decode3(
    CreateIssueInput,
    dynamic.field("name", dynamic.string),
    dynamic.field("description", dynamic.optional(dynamic.string)),
    dynamic.field("directory_id", dynamic.string),
  )
}

pub fn to_json(input: CreateIssueInput) -> Json {
  json.object([
    #("name", json.string(input.name)),
    #("description", json.nullable(input.description, json.string)),
    #("directory_id", json.string(input.directory_id)),
  ])
}
