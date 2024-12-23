import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}

pub type CreateIssueInput {
  CreateIssueInput(name: String, directory_id: String)
}

pub fn from_dynamic(
  json: Dynamic,
) -> Result(CreateIssueInput, dynamic.DecodeErrors) {
  json
  |> dynamic.decode2(
    CreateIssueInput,
    dynamic.field("name", dynamic.string),
    dynamic.field("directory_id", dynamic.string),
  )
}

pub fn to_json(input: CreateIssueInput) -> Json {
  json.object([
    #("name", json.string(input.name)),
    #("directory_id", json.string(input.directory_id)),
  ])
}
