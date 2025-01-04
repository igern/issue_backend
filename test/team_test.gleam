import app/router
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
