import app/profile/inputs/create_profile_input
import app/profile/outputs/profile
import app/router
import gleam/bit_array
import gleam/http
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option
import gleam/string
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

fn append_line(bit_array: BitArray, line: String) {
  bit_array
  |> bit_array.append(line |> bit_array.from_string)
  |> bit_array.append("\r\n" |> bit_array.from_string)
}

fn append_bytes(bit_array: BitArray, bytes: BitArray) {
  bit_array
  |> bit_array.append(bytes)
  |> bit_array.append("\r\n" |> bit_array.from_string)
}

fn post_file(
  method: http.Method,
  path: String,
  headers: List(http.Header),
  file_path: String,
) {
  let boundary = "abcde12345"
  let assert Ok(file_name) = string.split(file_path, "/") |> list.last
  let assert Ok(result) = simplifile.read_bits(file_path)
  let body =
    <<>>
    |> append_line("--" <> boundary)
    |> append_line(
      "Content-Disposition: form-data; name=\"file\"; filename=\""
      <> file_name
      <> "\"",
    )
    |> append_line("")
    |> append_bytes(result)
    |> append_line("--" <> boundary <> "--")
  testing.request(
    method,
    path,
    headers
      |> list.append([
        #("content-type", "multipart/form-data; boundary=" <> boundary),
      ]),
    body,
  )
}

pub fn upload_profile_picture_test() {
  use t <- utils.with_context()

  use t, authorized_profile <- utils.create_next_user_and_profile_and_login(t)

  let response =
    router.handle_request(
      post_file(
        http.Post,
        "/api/profiles/"
          <> authorized_profile.profile.id |> int.to_string()
          <> "/profile-picture",
        [utils.bearer_header(authorized_profile.auth_tokens.access_token)],
        "test/files/image_jpeg.jpg",
      ),
      t.context,
    )

  response.status |> should.equal(201)
  let assert Ok(data) =
    json.decode(testing.string_body(response), profile.decoder())
  io.debug(data.profile_picture)

  Nil
}
