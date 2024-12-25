import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}
import gleam/list
import gleam/option

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
    dynamic.field("name", dynamic.optional(dynamic.string)),
    dynamic.optional_field("description", dynamic.optional(dynamic.string)),
  )
}

pub fn to_json(input: UpdateIssueInput) -> Json {
  let stuff = [#("name", json.nullable(input.name, json.string))]
  case input.description {
    option.Some(description) -> {
      json.object(
        list.flatten([
          [#("description", json.nullable(description, json.string))],
          stuff,
        ]),
      )
    }
    _ -> json.object(stuff)
  }
  json.object([#("name", json.nullable(input.name, json.string))])
}
