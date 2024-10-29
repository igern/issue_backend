import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}

pub type LoginInput {
  LoginInput(email: String, password: String)
}

pub fn from_dynamic(json: Dynamic) -> Result(LoginInput, dynamic.DecodeErrors) {
  json
  |> dynamic.decode2(
    LoginInput,
    dynamic.field("email", dynamic.string),
    dynamic.field("password", dynamic.string),
  )
}

pub fn to_json(input: LoginInput) -> Json {
  json.object([
    #("email", json.string(input.email)),
    #("password", json.string(input.password)),
  ])
}
