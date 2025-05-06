import app/common/response_utils
import app/directory_status/inputs/create_directory_status_input
import app/directory_status/outputs/directory_status
import app/router
import gleam/http
import gleam/json
import gleeunit/should
import utils
import wisp/testing

pub fn create_directory_status_test() {
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

  use t, input <- utils.next_create_directory_status_input(t)
  let json = create_directory_status_input.to_json(input)

  let response =
    router.handle_request(
      testing.post_json(
        "/api/directories/" <> directory.id <> "/statuses",
        [utils.bearer_header(authorized_profile.auth_tokens.access_token)],
        json,
      ),
      t.context,
    )

  response |> utils.expect_status_code(201)
  let assert Ok(data) =
    json.parse(
      testing.string_body(response),
      directory_status.directory_status_decoder(),
    )
  data
  |> should.equal(directory_status.DirectoryStatus(
    data.id,
    input.name,
    data.directory_id,
  ))
}

pub fn create_directory_status_validate_name_test() {
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

  let input = create_directory_status_input.CreateDirectoryStatusInput("")
  let json = create_directory_status_input.to_json(input)

  let response =
    router.handle_request(
      testing.post_json(
        "/api/directories/" <> directory.id <> "/statuses",
        [utils.bearer_header(authorized_profile.auth_tokens.access_token)],
        json,
      ),
      t.context,
    )

  response
  |> utils.equal(response_utils.json_response(
    400,
    "name: must be atleast 2 characters long",
  ))
}

pub fn create_directory_status_not_member_of_directory_test() {
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
  use t, authorized_profile2 <- utils.next_create_user_and_profile_and_login(t)

  use t, input <- utils.next_create_directory_status_input(t)
  let json = create_directory_status_input.to_json(input)

  let response =
    router.handle_request(
      testing.post_json(
        "/api/directories/" <> directory.id <> "/statuses",
        [utils.bearer_header(authorized_profile2.auth_tokens.access_token)],
        json,
      ),
      t.context,
    )
  response |> utils.equal(response_utils.not_member_of_team_response())
}

pub fn create_directory_status_directory_not_found_test() {
  use t <- utils.with_context

  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)

  use t, input <- utils.next_create_directory_status_input(t)
  let json = create_directory_status_input.to_json(input)

  let response =
    router.handle_request(
      testing.post_json(
        "/api/directories/" <> utils.mock_uuidv4 <> "/statuses",
        [utils.bearer_header(authorized_profile.auth_tokens.access_token)],
        json,
      ),
      t.context,
    )

  response |> utils.equal(response_utils.directory_not_found_error_response())
}

pub fn create_directory_status_missing_authorization_header_test() {
  utils.missing_authorization_header_tester(
    http.Post,
    "/api/directories/1/statuses",
  )
}

pub fn create_directory_status_invalid_bearer_format_test() {
  utils.invalid_bearer_format_tester(http.Post, "/api/directories/1/statuses")
}

pub fn create_directory_status_invalid_jwt_test() {
  utils.invalid_jwt_tester(http.Post, "/api/directories/1/statuses")
}

pub fn create_directory_status_profile_required_test() {
  utils.profile_required_tester(http.Post, "/api/directories/1/statuses")
}
