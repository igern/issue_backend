import app/common/response_utils
import app/directory_status/outputs/directory_status
import app/router
import gleam/http
import gleam/json
import utils
import wisp
import wisp/testing

pub fn find_all_directory_statuses_test() {
  use t <- utils.with_context

  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)
  use t, team <- utils.next_create_team(
    t,
    authorized_profile.auth_tokens.access_token,
  )
  use t, directory <- utils.next_create_directory(
    t,
    team.id,
    authorized_profile.auth_tokens.access_token,
  )

  use t, directory_status <- utils.next_create_directory_status(
    t,
    directory.id,
    authorized_profile.auth_tokens.access_token,
  )
  let response =
    router.handle_request(
      testing.get("/api/directories/" <> directory.id <> "/statuses", [
        utils.bearer_header(authorized_profile.auth_tokens.access_token),
      ]),
      t.context,
    )

  response
  |> utils.equal(
    json.array([directory_status], directory_status.to_json)
    |> json.to_string_tree
    |> wisp.json_response(200),
  )
}

pub fn find_all_directory_statuses_specific_directory_test() {
  use t <- utils.with_context

  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)
  use t, team <- utils.next_create_team(
    t,
    authorized_profile.auth_tokens.access_token,
  )
  use t, directory1 <- utils.next_create_directory(
    t,
    team.id,
    authorized_profile.auth_tokens.access_token,
  )
  use t, directory2 <- utils.next_create_directory(
    t,
    team.id,
    authorized_profile.auth_tokens.access_token,
  )

  use t, directory_status1 <- utils.next_create_directory_status(
    t,
    directory1.id,
    authorized_profile.auth_tokens.access_token,
  )
  use t, directory_status2 <- utils.next_create_directory_status(
    t,
    directory2.id,
    authorized_profile.auth_tokens.access_token,
  )
  let response =
    router.handle_request(
      testing.get("/api/directories/" <> directory1.id <> "/statuses", [
        utils.bearer_header(authorized_profile.auth_tokens.access_token),
      ]),
      t.context,
    )

  response
  |> utils.equal(
    json.array([directory_status1], directory_status.to_json)
    |> json.to_string_tree
    |> wisp.json_response(200),
  )
  let response =
    router.handle_request(
      testing.get("/api/directories/" <> directory2.id <> "/statuses", [
        utils.bearer_header(authorized_profile.auth_tokens.access_token),
      ]),
      t.context,
    )

  response
  |> utils.equal(
    json.array([directory_status2], directory_status.to_json)
    |> json.to_string_tree
    |> wisp.json_response(200),
  )
}

pub fn find_all_directory_statuses_directory_not_found_test() {
  use t <- utils.with_context

  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)

  let response =
    router.handle_request(
      testing.get("/api/directories/" <> utils.mock_uuidv4 <> "/statuses", [
        utils.bearer_header(authorized_profile.auth_tokens.access_token),
      ]),
      t.context,
    )

  response
  |> utils.equal(response_utils.directory_not_found_error_response())
}

pub fn find_all_directory_statuses_missing_authorization_header_test() {
  utils.missing_authorization_header_tester(
    http.Get,
    "/api/directories/1/statuses",
  )
}

pub fn find_all_directory_statuses_invalid_bearer_format_test() {
  utils.invalid_bearer_format_tester(http.Get, "/api/directories/1/statuses")
}

pub fn find_all_directory_statuses_invalid_jwt_test() {
  utils.invalid_jwt_tester(http.Get, "/api/directories/1/statuses")
}

pub fn find_all_directory_statuses_profile_required_test() {
  utils.profile_required_tester(http.Get, "/api/directories/1/statuses")
}
