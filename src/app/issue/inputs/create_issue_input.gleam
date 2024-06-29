import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}

pub type CreateIssueInput {
  CreateIssueInput(name: String)
}

pub fn from_dynamic(
  json: Dynamic,
) -> Result(CreateIssueInput, dynamic.DecodeErrors) {
  json
  |> dynamic.decode1(CreateIssueInput, dynamic.field("name", dynamic.string))
}

pub fn to_json(input: CreateIssueInput) -> Json {
  json.object([#("name", json.string(input.name))])
}
