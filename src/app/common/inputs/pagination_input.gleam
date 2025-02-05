import app/common/valid
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

pub fn validate(input: PaginationInput) {
  let skip_check = valid.validate_min(input.skip, 0)
  let take_check = valid.validate_min(input.take, 0)

  valid.checks_to_validated(input, [
    #("skip", skip_check),
    #("take", take_check),
  ])
}
