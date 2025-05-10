import app/directory_status_type/outputs/directory_status_type
import app/router
import gleam/http
import gleam/json
import utils
import wisp
import wisp/testing

pub fn find_all_directory_status_types_test() {
  use t <- utils.with_context

  use t, authorized_user <- utils.next_create_user_and_login(t)

  let response =
    router.handle_request(
      testing.get("/api/directory_status_types", [
        utils.bearer_header(authorized_user.auth_tokens.access_token),
      ]),
      t.context,
    )

  response
  |> utils.equal(
    json.array(t.directory_status_types, directory_status_type.to_json)
    |> json.to_string_tree
    |> wisp.json_response(200),
  )
}

pub fn find_all_directory_status_types_missing_authorization_header_test() {
  utils.missing_authorization_header_tester(
    http.Get,
    "/api/directory_status_types",
  )
}

pub fn find_all_directory_status_types_invalid_bearer_format_test() {
  utils.invalid_bearer_format_tester(http.Get, "/api/directory_status_types")
}

pub fn find_all_directory_status_types_invalid_jwt_test() {
  utils.invalid_jwt_tester(http.Get, "/api/directory_status_types")
}
