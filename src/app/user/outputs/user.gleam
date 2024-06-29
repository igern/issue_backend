import gleam/dynamic
import gleam/json

pub type User {
  User(id: Int, email: String)
}

pub fn decoder() {
  dynamic.decode2(
    User,
    dynamic.field("id", dynamic.int),
    dynamic.field("email", dynamic.string),
  )
}

pub fn to_json(user: User) {
  json.object([#("id", json.int(user.id)), #("email", json.string(user.email))])
}
