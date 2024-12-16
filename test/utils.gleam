import app/auth/inputs/login_input.{type LoginInput, LoginInput}
import app/auth/outputs/auth_tokens.{type AuthTokens}
import app/common/response_utils
import app/database
import app/issue/inputs/create_issue_input.{
  type CreateIssueInput, CreateIssueInput,
}
import app/issue/outputs/issue.{type Issue}
import app/profile/inputs/create_profile_input.{
  type CreateProfileInput, CreateProfileInput,
}
import app/profile/outputs/profile.{type Profile}
import app/router
import app/types.{type Context, Context}
import app/user/inputs/create_user_input.{type CreateUserInput, CreateUserInput}
import app/user/outputs/user.{type User}
import gleam/http
import gleam/int
import gleam/json.{type Json}
import gleeunit/should
import sqlight
import wisp.{type Response}
import wisp/testing

pub type TestContext {
  TestContext(context: Context, next: Int)
}

pub type AuthorizedUser {
  AuthorizedUser(user: User, auth_tokens: AuthTokens)
}

pub type AuthorizedProfile {
  AuthorizedProfile(profile: Profile, user: User, auth_tokens: AuthTokens)
}

pub fn to_body(json: Json) {
  wisp.Text(json.to_string_builder(json))
}

pub fn with_context(test_case: fn(TestContext) -> Nil) -> Nil {
  use connection <- sqlight.with_connection(":memory:")

  let assert Ok(Nil) = database.init_schemas(connection)
  let context = Context(connection: connection)
  let test_context = TestContext(context: context, next: 1)

  test_case(test_context)
}

pub fn next_create_issue_input(
  t: TestContext,
  handler: fn(TestContext, CreateIssueInput) -> Nil,
) {
  handler(
    TestContext(..t, next: t.next + 1),
    CreateIssueInput(name: int.to_string(t.next)),
  )
}

pub fn create_issue(
  t: TestContext,
  access_token: String,
  handler: fn(Issue) -> Nil,
) {
  use t, input <- next_create_issue_input(t)
  let json = create_issue_input.to_json(input)

  let response =
    router.handle_request(
      testing.post_json("/api/issues", [bearer_header(access_token)], json),
      t.context,
    )
  response.status |> should.equal(201)

  let assert Ok(issue) =
    json.decode(testing.string_body(response), issue.decoder())
  handler(issue)
}

pub fn next_create_user_input(
  t: TestContext,
  handler: fn(TestContext, CreateUserInput) -> Nil,
) {
  handler(
    TestContext(..t, next: t.next + 1),
    CreateUserInput(
      email: "jonas" <> int.to_string(t.next) <> "@hotmail.dk",
      password: "secret1234",
    ),
  )
}

pub fn create_user(
  t: TestContext,
  input: CreateUserInput,
  handler: fn(User) -> Nil,
) -> Nil {
  let json = create_user_input.to_json(input)

  let response =
    router.handle_request(testing.post_json("/api/users", [], json), t.context)
  response.status |> should.equal(201)

  let assert Ok(user) =
    json.decode(testing.string_body(response), user.decoder())
  handler(user)
}

pub fn create_next_user(
  t: TestContext,
  handler: fn(TestContext, User) -> Nil,
) -> Nil {
  use t, input <- next_create_user_input(t)
  use user <- create_user(t, input)
  handler(t, user)
}

pub fn login(t: TestContext, input: LoginInput) {
  let response =
    router.handle_request(
      testing.post_json("/api/auth/login", [], login_input.to_json(input)),
      t.context,
    )

  response.status |> should.equal(201)
  let assert Ok(auth_tokens) =
    json.decode(testing.string_body(response), auth_tokens.decoder())
  auth_tokens
}

pub fn create_next_user_and_login(
  t: TestContext,
  handler: fn(TestContext, AuthorizedUser) -> Nil,
) {
  use t, user <- create_next_user(t)
  let auth_tokens =
    login(t, LoginInput(email: user.email, password: "secret1234"))
  handler(t, AuthorizedUser(user:, auth_tokens:))
}

pub fn create_next_user_and_profile_and_login(
  t: TestContext,
  handler: fn(TestContext, AuthorizedProfile) -> Nil,
) {
  use t, authorized_user <- create_next_user_and_login(t)
  use t, profile <- create_next_profile(t, authorized_user)
  handler(
    t,
    AuthorizedProfile(
      profile,
      authorized_user.user,
      authorized_user.auth_tokens,
    ),
  )
}

pub fn next_create_profile_input(
  t: TestContext,
  handler: fn(TestContext, CreateProfileInput) -> Nil,
) {
  handler(
    TestContext(..t, next: t.next + 1),
    CreateProfileInput(name: int.to_string(t.next)),
  )
}

pub fn create_profile(
  t: TestContext,
  authorized_user: AuthorizedUser,
  input: CreateProfileInput,
  handler: fn(Profile) -> Nil,
) {
  let json = create_profile_input.to_json(input)
  let response =
    router.handle_request(
      testing.post_json(
        "/api/profiles",
        [bearer_header(authorized_user.auth_tokens.access_token)],
        json,
      ),
      t.context,
    )

  let assert Ok(profile) =
    json.decode(testing.string_body(response), profile.decoder())
  handler(profile)
}

pub fn create_next_profile(
  t: TestContext,
  authorized_user: AuthorizedUser,
  handler: fn(TestContext, Profile) -> Nil,
) {
  use t, input <- next_create_profile_input(t)
  use profile <- create_profile(t, authorized_user, input)
  handler(t, profile)
}

pub fn bearer_header(access_token: String) {
  #("authorization", "Bearer " <> access_token)
}

pub fn response_equal(response1: Response, response2: Response) {
  testing.string_body(response1)
  |> should.equal(
    response2
    |> testing.string_body,
  )
}

pub fn missing_authorization_header_tester(method: http.Method, path: String) {
  use t <- with_context
  let response =
    router.handle_request(testing.request(method, path, [], <<>>), t.context)

  response
  |> response_equal(response_utils.missing_authorization_header_response())
}

pub fn invalid_bearer_format_tester(method: http.Method, path: String) {
  use t <- with_context
  let response =
    router.handle_request(
      testing.request(method, path, [#("authorization", "token")], <<>>),
      t.context,
    )
  response
  |> response_equal(response_utils.invalid_bearer_format_response())
}

pub fn invalid_jwt_tester(method: http.Method, path: String) {
  use t <- with_context
  let response =
    router.handle_request(
      testing.request(method, path, [#("authorization", "bearer token")], <<>>),
      t.context,
    )

  response |> response_equal(response_utils.invalid_jwt_response())
}

pub fn profile_required_tester(method: http.Method, path: String) {
  use t <- with_context

  use t, authorized_user <- create_next_user_and_login(t)

  let response =
    router.handle_request(
      testing.request(
        method,
        path,
        [bearer_header(authorized_user.auth_tokens.access_token)],
        <<>>,
      ),
      t.context,
    )

  response |> response_equal(response_utils.profile_required_response())
}
