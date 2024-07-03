import app/database
import app/issue/inputs/create_issue_input.{CreateIssueInput}
import app/issue/outputs/issue
import app/router
import app/types.{type Context, Context}
import app/user/inputs/create_user_input.{CreateUserInput}
import app/user/inputs/login_input.{type LoginInput, LoginInput}
import app/user/outputs/auth_tokens.{type AuthTokens}
import app/user/outputs/user.{type User}
import gleam/json.{type Json}
import gleeunit/should
import sqlight
import wisp
import wisp/testing

pub type AuthorizedUser {
  AuthorizedUser(user: User, auth_tokens: AuthTokens)
}

pub fn to_body(json: Json) {
  wisp.Text(json.to_string_builder(json))
}

pub fn with_context(test_case: fn(Context) -> Nil) -> Nil {
  use connection <- sqlight.with_connection(":memory:")

  let assert Ok(Nil) = database.init_schemas(connection)
  let context = Context(connection: connection)

  test_case(context)
}

pub fn create_issue(ctx: Context, access_token: String) {
  let input = create_issue_input.to_json(CreateIssueInput(name: "Jonas"))

  let response =
    router.handle_request(
      testing.post_json("/issues", [bearer_header(access_token)], input),
      ctx,
    )
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
    router.handle_request(testing.post_json("/users", [], input), ctx)
  response.status |> should.equal(201)

  let assert Ok(issue) =
    json.decode(testing.string_body(response), user.decoder())
  issue
}

pub fn login(ctx: Context, input: LoginInput) {
  let response =
    router.handle_request(
      testing.post_json("/auth/login", [], login_input.to_json(input)),
      ctx,
    )

  response.status |> should.equal(201)
  let assert Ok(auth_tokens) =
    json.decode(testing.string_body(response), auth_tokens.decoder())
  auth_tokens
}

pub fn create_user_and_login(ctx: Context) {
  let user = create_user(ctx)
  let auth_tokens =
    login(ctx, LoginInput(email: "jonas@hotmail.dk", password: "secret1234"))
  AuthorizedUser(user: user, auth_tokens: auth_tokens)
}

pub fn bearer_header(access_token: String) {
  #("authorization", "Bearer " <> access_token)
}
