import app/common/valid
import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import gleam/option

pub type UpdateDirectoryStatusInput {
  UpdateDirectoryStatusInput(name: option.Option(String))
}

fn update_directory_status_input_decoder() -> decode.Decoder(
  UpdateDirectoryStatusInput,
) {
  use name <- decode.optional_field(
    "name",
    option.None,
    decode.optional(decode.string),
  )
  decode.success(UpdateDirectoryStatusInput(name:))
}

pub fn from_dynamic(json: dynamic.Dynamic) {
  decode.run(json, update_directory_status_input_decoder())
}

pub fn to_json(input: UpdateDirectoryStatusInput) -> json.Json {
  json.object(case input.name {
    option.Some(name) -> [#("name", json.string(name))]
    option.None -> []
  })
}

pub fn validate(input: UpdateDirectoryStatusInput) {
  let valid_name = valid.validate_optional_min_length(input.name, 2)

  valid.checks_to_validated(input, [#("name", valid_name)])
}
