import app/auth/auth_router
import app/directory/directory_router
import app/issue/issue_router
import app/profile/profile_router
import app/team/team_router
import app/types.{type Context}
import app/user/user_router
import cors_builder
import gleam/http.{Get}
import gleam/json
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- middleware(req)
  use <- issue_router.router(req, ctx)
  use <- user_router.router(req, ctx)
  use <- auth_router.router(req, ctx)
  use <- profile_router.router(req, ctx)
  use <- directory_router.router(req, ctx)
  use <- team_router.router(req, ctx)

  case wisp.path_segments(req), req.method {
    [], Get -> wisp.redirect("/login")
    ["api"], Get -> {
      json.object([#("version", json.string("1.0.0"))])
      |> json.to_string_tree()
      |> wisp.json_response(200)
    }
    _, _ ->
      json.object([
        #("code", json.int(404)),
        #("message", json.string("not found")),
      ])
      |> json.to_string_tree()
      |> wisp.json_response(404)
  }
}

fn cors() {
  cors_builder.new()
  |> cors_builder.allow_origin("*")
  |> cors_builder.allow_method(http.Post)
  |> cors_builder.allow_header("content-type")
  |> cors_builder.allow_header("authorization")
}

pub fn middleware(
  req: Request,
  handle_request: fn(Request) -> Response,
) -> Response {
  let req = wisp.method_override(req)
  use req <- cors_builder.wisp_middleware(req, cors())
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.serve_static(req, "/static", "src/public")

  handle_request(req)
}
