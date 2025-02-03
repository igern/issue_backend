import app/pages/login
import app/types.{type Context}
import gleam/http
import wisp

pub fn router(
  req: wisp.Request,
  ctx: Context,
  handle_request: fn() -> wisp.Response,
) {
  case wisp.path_segments(req), req.method {
    ["login"], http.Get -> login.login()
    _, _ -> handle_request()
  }
}
