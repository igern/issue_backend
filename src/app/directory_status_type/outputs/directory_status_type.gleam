import gleam/dynamic
import gleam/dynamic/decode
import gleam/json

pub type DirectoryStatusType {
  DirectoryStatusType(name: String)
}

pub fn directory_status_type_decoder() -> decode.Decoder(DirectoryStatusType) {
  use name <- decode.field("name", decode.string)
  decode.success(DirectoryStatusType(name:))
}

pub fn from_dynamic(
  json: dynamic.Dynamic,
) -> Result(DirectoryStatusType, List(decode.DecodeError)) {
  json |> decode.run(directory_status_type_decoder())
}

pub fn to_json(directory_status_type: DirectoryStatusType) -> json.Json {
  json.object([#("name", json.string(directory_status_type.name))])
}
