import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}

pub type PaginationInput {
  PaginationInput(skip: Int, take: Int)
}

pub fn from_dynamic(json: Dynamic) {
  json
  |> dynamic.decode2(
    PaginationInput,
    dynamic.field("skip", dynamic.int),
    dynamic.field("take", dynamic.int),
  )
}

pub fn to_json(input: PaginationInput) -> Json {
  json.object([#("skip", json.int(input.skip)), #("take", json.int(input.take))])
}
