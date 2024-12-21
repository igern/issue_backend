import gleam/dynamic.{type Dynamic}
import gleam/json
import gleam/option.{type Option}

pub type Profile {
  Profile(id: Int, user_id: Int, name: String, profile_picture: Option(String))
}

pub fn decoder() {
  dynamic.decode4(
    Profile,
    dynamic.field("id", dynamic.int),
    dynamic.field("user_id", dynamic.int),
    dynamic.field("name", dynamic.string),
    dynamic.field("profile_picture", dynamic.optional(dynamic.string)),
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
    #("profile_picture", json.nullable(profile.profile_picture, json.string)),
  ])
}
