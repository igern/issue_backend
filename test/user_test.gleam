import app/router
import app/user/inputs/create_user_input
import app/user/inputs/login_input.{LoginInput}
import app/user/outputs/user.{User}
import gleam/json
import gleeunit/should
import utils
import wisp/testing

pub fn create_user_test() {
  use t <- utils.with_context

  use t, input <- utils.next_create_user_input(t)
  let json = create_user_input.to_json(input)

  let response =
    router.handle_request(testing.post_json("/users", [], json), t.context)

  response.status |> should.equal(201)

  let assert Ok(data) =
    json.decode(testing.string_body(response), user.decoder())
  data |> should.equal(User(id: 1, email: input.email))
}

pub fn user_login_test() {
  use t <- utils.with_context

  use t, user <- utils.create_next_user(t)
  let input =
    login_input.to_json(LoginInput(email: user.email, password: "secret1234"))

  let response =
    router.handle_request(
      testing.post_json("/auth/login", [], input),
      t.context,
    )

  response.status |> should.equal(201)
}
