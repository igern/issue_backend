import app/common/valid
import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import gleam/option

pub type UpdateDirectoryStatusInput {
  UpdateDirectoryStatusInput(
    name: option.Option(String),
    directory_status_type_name: option.Option(String),
  )
}

fn update_directory_status_input_decoder() -> decode.Decoder(
  UpdateDirectoryStatusInput,
) {
  use name <- decode.optional_field(
    "name",
    option.None,
    decode.optional(decode.string),
  )
  use directory_status_type_name <- decode.optional_field(
    "directory_status_type_name",
    option.None,
    decode.optional(decode.string),
  )
  decode.success(UpdateDirectoryStatusInput(
    name: name,
    directory_status_type_name: directory_status_type_name,
  ))
}

pub fn from_dynamic(json: dynamic.Dynamic) {
  decode.run(json, update_directory_status_input_decoder())
}

pub fn to_json(input: UpdateDirectoryStatusInput) -> json.Json {
  json.object(case input.name, input.directory_status_type_name {
    option.Some(name), option.Some(directory_status_type_name) -> [
      #("name", json.string(name)),
      #("directory_status_type_name", json.string(directory_status_type_name)),
    ]
    option.Some(name), option.None -> [#("name", json.string(name))]
    option.None, option.Some(directory_status_type_name) -> [
      #("directory_status_type_name", json.string(directory_status_type_name)),
    ]
    option.None, option.None -> []
  })
}

pub fn validate(input: UpdateDirectoryStatusInput) {
  let valid_name = valid.validate_optional_min_length(input.name, 2)

  valid.checks_to_validated(input, [#("name", valid_name)])
}
