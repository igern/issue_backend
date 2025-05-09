import app/common/response_utils
import app/router
import app/team/inputs/add_to_team_input.{AddToTeamInput}
import app/team/inputs/create_team_input
import app/team/outputs/team
import app/team/outputs/team_profile
import gleam/http
import gleam/json
import gleeunit/should
import utils
import wisp
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
    json.parse(testing.string_body(response), team.decoder())
  data
  |> should.equal(team.Team(
    id: data.id,
    name: input.name,
    owner_id: auth_profile.profile.id,
  ))
}

pub fn create_team_validate_name_test() {
  use t <- utils.with_context

  use t, auth_profile <- utils.next_create_user_and_profile_and_login(t)

  let input = create_team_input.CreateTeamInput(name: "k")
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

  response
  |> utils.equal(response_utils.json_response(
    400,
    "name: must be atleast 2 characters long",
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
    json.parse(testing.string_body(response), team.decoder())
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
  |> utils.equal(response_utils.team_not_found_error_response())
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
  |> utils.equal(response_utils.can_not_delete_other_teams_response())
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
  |> utils.equal(response_utils.profile_not_found_error_response())
}

pub fn add_to_team_not_team_owner_test() {
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
        [utils.bearer_header(auth_profile2.auth_tokens.access_token)],
        json,
      ),
      t.context,
    )

  response |> utils.equal(response_utils.not_team_owner_response())
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

pub fn delete_from_team_test() {
  use t <- utils.with_context

  use t, auth_profile1 <- utils.next_create_user_and_profile_and_login(t)
  use t, auth_profile2 <- utils.next_create_user_and_profile_and_login(t)
  use t, team <- utils.next_create_team(
    t,
    auth_profile1.auth_tokens.access_token,
  )

  use <- utils.add_to_team(
    t,
    team.id,
    AddToTeamInput(auth_profile2.profile.id),
    auth_profile1.auth_tokens.access_token,
  )

  let response =
    router.handle_request(
      testing.delete_json(
        "/api/teams/" <> team.id <> "/profiles/" <> auth_profile2.profile.id,
        [utils.bearer_header(auth_profile1.auth_tokens.access_token)],
        json.object([]),
      ),
      t.context,
    )
  response.status |> should.equal(200)
}

pub fn delete_from_team_team_not_found_test() {
  use t <- utils.with_context

  use t, auth_profile1 <- utils.next_create_user_and_profile_and_login(t)

  let response =
    router.handle_request(
      testing.delete_json(
        "/api/teams/" <> utils.mock_uuidv4 <> "/profiles/" <> utils.mock_uuidv4,
        [utils.bearer_header(auth_profile1.auth_tokens.access_token)],
        json.object([]),
      ),
      t.context,
    )
  response
  |> utils.equal(response_utils.team_not_found_error_response())
}

pub fn delete_from_team_profile_not_found_test() {
  use t <- utils.with_context

  use t, auth_profile1 <- utils.next_create_user_and_profile_and_login(t)
  use t, team <- utils.next_create_team(
    t,
    auth_profile1.auth_tokens.access_token,
  )

  let response =
    router.handle_request(
      testing.delete_json(
        "/api/teams/" <> team.id <> "/profiles/" <> utils.mock_uuidv4,
        [utils.bearer_header(auth_profile1.auth_tokens.access_token)],
        json.object([]),
      ),
      t.context,
    )

  response
  |> utils.equal(response_utils.profile_not_found_error_response())
}

pub fn delete_from_team_not_team_owner_test() {
  use t <- utils.with_context

  use t, auth_profile1 <- utils.next_create_user_and_profile_and_login(t)
  use t, auth_profile2 <- utils.next_create_user_and_profile_and_login(t)
  use t, team <- utils.next_create_team(
    t,
    auth_profile1.auth_tokens.access_token,
  )

  use <- utils.add_to_team(
    t,
    team.id,
    AddToTeamInput(auth_profile2.profile.id),
    auth_profile1.auth_tokens.access_token,
  )

  let response =
    router.handle_request(
      testing.delete_json(
        "/api/teams/" <> team.id <> "/profiles/" <> auth_profile1.profile.id,
        [utils.bearer_header(auth_profile2.auth_tokens.access_token)],
        json.object([]),
      ),
      t.context,
    )
  response |> utils.equal(response_utils.not_team_owner_response())
}

pub fn delete_from_team_cannot_kick_team_owner_test() {
  use t <- utils.with_context

  use t, auth_profile1 <- utils.next_create_user_and_profile_and_login(t)
  use t, team <- utils.next_create_team(
    t,
    auth_profile1.auth_tokens.access_token,
  )

  let response =
    router.handle_request(
      testing.delete_json(
        "/api/teams/" <> team.id <> "/profiles/" <> auth_profile1.profile.id,
        [utils.bearer_header(auth_profile1.auth_tokens.access_token)],
        json.object([]),
      ),
      t.context,
    )
  response |> utils.equal(response_utils.cannot_kick_team_owner_of_team())
}

pub fn delete_from_team_missing_authorization_header_test() {
  utils.missing_authorization_header_tester(
    http.Delete,
    "/api/teams/1/profiles/1",
  )
}

pub fn delete_from_team_invalid_bearer_format_test() {
  utils.invalid_bearer_format_tester(http.Delete, "/api/teams/1/profiles/1")
}

pub fn delete_from_team_invalid_jwt_test() {
  utils.invalid_jwt_tester(http.Delete, "/api/teams/1/profiles/1")
}

pub fn delete_from_team_profile_required_test() {
  utils.profile_required_tester(http.Delete, "/api/teams/1/profiles/1")
}

pub fn find_team_test() {
  use t <- utils.with_context

  use t, auth_profile <- utils.next_create_user_and_profile_and_login(t)
  use t, team <- utils.next_create_team(
    t,
    auth_profile.auth_tokens.access_token,
  )

  let response =
    router.handle_request(
      testing.get("/api/teams/" <> team.id, [
        utils.bearer_header(auth_profile.auth_tokens.access_token),
      ]),
      t.context,
    )

  utils.equal(
    response,
    team.to_json(team) |> json.to_string_tree |> wisp.json_response(200),
  )
}

pub fn find_team_not_member_test() {
  use t <- utils.with_context

  use t, auth_profile1 <- utils.next_create_user_and_profile_and_login(t)
  use t, team <- utils.next_create_team(
    t,
    auth_profile1.auth_tokens.access_token,
  )
  use t, auth_profile2 <- utils.next_create_user_and_profile_and_login(t)

  let response =
    router.handle_request(
      testing.get("/api/teams/" <> team.id, [
        utils.bearer_header(auth_profile2.auth_tokens.access_token),
      ]),
      t.context,
    )

  utils.equal(response, response_utils.not_member_of_team_response())
}

pub fn find_team_invalid_team_test() {
  use t <- utils.with_context

  use t, auth_profile <- utils.next_create_user_and_profile_and_login(t)

  let response =
    router.handle_request(
      testing.get("/api/teams/" <> utils.mock_uuidv4, [
        utils.bearer_header(auth_profile.auth_tokens.access_token),
      ]),
      t.context,
    )

  utils.equal(response, response_utils.not_member_of_team_response())
}

pub fn find_team_as_member_test() {
  use t <- utils.with_context

  use t, auth_profile1 <- utils.next_create_user_and_profile_and_login(t)
  use t, auth_profile2 <- utils.next_create_user_and_profile_and_login(t)
  use t, team <- utils.next_create_team(
    t,
    auth_profile1.auth_tokens.access_token,
  )
  use <- utils.add_to_team(
    t,
    team.id,
    AddToTeamInput(auth_profile2.profile.id),
    auth_profile1.auth_tokens.access_token,
  )

  let response =
    router.handle_request(
      testing.get("/api/teams/" <> team.id, [
        utils.bearer_header(auth_profile2.auth_tokens.access_token),
      ]),
      t.context,
    )

  utils.equal(
    response,
    team.to_json(team) |> json.to_string_tree |> wisp.json_response(200),
  )
}

pub fn find_team_missing_authorization_header_test() {
  utils.missing_authorization_header_tester(http.Get, "/api/teams/1")
}

pub fn find_team_invalid_bearer_format_test() {
  utils.invalid_bearer_format_tester(http.Get, "/api/teams/1")
}

pub fn find_team_invalid_jwt_test() {
  utils.invalid_jwt_tester(http.Get, "/api/teams/1")
}

pub fn find_team_profile_required_test() {
  utils.profile_required_tester(http.Get, "/api/teams/1")
}

pub fn find_profiles_from_team_test() {
  use t <- utils.with_context

  use t, auth_profile <- utils.next_create_user_and_profile_and_login(t)
  use t, team <- utils.next_create_team(
    t,
    auth_profile.auth_tokens.access_token,
  )

  let response =
    router.handle_request(
      testing.get("/api/teams/" <> team.id <> "/profiles", [
        utils.bearer_header(auth_profile.auth_tokens.access_token),
      ]),
      t.context,
    )

  utils.equal(
    response,
    json.array(
      [team_profile.TeamProfile(team.id, auth_profile.profile.id)],
      team_profile.to_json,
    )
      |> json.to_string_tree
      |> wisp.json_response(200),
  )
}

pub fn find_profiles_from_team_not_member_of_team_test() {
  use t <- utils.with_context

  use t, auth_profile <- utils.next_create_user_and_profile_and_login(t)
  use t, team <- utils.next_create_team(
    t,
    auth_profile.auth_tokens.access_token,
  )

  use t, auth_profile2 <- utils.next_create_user_and_profile_and_login(t)
  let response =
    router.handle_request(
      testing.get("/api/teams/" <> team.id <> "/profiles", [
        utils.bearer_header(auth_profile2.auth_tokens.access_token),
      ]),
      t.context,
    )

  utils.equal(response, response_utils.not_member_of_team_response())
}

pub fn find_profiles_from_team_team_not_found_test() {
  use t <- utils.with_context

  use t, auth_profile <- utils.next_create_user_and_profile_and_login(t)
  let response =
    router.handle_request(
      testing.get("/api/teams/" <> utils.mock_uuidv4 <> "/profiles", [
        utils.bearer_header(auth_profile.auth_tokens.access_token),
      ]),
      t.context,
    )

  utils.equal(response, response_utils.not_member_of_team_response())
}

pub fn find_profiles_tom_team_missing_authorization_header_test() {
  utils.missing_authorization_header_tester(http.Get, "/api/teams/1/profiles")
}

pub fn find_profiles_tom_team_invalid_bearer_format_test() {
  utils.invalid_bearer_format_tester(http.Get, "/api/teams/1/profiles")
}

pub fn find_profiles_tom_team_invalid_jwt_test() {
  utils.invalid_jwt_tester(http.Get, "/api/teams/1/profiles")
}

pub fn find_profiles_tom_team_profile_required_test() {
  utils.profile_required_tester(http.Get, "/api/teams/1/profiles")
}

pub fn find_teams_from_current_profile_test() {
  use t <- utils.with_context

  use t, auth_profile1 <- utils.next_create_user_and_profile_and_login(t)
  use t, team1 <- utils.next_create_team(
    t,
    auth_profile1.auth_tokens.access_token,
  )
  use t, auth_profile2 <- utils.next_create_user_and_profile_and_login(t)
  use t, team2 <- utils.next_create_team(
    t,
    auth_profile2.auth_tokens.access_token,
  )
  use <- utils.add_to_team(
    t,
    team2.id,
    AddToTeamInput(auth_profile1.profile.id),
    auth_profile2.auth_tokens.access_token,
  )

  let response =
    router.handle_request(
      testing.get("/api/profiles/me/teams", [
        utils.bearer_header(auth_profile1.auth_tokens.access_token),
      ]),
      t.context,
    )

  utils.equal(
    response,
    json.array([team1, team2], team.to_json)
      |> json.to_string_tree
      |> wisp.json_response(200),
  )
}

pub fn find_teams_from_current_profile_missing_authorization_header_test() {
  utils.missing_authorization_header_tester(http.Get, "/api/profiles/me/teams")
}

pub fn find_teams_from_current_profile_invalid_bearer_format_test() {
  utils.invalid_bearer_format_tester(http.Get, "/api/profiles/me/teams")
}

pub fn find_teams_from_current_profile_invalid_jwt_test() {
  utils.invalid_jwt_tester(http.Get, "/api/profiles/me/teams")
}

pub fn find_teams_from_current_profile_profile_required_test() {
  utils.profile_required_tester(http.Get, "/api/profiles/me/teams")
}
