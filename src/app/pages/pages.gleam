import app/common/response_utils
import app/pages/create_profile
import app/pages/login
import app/types.{type Context}
import app/user/inputs/create_user_input
import app/user/user_service
import gleam/http
import wisp

pub fn router(
  req: wisp.Request,
  ctx: Context,
  handle_request: fn() -> wisp.Response,
) {
  case wisp.path_segments(req), req.method {
    ["login"], http.Get -> login.login()
    ["create-profile"], http.Get -> create_profile.create_profile()
    ["user"], http.Post -> create_user(req, ctx)
    _, _ -> handle_request()
  }
}

fn create_user(req: wisp.Request, ctx: Context) {
  use json <- wisp.require_json(req)
  use input <- response_utils.or_decode_error(create_user_input.from_dynamic(
    json,
  ))

  use result <- response_utils.map_service_errors(user_service.create(
    input,
    ctx,
  ))

  wisp.redirect("/login")
}
