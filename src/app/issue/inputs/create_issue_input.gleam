import app/common/valid
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/option.{type Option}

pub type CreateIssueInput {
  CreateIssueInput(name: String, description: Option(String))
}

fn create_issue_input_decoder() -> decode.Decoder(CreateIssueInput) {
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  decode.success(CreateIssueInput(name:, description:))
}

pub fn from_dynamic(
  json: Dynamic,
) -> Result(CreateIssueInput, List(decode.DecodeError)) {
  decode.run(json, create_issue_input_decoder())
}

pub fn to_json(input: CreateIssueInput) -> Json {
  json.object([
    #("name", json.string(input.name)),
    #("description", json.nullable(input.description, json.string)),
  ])
}

pub fn validate(input: CreateIssueInput) {
  let valid_name = valid.validate_min_length(input.name, 2)

  valid.checks_to_validated(input, [#("name", valid_name)])
}
