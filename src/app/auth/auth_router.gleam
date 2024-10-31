import app/auth/auth_service
import app/auth/inputs/login_input
import app/auth/inputs/refresh_auth_tokens_input
import app/auth/outputs/auth_tokens
import app/common/response_utils
import app/types.{type Context}
import gleam/http.{Post}
import gleam/json
import wisp.{type Request, type Response}

pub fn router(req: Request, ctx: Context, handle_request: fn() -> Response) {
  case wisp.path_segments(req), req.method {
    ["auth", "login"], Post -> login(req, ctx)
    ["auth", "refresh_auth_tokens"], Post -> refresh_auth_tokens(req, ctx)
    _, _ -> handle_request()
  }
}

fn login(req: Request, ctx: Context) {
  use json <- wisp.require_json(req)
  use input <- response_utils.or_decode_error(login_input.from_dynamic(json))

  use result <- response_utils.map_service_errors(auth_service.login(input, ctx))

  auth_tokens.to_json(result)
  |> json.to_string_builder()
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
  |> json.to_string_builder()
  |> wisp.json_response(201)
}
