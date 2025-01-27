import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{None, Some}

pub type UpdateIssueInput {
  UpdateIssueInput(
    name: option.Option(String),
    description: option.Option(option.Option(String)),
  )
}

fn update_issue_input_decoder() -> decode.Decoder(UpdateIssueInput) {
  use name <- decode.optional_field(
    "name",
    option.None,
    decode.optional(decode.string),
  )
  use description <- decode.optional_field(
    "description",
    option.None,
    decode.optional(decode.string) |> decode.map(option.Some),
  )
  decode.success(UpdateIssueInput(name:, description:))
}

pub fn from_dynamic(
  json: Dynamic,
) -> Result(UpdateIssueInput, List(decode.DecodeError)) {
  decode.run(json, update_issue_input_decoder())
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
