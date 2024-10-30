import app/auth/auth_router
import app/auth/inputs/login_input.{LoginInput}
import app/auth/inputs/refresh_auth_tokens_input.{RefreshAuthTokensInput}
import app/router
import gleeunit/should
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

  response |> should.equal(auth_router.invalid_credentials_response())
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

  response |> should.equal(auth_router.invalid_credentials_response())
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

  response.status |> should.equal(201)
}
