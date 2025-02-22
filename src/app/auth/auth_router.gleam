import app/auth/auth_service
import app/auth/inputs/login_input
import app/auth/inputs/refresh_auth_tokens_input
import app/auth/outputs/auth_tokens
import app/auth/pages/login_page
import app/common/response_utils
import app/common/valid
import app/types.{type Context}
import gleam/http.{Post}
import gleam/json
import wisp.{type Request, type Response}

pub fn router(req: Request, ctx: Context, handle_request: fn() -> Response) {
  case wisp.path_segments(req), req.method {
    ["login"], http.Get -> login_page.login_page()
    ["login"], http.Post -> login(req, ctx)
    ["api", "auth", "login"], Post -> post_api_auth_login(req, ctx)
    ["api", "auth", "refresh_auth_tokens"], Post ->
      refresh_auth_tokens(req, ctx)
    _, _ -> handle_request()
  }
}

fn post_api_auth_login(req: Request, ctx: Context) {
  use json <- wisp.require_json(req)
  use input <- response_utils.or_decode_error(login_input.from_dynamic(json))
  use input <- valid.or_bad_request_response(login_input.validate(input))

  use result <- response_utils.map_service_errors(auth_service.login(input, ctx))

  auth_tokens.to_json(result)
  |> json.to_string_tree()
  |> wisp.json_response(201)
}

fn refresh_auth_tokens(req: Request, ctx: Context) {
  use json <- wisp.require_json(req)
  use input <- response_utils.or_decode_error(
    refresh_auth_tokens_input.from_dynamic(json),
  )

  use result <- response_utils.map_service_errors(
    auth_service.refresh_auth_tokens(input, ctx),
  )

  auth_tokens.to_json(result)
  |> json.to_string_tree()
  |> wisp.json_response(201)
}

fn login(req: wisp.Request, ctx: Context) {
  use json <- wisp.require_json(req)
  use input <- response_utils.or_decode_error(login_input.from_dynamic(json))
  use input <- valid.or_bad_request_response(login_input.validate(input))

  use result <- response_utils.map_service_errors(auth_service.login(input, ctx))

  wisp.ok()
  |> wisp.set_header("X-Access-Token", result.access_token)
  |> wisp.set_header("X-Refresh-Token", result.refresh_token)
  |> wisp.set_header("HX-Redirect", "/teams")
}
