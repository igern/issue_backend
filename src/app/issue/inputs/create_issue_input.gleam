import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/option.{type Option}

pub type CreateIssueInput {
  CreateIssueInput(
    name: String,
    description: Option(String),
    directory_id: String,
  )
}

fn create_issue_input_decoder() -> decode.Decoder(CreateIssueInput) {
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  use directory_id <- decode.field("directory_id", decode.string)
  decode.success(CreateIssueInput(name:, description:, directory_id:))
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
    #("directory_id", json.string(input.directory_id)),
  ])
}
