import gleam/dynamic/decode
import gleam/json

pub type AuthTokens {
  AuthTokens(refresh_token: String, access_token: String)
}

pub fn decoder() -> decode.Decoder(AuthTokens) {
  use refresh_token <- decode.field("refresh_token", decode.string)
  use access_token <- decode.field("access_token", decode.string)
  decode.success(AuthTokens(refresh_token:, access_token:))
}

pub fn to_json(auth_tokens: AuthTokens) {
  json.object([
    #("refresh_token", json.string(auth_tokens.refresh_token)),
    #("access_token", json.string(auth_tokens.access_token)),
  ])
}
