import gleam/dynamic
import gleam/dynamic/decode
import gleam/json

pub type TeamProfile {
  TeamProfile(team_id: String, profile_id: String)
}

fn team_profile_decoder() -> decode.Decoder(TeamProfile) {
  use team_id <- decode.field("team_id", decode.string)
  use profile_id <- decode.field("profile_id", decode.string)
  decode.success(TeamProfile(team_id:, profile_id:))
}

pub fn from_dynamic(
  json: dynamic.Dynamic,
) -> Result(TeamProfile, List(decode.DecodeError)) {
  decode.run(json, team_profile_decoder())
}

pub fn to_json(team_profile: TeamProfile) {
  json.object([
    #("team_id", json.string(team_profile.team_id)),
    #("profile_id", json.string(team_profile.profile_id)),
  ])
}
