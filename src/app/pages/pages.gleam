import app/auth/auth_service
import app/auth/inputs/login_input
import app/common/response_utils
import app/common/valid
import app/pages/create_user
import app/pages/index
import app/pages/login
import app/types.{type Context}
import app/user/inputs/create_user_input
import app/user/user_service
import gleam/http
import gleam/option
import wisp

pub fn router(
  req: wisp.Request,
  ctx: Context,
  handle_request: fn() -> wisp.Response,
) {
  case wisp.path_segments(req), req.method {
    ["login"], http.Get -> login.login()
    ["create-user"], http.Get -> create_user.create_user(option.None)
    ["index"], http.Get -> index.index()
    ["create-user"], http.Post -> create_user(req, ctx)
    ["login"], http.Post -> login(req, ctx)
    _, _ -> handle_request()
  }
}

fn create_user(req: wisp.Request, ctx: Context) {
  use json <- wisp.require_json(req)
  use input <- response_utils.or_decode_error(create_user_input.from_dynamic(
    json,
  ))

  let input = create_user_input.validate(input)
  case input {
    Ok(input) -> {
      let assert Ok(user) = user_service.create(input, ctx)

      use input <- response_utils.or_decode_error(login_input.from_dynamic(json))
      let assert Ok(input) = login_input.validate(input)
      let assert Ok(auth_tokens) = auth_service.login(input, ctx)

      wisp.ok()
      |> wisp.set_header("X-Access-Token", auth_tokens.access_token)
      |> wisp.set_header("X-Refresh-Token", auth_tokens.refresh_token)
      |> wisp.set_header("HX-Redirect", "/create-profile")
    }
    Error(invalid) ->
      create_user.create_user(option.Some(valid.errors(invalid)))
  }
}

fn login(req: wisp.Request, ctx: Context) {
  use json <- wisp.require_json(req)
  use input <- response_utils.or_decode_error(login_input.from_dynamic(json))
  use input <- valid.or_bad_request_response(login_input.validate(input))

  use result <- response_utils.map_service_errors(auth_service.login(input, ctx))

  wisp.redirect("/index")
}
