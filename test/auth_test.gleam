import app/auth/inputs/login_input.{LoginInput}
import app/auth/inputs/refresh_auth_tokens_input.{RefreshAuthTokensInput}
import app/common/response_utils
import app/router
import birl
import gleam/dynamic
import gleeunit/should
import sqlight
import utils
import wisp/testing

pub fn login_test() {
  use t <- utils.with_context

  use t, input <- utils.next_create_user_input(t)
  use _ <- utils.create_user(t, input)
  let input =
    login_input.to_json(LoginInput(email: input.email, password: input.password))

  let response =
    router.handle_request(
      testing.post_json("/auth/login", [], input),
      t.context,
    )

  response.status |> should.equal(201)
}

pub fn login_invalid_email_test() {
  use t <- utils.with_context
  let input =
    login_input.to_json(LoginInput(
      email: "jonas@hotmail.com",
      password: "secret1234",
    ))

  let response =
    router.handle_request(
      testing.post_json("/auth/login", [], input),
      t.context,
    )

  response |> should.equal(response_utils.invalid_credentials_response())
}

pub fn login_invalid_password_test() {
  use t <- utils.with_context

  use t, user <- utils.create_next_user(t)

  let input =
    login_input.to_json(LoginInput(
      email: user.email,
      password: "invalid password",
    ))

  let response =
    router.handle_request(
      testing.post_json("/auth/login", [], input),
      t.context,
    )

  response |> should.equal(response_utils.invalid_credentials_response())
}

pub fn refresh_auth_tokens_test() {
  use t <- utils.with_context

  use t, user <- utils.create_next_user_and_login(t)

  let input =
    refresh_auth_tokens_input.to_json(RefreshAuthTokensInput(
      refresh_token: user.auth_tokens.refresh_token,
    ))

  let response =
    router.handle_request(
      testing.post_json("/auth/refresh_auth_tokens", [], input),
      t.context,
    )

  let sql = "select * from refresh_tokens where token = ?"

  let assert Ok([]) =
    sqlight.query(
      sql,
      t.context.connection,
      [sqlight.text(user.auth_tokens.refresh_token)],
      dynamic.tuple3(dynamic.string, dynamic.int, dynamic.string),
    )

  response.status |> should.equal(201)
}

pub fn refresh_auth_tokens_not_found_test() {
  use t <- utils.with_context

  let input =
    refresh_auth_tokens_input.to_json(RefreshAuthTokensInput(
      refresh_token: "invalid token",
    ))

  let response =
    router.handle_request(
      testing.post_json("/auth/refresh_auth_tokens", [], input),
      t.context,
    )

  response
  |> should.equal(response_utils.refresh_token_not_found_error_response())
}

pub fn refresh_auth_tokens_expired_test() {
  use t <- utils.with_context
  use t, user <- utils.create_next_user_and_login(t)

  let sql = "update refresh_tokens set expiresAt = ? where token = ?"
  let assert Ok(_) =
    sqlight.query(
      sql,
      on: t.context.connection,
      with: [
        sqlight.text(birl.now() |> birl.to_iso8601),
        sqlight.text(user.auth_tokens.refresh_token),
      ],
      expecting: dynamic.tuple3(dynamic.string, dynamic.int, dynamic.string),
    )

  let input =
    refresh_auth_tokens_input.to_json(RefreshAuthTokensInput(
      refresh_token: user.auth_tokens.refresh_token,
    ))

  let response =
    router.handle_request(
      testing.post_json("/auth/refresh_auth_tokens", [], input),
      t.context,
    )

  response
  |> should.equal(response_utils.refresh_token_expired_error_response())
}
