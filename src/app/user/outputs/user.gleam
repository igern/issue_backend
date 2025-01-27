import gleam/dynamic/decode
import gleam/json

pub type User {
  User(id: String, email: String)
}

pub fn decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", decode.string)
  use email <- decode.field("email", decode.string)
  decode.success(User(id:, email:))
}

pub fn to_json(user: User) {
  json.object([
    #("id", json.string(user.id)),
    #("email", json.string(user.email)),
  ])
}
