import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json.{type Json}

pub type PaginationInput {
  PaginationInput(skip: Int, take: Int)
}

fn pagination_input_decoder() -> decode.Decoder(PaginationInput) {
  use skip <- decode.field("skip", decode.int)
  use take <- decode.field("take", decode.int)
  decode.success(PaginationInput(skip:, take:))
}

pub fn from_dynamic(json: Dynamic) {
  decode.run(json, pagination_input_decoder())
}

pub fn to_json(input: PaginationInput) -> Json {
  json.object([#("skip", json.int(input.skip)), #("take", json.int(input.take))])
}
