import app/database
import app/issue/inputs/create_issue_input.{CreateIssueInput}
import app/issue/outputs/issue
import app/router
import app/types.{type Context, Context}
import app/user/inputs/create_user_input.{CreateUserInput}
import app/user/outputs/user
import gleam/json.{type Json}
import gleeunit/should
import sqlight
import wisp
import wisp/testing

pub fn to_body(json: Json) {
  wisp.Text(json.to_string_builder(json))
}

pub fn with_context(test_case: fn(Context) -> Nil) -> Nil {
  use connection <- sqlight.with_connection(":memory:")

  let assert Ok(Nil) = database.init_schemas(connection)
  let context = Context(connection: connection)

  test_case(context)
}

pub fn create_issue(ctx: Context) {
  let input = create_issue_input.to_json(CreateIssueInput(name: "Jonas"))

  let response =
    router.handle_request(testing.post_json("/issues", [], input), ctx)
  response.status |> should.equal(201)

  let assert Ok(issue) =
    json.decode(testing.string_body(response), issue.decoder())
  issue
}

pub fn create_user(ctx: Context) {
  let input =
    create_user_input.to_json(CreateUserInput(
      email: "jonas@hotmail.dk",
      password: "secret1234",
    ))

  let response =
    router.handle_request(testing.post_json("/user", [], input), ctx)
  response.status |> should.equal(201)

  let assert Ok(issue) =
    json.decode(testing.string_body(response), user.decoder())
  issue
}
