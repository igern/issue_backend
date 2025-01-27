import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json

pub type Directory {
  Directory(id: String, name: String, created_at: String)
}

pub fn decoder() -> decode.Decoder(Directory) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use created_at <- decode.field("created_at", decode.string)
  decode.success(Directory(id:, name:, created_at:))
}

pub fn from_dynamic(
  json: Dynamic,
) -> Result(Directory, List(decode.DecodeError)) {
  json |> decode.run(decoder())
}

pub fn to_json(directory: Directory) {
  json.object([
    #("id", json.string(directory.id)),
    #("name", json.string(directory.name)),
    #("created_at", json.string(directory.created_at)),
  ])
}
