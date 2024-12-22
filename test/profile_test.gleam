import app/common/response_utils
import app/profile/inputs/create_profile_input
import app/profile/outputs/profile
import app/profile/profile_service
import app/router
import app/types
import bucket
import gleam/http
import gleam/httpc
import gleam/int
import gleam/json
import gleam/option
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
    profile_picture: option.None,
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

  let response =
    router.handle_request(
      utils.post_file(
        "/api/profiles/"
          <> authorized_profile.profile.id |> int.to_string()
          <> "/profile-picture",
        [utils.bearer_header(authorized_profile.auth_tokens.access_token)],
        utils.jpg,
      ),
      t.context,
    )

  response.status |> should.equal(201)
  let assert Ok(data) =
    json.decode(testing.string_body(response), profile.decoder())

  data.profile_picture |> should.be_some
  Nil
}

pub fn upload_profile_picture_can_not_update_other_profile_test() {
  use t <- utils.with_context()

  use t, authorized_profile1 <- utils.create_next_user_and_profile_and_login(t)
  use t, authorized_profile2 <- utils.create_next_user_and_profile_and_login(t)

  let response =
    router.handle_request(
      utils.post_file(
        "/api/profiles/"
          <> authorized_profile2.profile.id |> int.to_string()
          <> "/profile-picture",
        [utils.bearer_header(authorized_profile1.auth_tokens.access_token)],
        utils.jpg,
      ),
      t.context,
    )

  response
  |> utils.response_equal(
    response_utils.can_not_update_other_profile_response(),
  )
}

pub fn upload_profile_picture_invalid_file_type_test() {
  use t <- utils.with_context()

  use t, authorized_profile <- utils.create_next_user_and_profile_and_login(t)

  let response =
    router.handle_request(
      utils.post_file(
        "/api/profiles/"
          <> authorized_profile.profile.id |> int.to_string()
          <> "/profile-picture",
        [utils.bearer_header(authorized_profile.auth_tokens.access_token)],
        utils.png,
      ),
      t.context,
    )

  response
  |> utils.response_equal(response_utils.json_response(400, "invalid file type"))
}

pub fn upload_profile_picture_file_read_error_test() {
  use t <- utils.with_context()
  profile_service.upload_profile_picture("invalid.jpg", 1, t.context)
  |> should.equal(Error(response_utils.FileReadError(simplifile.Enoent)))
}

pub fn upload_profile_picture_profile_not_found_test() {
  use t <- utils.with_context()
  profile_service.upload_profile_picture(utils.jpg, 1, t.context)
  |> should.equal(Error(response_utils.ProfileNotFoundError))
}

pub fn upload_profile_picture_file_upload_error_test() {
  use t <- utils.with_context()
  let t =
    utils.TestContext(
      ..t,
      context: types.Context(
        ..t.context,
        storage_credentials: bucket.Credentials(
          ..t.context.storage_credentials,
          host: "Invalid",
        ),
      ),
    )
  profile_service.upload_profile_picture(utils.jpg, 1, t.context)
  |> should.equal(
    Error(
      response_utils.FileUploadError(httpc.FailedToConnect(
        httpc.Posix("nxdomain"),
        httpc.Posix("nxdomain"),
      )),
    ),
  )
}

pub fn upload_profile_picture_missing_authorization_header_test() {
  utils.missing_authorization_header_tester(
    http.Post,
    "/api/profiles/1/profile-picture",
  )
}

pub fn upload_profile_picture_invalid_bearer_format_test() {
  utils.invalid_bearer_format_tester(
    http.Post,
    "/api/profiles/1/profile-picture",
  )
}

pub fn upload_profile_picture_invalid_jwt_test() {
  utils.invalid_jwt_tester(http.Post, "/api/profiles/1/profile-picture")
}

pub fn upload_profile_picture_profile_required_test() {
  utils.profile_required_tester(http.Post, "/api/profiles/1/profile-picture")
}
