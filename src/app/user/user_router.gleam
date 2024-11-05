import app/common/response_utils
import app/types.{type Context}
import app/user/inputs/create_user_input
import app/user/outputs/user
import app/user/user_service
import gleam/http.{Post}
import gleam/json
import wisp.{type Request, type Response}

pub fn router(req: Request, ctx: Context, handle_request: fn() -> Response) {
  case wisp.path_segments(req), req.method {
    ["api", "users"], Post -> create_user(req, ctx)
    _, _ -> handle_request()
  }
}

fn create_user(req: Request, ctx: Context) {
  use json <- wisp.require_json(req)
  use input <- response_utils.or_decode_error(create_user_input.from_dynamic(
    json,
  ))

  use result <- response_utils.map_service_errors(user_service.create(
    input,
    ctx,
  ))

  user.to_json(result)
  |> json.to_string_builder()
  |> wisp.json_response(201)
}
