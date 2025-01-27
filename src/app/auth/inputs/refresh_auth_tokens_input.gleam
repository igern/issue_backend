import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json.{type Json}

pub type RefreshAuthTokensInput {
  RefreshAuthTokensInput(refresh_token: String)
}

fn refresh_auth_tokens_input_decoder() -> decode.Decoder(RefreshAuthTokensInput) {
  use refresh_token <- decode.field("refresh_token", decode.string)
  decode.success(RefreshAuthTokensInput(refresh_token:))
}

pub fn from_dynamic(
  json: Dynamic,
) -> Result(RefreshAuthTokensInput, List(decode.DecodeError)) {
  decode.run(json, refresh_auth_tokens_input_decoder())
}

pub fn to_json(input: RefreshAuthTokensInput) -> Json {
  json.object([#("refresh_token", json.string(input.refresh_token))])
}
