import app/directory/inputs/create_directory_input
import app/directory/inputs/update_directory_input
import app/directory/outputs/directory
import app/router
import gleam/http
import gleam/json
import gleeunit/should
import utils
import wisp/testing

pub fn create_directory_test() {
  use t <- utils.with_context

  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)

  use t, input <- utils.next_create_directory_input(t)
  let json = create_directory_input.to_json(input)
  let response =
    router.handle_request(
      testing.post_json(
        "/api/directories",
        [utils.bearer_header(authorized_profile.auth_tokens.access_token)],
        json,
      ),
      t.context,
    )

  response.status |> should.equal(201)
  let assert Ok(data) =
    json.decode(testing.string_body(response), directory.decoder())

  data
  |> should.equal(directory.Directory(data.id, input.name, data.created_at))
}

pub fn create_directory_missing_authorization_header_test() {
  utils.missing_authorization_header_tester(http.Post, "/api/directories")
}

pub fn create_directory_invalid_bearer_format_test() {
  utils.invalid_bearer_format_tester(http.Post, "/api/directories")
}

pub fn create_directory_invalid_jwt_test() {
  utils.invalid_jwt_tester(http.Post, "/api/directories")
}

pub fn create_directory_profile_required_test() {
  utils.profile_required_tester(http.Post, "/api/directories")
}

pub fn update_directory_test() {
  use t <- utils.with_context

  use t, profile <- utils.next_create_user_and_profile_and_login(t)
  use t, directory <- utils.next_create_directory(
    t,
    profile.auth_tokens.access_token,
  )

  use t, input <- utils.next_update_directory_input(t)
  let json = update_directory_input.to_json(input)

  let response =
    router.handle_request(
      testing.patch_json(
        "/api/directories/" <> directory.id,
        [utils.bearer_header(profile.auth_tokens.access_token)],
        json,
      ),
      t.context,
    )

  response.status |> should.equal(200)

  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), directory.decoder())
  data |> should.equal(directory.Directory(..directory, name: input.name))
}

pub fn update_directory_missing_authorization_header_test() {
  utils.missing_authorization_header_tester(http.Patch, "/api/directories/1")
}

pub fn update_directory_invalid_bearer_format_test() {
  utils.invalid_bearer_format_tester(http.Patch, "/api/directories/1")
}

pub fn update_directory_invalid_jwt_test() {
  utils.invalid_jwt_tester(http.Patch, "/api/directories/1")
}

pub fn update_directory_profile_required_test() {
  utils.profile_required_tester(http.Patch, "/api/directories/1")
}

pub fn delete_directory_test() {
  use t <- utils.with_context

  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)
  use t, directory <- utils.next_create_directory(
    t,
    authorized_profile.auth_tokens.access_token,
  )

  let response =
    router.handle_request(
      testing.delete_json(
        "/api/directories/" <> directory.id,
        [utils.bearer_header(authorized_profile.auth_tokens.access_token)],
        json.object([]),
      ),
      t.context,
    )

  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), directory.decoder())

  data
  |> should.equal(directory)
}

pub fn delete_directory_cascade_issues_test() {
  use t <- utils.with_context

  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)
  use t, directory <- utils.next_create_directory(
    t,
    authorized_profile.auth_tokens.access_token,
  )
  use t, _ <- utils.next_create_issue(
    t,
    authorized_profile.auth_tokens.access_token,
    directory.id,
  )

  utils.delete_directory(
    t,
    authorized_profile.auth_tokens.access_token,
    directory.id,
  )
  let issues = utils.find_issues(t, authorized_profile.auth_tokens.access_token)
  issues.total |> should.equal(0)
}

pub fn delete_directory_missing_authorization_header_test() {
  utils.missing_authorization_header_tester(http.Delete, "/api/directories/id")
}

pub fn delete_directory_invalid_bearer_format_test() {
  utils.invalid_bearer_format_tester(http.Delete, "/api/directories/id")
}

pub fn delete_directory_invalid_jwt_test() {
  utils.invalid_jwt_tester(http.Delete, "/api/directories/id")
}

pub fn delete_directory_profile_required_test() {
  utils.profile_required_tester(http.Delete, "/api/directories/id")
}
