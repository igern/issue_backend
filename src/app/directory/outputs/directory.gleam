import gleam/dynamic.{type Dynamic}
import gleam/json

pub type Directory {
  Directory(id: String, name: String, created_at: String)
}

pub fn decoder() {
  dynamic.decode3(
    Directory,
    dynamic.field("id", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("created_at", dynamic.string),
  )
}

pub fn from_dynamic(json: Dynamic) -> Result(Directory, dynamic.DecodeErrors) {
  json |> decoder()
}

pub fn to_json(directory: Directory) {
  json.object([
    #("id", json.string(directory.id)),
    #("name", json.string(directory.name)),
    #("created_at", json.string(directory.created_at)),
  ])
}
