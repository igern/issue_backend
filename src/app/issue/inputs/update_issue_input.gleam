import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}

pub type UpdateIssueInput {
  UpdateIssueInput(name: String)
}

pub fn from_dynamic(
  json: Dynamic,
) -> Result(UpdateIssueInput, dynamic.DecodeErrors) {
  json
  |> dynamic.decode1(UpdateIssueInput, dynamic.field("name", dynamic.string))
}

pub fn to_json(input: UpdateIssueInput) -> Json {
  json.object([#("name", json.string(input.name))])
}
