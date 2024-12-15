import gleam/dynamic.{type Dynamic}
import gleam/json

pub type Profile {
  Profile(id: Int, user_id: Int, name: String)
}

pub fn decoder() {
  dynamic.decode3(
    Profile,
    dynamic.field("id", dynamic.int),
    dynamic.field("user_id", dynamic.int),
    dynamic.field("name", dynamic.string),
  )
}

pub fn from_dynamic(json: Dynamic) -> Result(Profile, dynamic.DecodeErrors) {
  json |> decoder()
}

pub fn to_json(profile: Profile) {
  json.object([
    #("id", json.int(profile.id)),
    #("user_id", json.int(profile.user_id)),
    #("name", json.string(profile.name)),
  ])
}
