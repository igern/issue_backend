import app/router
import app/user/inputs/create_user_input.{CreateUserInput}
import app/user/outputs/user.{User}
import gleam/json
import gleeunit/should
import utils
import wisp/testing

pub fn create_user_test() {
  use ctx <- utils.with_context

  let input =
    create_user_input.to_json(CreateUserInput(
      email: "jonas@hotmail.dk",
      password: "secret1234",
    ))

  let response =
    router.handle_request(testing.post_json("/users", [], input), ctx)

  response.status |> should.equal(201)

  let assert Ok(data) =
    json.decode(testing.string_body(response), user.decoder())
  data |> should.equal(User(id: 1, email: "jonas@hotmail.dk"))
}
