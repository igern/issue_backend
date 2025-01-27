import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
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

pub fn decoder() -> decode.Decoder(Profile) {
  use id <- decode.field("id", decode.string)
  use user_id <- decode.field("user_id", decode.string)
  use name <- decode.field("name", decode.string)
  use profile_picture <- decode.field(
    "profile_picture",
    decode.optional(decode.string),
  )
  decode.success(Profile(id:, user_id:, name:, profile_picture:))
}

pub fn from_dynamic(json: Dynamic) {
  decode.run(json, decoder())
}

pub fn to_json(profile: Profile) {
  json.object([
    #("id", json.string(profile.id)),
    #("user_id", json.string(profile.user_id)),
    #("name", json.string(profile.name)),
    #("profile_picture", json.nullable(profile.profile_picture, json.string)),
  ])
}
