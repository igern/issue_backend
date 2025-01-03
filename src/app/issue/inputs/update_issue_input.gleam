import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{None, Some}

pub type UpdateIssueInput {
  UpdateIssueInput(
    name: option.Option(String),
    description: option.Option(option.Option(String)),
  )
}

pub fn from_dynamic(
  json: Dynamic,
) -> Result(UpdateIssueInput, dynamic.DecodeErrors) {
  json
  |> dynamic.decode2(
    UpdateIssueInput,
    dynamic.optional_field("name", dynamic.string),
    dynamic.optional_field("description", dynamic.optional(dynamic.string)),
  )
}

pub fn to_json(input: UpdateIssueInput) -> Json {
  let name = case input.name {
    Some(name) -> [#("name", json.string(name))]
    None -> []
  }
  let description = case input.description {
    Some(Some(description)) -> [#("description", json.string(description))]
    Some(None) -> [#("description", json.null())]
    None -> []
  }

  json.object(list.flatten([name, description]))
}
