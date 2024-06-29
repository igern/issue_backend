import app/types.{type Context}
import app/user/user_service
import gleam/http.{Post}
import wisp.{type Request, type Response}

pub fn router(req: Request, ctx: Context, handle_request: fn() -> Response) {
  case wisp.path_segments(req), req.method {
    ["users"], Post -> user_service.create(req, ctx)
    _, _ -> handle_request()
  }
}
