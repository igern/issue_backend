import app/auth/inputs/login_input.{type LoginInput, LoginInput}
import app/auth/outputs/auth_tokens.{type AuthTokens}
import app/common/response_utils
import app/database
import app/directory/inputs/create_directory_input.{
  type CreateDirectoryInput, CreateDirectoryInput,
}
import app/directory/inputs/update_directory_input.{
  type UpdateDirectoryInput, UpdateDirectoryInput,
}
import app/directory/outputs/directory.{type Directory}
import app/issue/inputs/create_issue_input.{
  type CreateIssueInput, CreateIssueInput,
}
import app/issue/outputs/issue.{type Issue}
import app/issue/outputs/paginated_issues
import app/profile/inputs/create_profile_input.{
  type CreateProfileInput, CreateProfileInput,
}
import app/profile/outputs/profile.{type Profile}
import app/router
import app/types.{type Context, Context}
import app/user/inputs/create_user_input.{type CreateUserInput, CreateUserInput}
import app/user/outputs/user.{type User}
import bucket
import dot_env
import dot_env/env
import gleam/bit_array
import gleam/http
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option
import gleam/string
import gleeunit/should
import simplifile
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
  wisp.Text(json.to_string_tree(json))
}

pub fn with_context(test_case: fn(TestContext) -> Nil) -> Nil {
  dot_env.load_default()
  let assert Ok(storage) = env.get_string("STORAGE_BUCKET")
  let assert Ok(host) = env.get_string("STORAGE_HOST")
  let assert Ok(access) = env.get_string("STORAGE_ACCESS")
  let assert Ok(secret) = env.get_string("STORAGE_SECRET")
  let assert Ok(region) = env.get_string("STORAGE_SECRET")
  let assert Ok(port) = env.get_int("STORAGE_PORT")
  let creds =
    bucket.Credentials(
      host:,
      port: option.Some(port),
      scheme: http.Http,
      region:,
      access_key_id: access,
      secret_access_key: secret,
    )

  use connection <- sqlight.with_connection(":memory:")
  let assert Ok(Nil) = database.init_schemas(connection)

  let context =
    Context(
      connection: connection,
      storage_credentials: creds,
      storage_bucket: storage,
    )
  let test_context = TestContext(context: context, next: 1)

  test_case(test_context)
}

pub fn next_create_issue_input(
  t: TestContext,
  directory_id: String,
  handler: fn(TestContext, CreateIssueInput) -> Nil,
) {
  handler(
    TestContext(..t, next: t.next + 1),
    CreateIssueInput(
      name: "name" <> int.to_string(t.next),
      directory_id: directory_id,
    ),
  )
}

pub fn next_create_issue(
  t: TestContext,
  access_token: String,
  directory_id: String,
  handler: fn(TestContext, Issue) -> Nil,
) {
  use t, input <- next_create_issue_input(t, directory_id)
  let json = create_issue_input.to_json(input)

  let response =
    router.handle_request(
      testing.post_json("/api/issues", [bearer_header(access_token)], json),
      t.context,
    )
  response.status |> should.equal(201)

  let assert Ok(issue) =
    json.decode(testing.string_body(response), issue.decoder())
  handler(t, issue)
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

pub fn next_create_user(
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

pub fn next_create_user_and_login(
  t: TestContext,
  handler: fn(TestContext, AuthorizedUser) -> Nil,
) {
  use t, user <- next_create_user(t)
  let auth_tokens =
    login(t, LoginInput(email: user.email, password: "secret1234"))
  handler(t, AuthorizedUser(user:, auth_tokens:))
}

pub fn next_create_user_and_profile_and_login(
  t: TestContext,
  handler: fn(TestContext, AuthorizedProfile) -> Nil,
) {
  use t, authorized_user <- next_create_user_and_login(t)
  use t, profile <- next_create_profile(t, authorized_user)
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
    CreateProfileInput(name: "name" <> int.to_string(t.next)),
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

pub fn next_create_profile(
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
  response1.status |> should.equal(response2.status)
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

  use t, authorized_user <- next_create_user_and_login(t)

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

fn append_line(bit_array: BitArray, line: String) {
  bit_array
  |> bit_array.append(line |> bit_array.from_string)
  |> bit_array.append("\r\n" |> bit_array.from_string)
}

fn append_bytes(bit_array: BitArray, bytes: BitArray) {
  bit_array
  |> bit_array.append(bytes)
  |> bit_array.append("\r\n" |> bit_array.from_string)
}

pub fn post_file(path: String, headers: List(http.Header), file_path: String) {
  let boundary = "abcde12345"
  let assert Ok(file_name) = string.split(file_path, "/") |> list.last
  let assert Ok(result) = simplifile.read_bits(file_path)
  let body =
    <<>>
    |> append_line("--" <> boundary)
    |> append_line(
      "Content-Disposition: form-data; name=\"file\"; filename=\""
      <> file_name
      <> "\"",
    )
    |> append_line("")
    |> append_bytes(result)
    |> append_line("--" <> boundary <> "--")
  testing.request(
    http.Post,
    path,
    headers
      |> list.append([
        #("content-type", "multipart/form-data; boundary=" <> boundary),
      ]),
    body,
  )
}

pub const jpg = "test/files/jpg.jpg"

pub const png = "test/files/png.png"

pub const mock_uuidv4 = "C1136D3F-E398-4496-A777-2DBFC882C70A"

pub fn next_create_directory_input(
  t: TestContext,
  handler: fn(TestContext, CreateDirectoryInput) -> Nil,
) {
  handler(
    TestContext(..t, next: t.next + 1),
    CreateDirectoryInput("name_" <> int.to_string(t.next)),
  )
}

pub fn next_update_directory_input(
  t: TestContext,
  handler: fn(TestContext, UpdateDirectoryInput) -> Nil,
) {
  handler(
    TestContext(..t, next: t.next + 1),
    UpdateDirectoryInput("name_" <> int.to_string(t.next)),
  )
}

pub fn create_directory(
  t: TestContext,
  input: CreateDirectoryInput,
  access_token: String,
  handle: fn(Directory) -> Nil,
) -> Nil {
  let json = create_directory_input.to_json(input)

  let response =
    router.handle_request(
      testing.post_json("/api/directories", [bearer_header(access_token)], json),
      t.context,
    )

  response.status |> should.equal(201)

  let assert Ok(directory) =
    json.decode(testing.string_body(response), directory.decoder())
  handle(directory)
}

pub fn next_create_directory(
  t: TestContext,
  access_token: String,
  handle: fn(TestContext, Directory) -> Nil,
) {
  use t, input <- next_create_directory_input(t)
  use directory <- create_directory(t, input, access_token)
  handle(t, directory)
}

pub fn delete_directory(t: TestContext, access_token: String, id: String) {
  let response =
    router.handle_request(
      testing.delete_json(
        "/api/directories/" <> id,
        [bearer_header(access_token)],
        json.object([]),
      ),
      t.context,
    )
  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), directory.decoder())

  data
}

pub fn find_issues(t: TestContext, access_token: String) {
  let response =
    router.handle_request(
      testing.get("/api/issues?skip=0&take=10", [bearer_header(access_token)]),
      t.context,
    )

  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), paginated_issues.decoder())
  data
}
