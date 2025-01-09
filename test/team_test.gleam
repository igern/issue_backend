import app/common/response_utils
import app/router
import app/team/inputs/add_to_team_input.{AddToTeamInput}
import app/team/inputs/create_team_input
import app/team/outputs/team
import gleam/http
import gleam/json
import gleeunit/should
import utils
import wisp/testing

pub fn create_team_test() {
  use t <- utils.with_context

  use t, auth_profile <- utils.next_create_user_and_profile_and_login(t)

  use t, input <- utils.next_create_team_input(t)
  let json = create_team_input.to_json(input)

  let response =
    router.handle_request(
      testing.post_json(
        "/api/teams",
        [utils.bearer_header(auth_profile.auth_tokens.access_token)],
        json,
      ),
      t.context,
    )

  response.status |> should.equal(201)
  let assert Ok(data) =
    json.decode(testing.string_body(response), team.decoder())
  data
  |> should.equal(team.Team(
    id: data.id,
    name: input.name,
    owner_id: auth_profile.profile.id,
  ))
}

pub fn create_team_missing_authorization_header_test() {
  utils.missing_authorization_header_tester(http.Post, "/api/teams")
}

pub fn create_team_invalid_bearer_format_test() {
  utils.invalid_bearer_format_tester(http.Post, "/api/teams")
}

pub fn create_team_invalid_jwt_test() {
  utils.invalid_jwt_tester(http.Post, "/api/teams")
}

pub fn create_team_profile_required_test() {
  utils.profile_required_tester(http.Post, "/api/teams")
}

pub fn delete_team_test() {
  use t <- utils.with_context

  use t, auth_profile <- utils.next_create_user_and_profile_and_login(t)

  use t, team <- utils.next_create_team(
    t,
    auth_profile.auth_tokens.access_token,
  )

  let response =
    router.handle_request(
      testing.delete_json(
        "/api/teams/" <> team.id,
        [utils.bearer_header(auth_profile.auth_tokens.access_token)],
        json.object([]),
      ),
      t.context,
    )

  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), team.decoder())
  data
  |> should.equal(team)
}

pub fn delete_team_not_found_test() {
  use t <- utils.with_context

  use t, auth_profile <- utils.next_create_user_and_profile_and_login(t)
  let response =
    router.handle_request(
      testing.delete_json(
        "/api/teams/1",
        [utils.bearer_header(auth_profile.auth_tokens.access_token)],
        json.object([]),
      ),
      t.context,
    )

  response
  |> utils.response_equal(response_utils.team_not_found_error_response())
}

pub fn delete_team_can_not_delete_other_teams_test() {
  use t <- utils.with_context

  use t, auth_profile <- utils.next_create_user_and_profile_and_login(t)
  use t, auth_profile2 <- utils.next_create_user_and_profile_and_login(t)

  use t, team <- utils.next_create_team(
    t,
    auth_profile.auth_tokens.access_token,
  )

  let response =
    router.handle_request(
      testing.delete_json(
        "/api/teams/" <> team.id,
        [utils.bearer_header(auth_profile2.auth_tokens.access_token)],
        json.object([]),
      ),
      t.context,
    )

  response
  |> utils.response_equal(response_utils.can_not_delete_other_teams_response())
}

pub fn delete_team_missing_authorization_header_test() {
  utils.missing_authorization_header_tester(http.Delete, "/api/teams/1")
}

pub fn delete_team_invalid_bearer_format_test() {
  utils.invalid_bearer_format_tester(http.Delete, "/api/teams/1")
}

pub fn delete_team_invalid_jwt_test() {
  utils.invalid_jwt_tester(http.Delete, "/api/teams/1")
}

pub fn delete_team_profile_required_test() {
  utils.profile_required_tester(http.Delete, "/api/teams/1")
}

pub fn add_to_team_test() {
  use t <- utils.with_context

  use t, auth_profile1 <- utils.next_create_user_and_profile_and_login(t)
  use t, auth_profile2 <- utils.next_create_user_and_profile_and_login(t)
  use t, team <- utils.next_create_team(
    t,
    auth_profile1.auth_tokens.access_token,
  )

  let json =
    AddToTeamInput(auth_profile2.profile.id) |> add_to_team_input.to_json

  let response =
    router.handle_request(
      testing.post_json(
        "/api/teams/" <> team.id,
        [utils.bearer_header(auth_profile1.auth_tokens.access_token)],
        json,
      ),
      t.context,
    )

  response.status |> should.equal(201)
}

pub fn add_to_team_profile_not_found_test() {
  use t <- utils.with_context

  use t, auth_profile1 <- utils.next_create_user_and_profile_and_login(t)
  use t, team <- utils.next_create_team(
    t,
    auth_profile1.auth_tokens.access_token,
  )

  let json = AddToTeamInput(utils.mock_uuidv4) |> add_to_team_input.to_json

  let response =
    router.handle_request(
      testing.post_json(
        "/api/teams/" <> team.id,
        [utils.bearer_header(auth_profile1.auth_tokens.access_token)],
        json,
      ),
      t.context,
    )

  response
  |> utils.response_equal(response_utils.profile_not_found_error_response())
}

pub fn add_to_team_missing_authorization_header_test() {
  utils.missing_authorization_header_tester(http.Post, "/api/teams/1")
}

pub fn add_to_team_invalid_bearer_format_test() {
  utils.invalid_bearer_format_tester(http.Post, "/api/teams/1")
}

pub fn add_to_team_invalid_jwt_test() {
  utils.invalid_jwt_tester(http.Post, "/api/teams/1")
}

pub fn add_to_team_profile_required_test() {
  utils.profile_required_tester(http.Post, "/api/teams/1")
}
