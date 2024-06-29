import app/issue/issue_service
import app/types.{type Context}
import gleam/http.{Delete, Get, Patch, Post}
import wisp.{type Request, type Response}

pub fn router(req: Request, ctx: Context, handle_request: fn() -> Response) {
  case wisp.path_segments(req), req.method {
    ["issues"], Post -> issue_service.create(req, ctx)
    ["issues"], Get -> issue_service.find_all(ctx)
    ["issues", id], Get -> issue_service.find_one(id, ctx)
    ["issues", id], Patch -> issue_service.update_one(req, id, ctx)
    ["issues", id], Delete -> issue_service.delete_one(id, ctx)
    _, _ -> handle_request()
  }
}
