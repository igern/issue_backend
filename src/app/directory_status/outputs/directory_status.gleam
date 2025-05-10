import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json

pub type DirectoryStatus {
  DirectoryStatus(
    id: String,
    name: String,
    directory_id: String,
    directory_status_type_name: String,
  )
}

pub fn directory_status_decoder() -> decode.Decoder(DirectoryStatus) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use directory_id <- decode.field("directory_id", decode.string)
  use directory_status_type_name <- decode.field(
    "directory_status_type_name",
    decode.string,
  )
  decode.success(DirectoryStatus(
    id:,
    name:,
    directory_id:,
    directory_status_type_name:,
  ))
}

pub fn from_dynamic(
  json: Dynamic,
) -> Result(DirectoryStatus, List(decode.DecodeError)) {
  json |> decode.run(directory_status_decoder())
}

pub fn to_json(directory_status: DirectoryStatus) -> json.Json {
  json.object([
    #("id", json.string(directory_status.id)),
    #("name", json.string(directory_status.name)),
    #("directory_id", json.string(directory_status.directory_id)),
    #(
      "directory_status_type_name",
      json.string(directory_status.directory_status_type_name),
    ),
  ])
}
