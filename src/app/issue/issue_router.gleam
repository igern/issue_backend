import app/issue/issue_service
import app/types.{type Context}
import app/user/auth_guards
import gleam/http.{Delete, Get, Patch, Post}
import wisp.{type Request, type Response}

pub fn router(req: Request, ctx: Context, handle_request: fn() -> Response) {
  case wisp.path_segments(req), req.method {
    ["issues"], Post -> {
      use <- auth_guards.jwt(req)
      issue_service.create(req, ctx)
    }
    ["issues"], Get -> {
      use <- auth_guards.jwt(req)
      issue_service.find_all(ctx)
    }
    ["issues", id], Get -> {
      use <- auth_guards.jwt(req)
      issue_service.find_one(id, ctx)
    }
    ["issues", id], Patch -> {
      use <- auth_guards.jwt(req)
      issue_service.update_one(req, id, ctx)
    }
    ["issues", id], Delete -> {
      use <- auth_guards.jwt(req)
      issue_service.delete_one(id, ctx)
    }
    _, _ -> handle_request()
  }
}
