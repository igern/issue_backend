import gleam/dynamic.{type Dynamic}
import gleam/json
import gleam/option.{type Option}

pub type Profile {
  Profile(
    id: String,
    user_id: String,
    name: String,
    profile_picture: Option(String),
  )
}

pub fn decoder() {
  dynamic.decode4(
    Profile,
    dynamic.field("id", dynamic.string),
    dynamic.field("user_id", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("profile_picture", dynamic.optional(dynamic.string)),
  )
}

pub fn from_dynamic(json: Dynamic) -> Result(Profile, dynamic.DecodeErrors) {
  json |> decoder()
}

pub fn to_json(profile: Profile) {
  json.object([
    #("id", json.string(profile.id)),
    #("user_id", json.string(profile.user_id)),
    #("name", json.string(profile.name)),
    #("profile_picture", json.nullable(profile.profile_picture, json.string)),
  ])
}
