import app/common/response_utils
import app/profile/profile_service
import app/router
import app/user/inputs/create_user_input
import app/user/outputs/user.{User}
import app/user/user_service
import gleam/http
import gleam/json
import gleeunit/should
import sqlight
import utils
import wisp
import wisp/testing

pub fn create_user_test() {
  use t <- utils.with_context

  use t, input <- utils.next_create_user_input(t)
  let json = create_user_input.to_json(input)

  let response =
    router.handle_request(testing.post_json("api/users", [], json), t.context)

  response.status |> should.equal(201)

  let assert Ok(data) =
    json.decode(testing.string_body(response), user.decoder())
  data |> should.equal(User(id: data.id, email: input.email))
}

pub fn delete_one_user_test() {
  use t <- utils.with_context

  use t, authorized_user <- utils.create_next_user_and_login(t)

  let response =
    router.handle_request(
      testing.delete_json(
        "api/users/" <> authorized_user.user.id,
        [utils.bearer_header(authorized_user.auth_tokens.access_token)],
        json.object([]),
      ),
      t.context,
    )

  response
  |> utils.response_equal(
    user.to_json(authorized_user.user)
    |> json.to_string_tree()
    |> wisp.json_response(200),
  )
}

pub fn delete_one_user_not_found_test() {
  use t <- utils.with_context

  use t, authorized_user <- utils.create_next_user_and_login(t)

  let sql = "delete from users where id = ? returning *"

  let assert Ok(_) =
    sqlight.query(
      sql,
      t.context.connection,
      [sqlight.text(authorized_user.user.id)],
      user_service.user_decoder(),
    )
  let response =
    router.handle_request(
      testing.delete_json(
        "api/users/" <> authorized_user.user.id,
        [utils.bearer_header(authorized_user.auth_tokens.access_token)],
        json.object([]),
      ),
      t.context,
    )

  response
  |> utils.response_equal(response_utils.user_not_found_error_response())
}

pub fn delete_one_user_with_profile_test() {
  use t <- utils.with_context

  use t, authorized_profil <- utils.create_next_user_and_profile_and_login(t)

  let response =
    router.handle_request(
      testing.delete_json(
        "api/users/" <> authorized_profil.user.id,
        [utils.bearer_header(authorized_profil.auth_tokens.access_token)],
        json.object([]),
      ),
      t.context,
    )

  let sql = "select * from profiles where id = ?"
  let result =
    sqlight.query(
      sql,
      t.context.connection,
      [sqlight.text(authorized_profil.profile.id)],
      profile_service.profile_decoder(),
    )
  result |> should.equal(Ok([]))

  response
  |> utils.response_equal(
    authorized_profil.user
    |> user.to_json()
    |> json.to_string_tree()
    |> wisp.json_response(200),
  )
}

pub fn delete_one_user_other_user_test() {
  use t <- utils.with_context

  use t, authorized_profil1 <- utils.create_next_user_and_profile_and_login(t)
  use t, authorized_profil2 <- utils.create_next_user_and_profile_and_login(t)

  let response =
    router.handle_request(
      testing.delete_json(
        "api/users/" <> authorized_profil2.user.id,
        [utils.bearer_header(authorized_profil1.auth_tokens.access_token)],
        json.object([]),
      ),
      t.context,
    )

  response
  |> utils.response_equal(response_utils.can_not_delete_other_user_response())
}

pub fn delete_one_user_missing_authorization_header_test() {
  utils.missing_authorization_header_tester(http.Delete, "/api/users/1")
}

pub fn delete_one_user_invalid_bearer_format_test() {
  utils.invalid_bearer_format_tester(http.Delete, "/api/users/1")
}

pub fn delete_one_user_invalid_jwt_test() {
  utils.invalid_jwt_tester(http.Delete, "/api/users/1")
}
