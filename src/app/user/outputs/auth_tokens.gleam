import gleam/dynamic
import gleam/json

pub type AuthTokens {
  AuthTokens(refresh_token: String, access_token: String)
}

pub fn decoder() {
  dynamic.decode2(
    AuthTokens,
    dynamic.field("refresh_token", dynamic.string),
    dynamic.field("access_token", dynamic.string),
  )
}

pub fn to_json(auth_tokens: AuthTokens) {
  json.object([
    #("refresh_token", json.string(auth_tokens.refresh_token)),
    #("access_token", json.string(auth_tokens.access_token)),
  ])
}
