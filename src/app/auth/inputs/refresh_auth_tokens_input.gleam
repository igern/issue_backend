import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}

pub type RefreshAuthTokensInput {
  RefreshAuthTokensInput(refresh_token: String)
}

pub fn from_dynamic(
  json: Dynamic,
) -> Result(RefreshAuthTokensInput, dynamic.DecodeErrors) {
  json
  |> dynamic.decode1(
    RefreshAuthTokensInput,
    dynamic.field("refresh_token", dynamic.string),
  )
}

pub fn to_json(input: RefreshAuthTokensInput) -> Json {
  json.object([#("refresh_token", json.string(input.refresh_token))])
}
