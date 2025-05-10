import app/common/response_utils
import app/directory_status/inputs/update_directory_status_input
import app/directory_status/outputs/directory_status
import app/router
import gleam/http
import gleam/json
import gleam/option
import utils
import wisp
import wisp/testing

pub fn update_directory_status_test() {
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

  use t, input <- utils.next_update_directory_status_input(t)
  let json = update_directory_status_input.to_json(input)

  let response =
    router.handle_request(
      testing.patch_json(
        "/api/directory-statuses/" <> directory_status.id,
        [utils.bearer_header(authorized_profile.auth_tokens.access_token)],
        json,
      ),
      t.context,
    )

  response
  |> utils.equal(
    directory_status.to_json(
      directory_status.DirectoryStatus(
        ..directory_status,
        name: option.unwrap(input.name, "invalid"),
      ),
    )
    |> json.to_string_tree
    |> wisp.json_response(200),
  )
}

pub fn update_directory_status_no_update_test() {
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
      testing.patch_json(
        "/api/directory-statuses/" <> directory_status.id,
        [utils.bearer_header(authorized_profile.auth_tokens.access_token)],
        json.object([]),
      ),
      t.context,
    )

  response
  |> utils.equal(
    directory_status.to_json(directory_status)
    |> json.to_string_tree
    |> wisp.json_response(200),
  )
}

pub fn update_directory_status_not_found_test() {
  use t <- utils.with_context

  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)

  let response =
    router.handle_request(
      testing.patch_json(
        "/api/directory-statuses/" <> utils.mock_uuidv4,
        [utils.bearer_header(authorized_profile.auth_tokens.access_token)],
        json.object([]),
      ),
      t.context,
    )

  response
  |> utils.equal(response_utils.directory_status_not_found_error_response())
}

pub fn update_directory_status_not_member_of_directory_test() {
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
  use t, authorized_profile2 <- utils.next_create_user_and_profile_and_login(t)

  let response =
    router.handle_request(
      testing.patch_json(
        "/api/directory-statuses/" <> directory_status.id,
        [utils.bearer_header(authorized_profile2.auth_tokens.access_token)],
        json.object([]),
      ),
      t.context,
    )
  response |> utils.equal(response_utils.not_member_of_team_response())
}

pub fn update_directory_status_missing_authorization_header_test() {
  utils.missing_authorization_header_tester(
    http.Patch,
    "/api/directory-statuses/1",
  )
}

pub fn update_directory_status_invalid_bearer_format_test() {
  utils.invalid_bearer_format_tester(http.Patch, "/api/directory-statuses/1")
}

pub fn update_directory_status_invalid_jwt_test() {
  utils.invalid_jwt_tester(http.Patch, "/api/directory-statuses/1")
}

pub fn update_directory_status_profile_required_test() {
  utils.profile_required_tester(http.Patch, "/api/directory-statuses/1")
}
