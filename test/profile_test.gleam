import app/profile/inputs/create_profile_input
import app/profile/outputs/profile
import app/router
import gleam/http
import gleam/int
import gleam/io
import gleam/json
import gleam/result
import gleeunit/should
import simplifile
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

pub fn create_profile_missing_authorization_header_test() {
  utils.missing_authorization_header_tester(http.Post, "/api/profiles")
}

pub fn create_profile_invalid_bearer_format_test() {
  utils.invalid_bearer_format_tester(http.Post, "/api/profiles")
}

pub fn create_profile_invalid_jwt_test() {
  utils.invalid_jwt_tester(http.Post, "/api/profiles")
}

pub fn upload_profile_picture_test() {
  use t <- utils.with_context()

  use t, authorized_profile <- utils.create_next_user_and_profile_and_login(t)

  let assert Ok(result) = simplifile.read_bits("test/files/image_jpeg.jpg")

  let response =
    router.handle_request(
      testing.request(
        http.Put,
        "/api/profiles/"
          <> authorized_profile.profile.id |> int.to_string()
          <> "/profile-picture",
        [
          #("content-type", "image/jpeg"),
          utils.bearer_header(authorized_profile.auth_tokens.access_token),
        ],
        result,
      ),
      t.context,
    )

  response.status |> should.equal(201)
}
