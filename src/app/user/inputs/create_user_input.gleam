import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}

pub type CreateUserInput {
  CreateUserInput(email: String, password: String)
}

pub fn from_dynamic(
  json: Dynamic,
) -> Result(CreateUserInput, dynamic.DecodeErrors) {
  json
  |> dynamic.decode2(
    CreateUserInput,
    dynamic.field("email", dynamic.string),
    dynamic.field("password", dynamic.string),
  )
}

pub fn to_json(input: CreateUserInput) -> Json {
  json.object([
    #("email", json.string(input.email)),
    #("password", json.string(input.password)),
  ])
}
