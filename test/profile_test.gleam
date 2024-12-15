import app/profile/inputs/create_profile_input
import app/profile/outputs/profile
import app/router
import gleam/json
import gleeunit/should
import utils
import wisp/testing

pub fn create_profile_test() {
  use t <- utils.with_context

  use t, authorized_user <- utils.create_next_user_and_login(t)

  use t, input <- utils.next_create_profile_input(t)
  let json = create_profile_input.to_json(input)

  let response =
    router.handle_request(
      testing.post_json(
        "/api/profiles",
        [utils.bearer_header(authorized_user.auth_tokens.access_token)],
        json,
      ),
      t.context,
    )

  response.status |> should.equal(201)
  let assert Ok(data) =
    json.decode(testing.string_body(response), profile.decoder())

  data
  |> should.equal(profile.Profile(
    id: data.id,
    user_id: authorized_user.user.id,
    name: data.name,
  ))
}
