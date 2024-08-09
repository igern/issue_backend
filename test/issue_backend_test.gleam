import app/router
import gleam/json
import gleeunit
import gleeunit/should
import utils
import wisp
import wisp/testing

pub fn main() {
  gleeunit.main()
}

pub fn version_test() {
  use t <- utils.with_context
  let response = router.handle_request(testing.get("/", []), t.context)

  response.status |> should.equal(200)

  let expected_json = json.object([#("version", json.string("1.0.0"))])

  response.body
  |> should.equal(wisp.Text(json.to_string_builder(expected_json)))
}

pub fn not_found_test() {
  use t <- utils.with_context
  let response = router.handle_request(testing.get("/invalid", []), t.context)

  response.status |> should.equal(404)

  let expected_json =
    json.object([
      #("code", json.int(404)),
      #("message", json.string("not found")),
    ])
  response.body
  |> should.equal(wisp.Text(json.to_string_builder(expected_json)))
}
