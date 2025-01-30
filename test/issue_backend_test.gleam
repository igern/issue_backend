import app/router
import gleam/json
import gleeunit
import utils
import wisp
import wisp/testing

pub fn main() {
  gleeunit.main()
}

pub fn version_test() {
  use t <- utils.with_context
  let response = router.handle_request(testing.get("/api", []), t.context)

  response
  |> utils.equal(
    json.to_string_tree(json.object([#("version", json.string("1.0.0"))]))
    |> wisp.json_response(200),
  )
}

pub fn not_found_test() {
  use t <- utils.with_context
  let response = router.handle_request(testing.get("/invalid", []), t.context)

  response
  |> utils.equal(
    json.to_string_tree(
      json.object([
        #("code", json.int(404)),
        #("message", json.string("not found")),
      ]),
    )
    |> wisp.json_response(404),
  )
}
