import app/auth/auth_router
import app/issue/issue_router
import app/types.{type Context}
import app/user/user_router
import gleam/http.{Get, Post}
import gleam/json
import lustre/attribute
import lustre/element
import lustre/element/html
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- middleware(req)
  use <- issue_router.router(req, ctx)
  use <- user_router.router(req, ctx)
  use <- auth_router.router(req, ctx)

  case wisp.path_segments(req), req.method {
    [], Get -> login_page()
    ["auth", "login"], Post -> login(req, ctx)
    ["api"], Get -> {
      json.object([#("version", json.string("1.0.0"))])
      |> json.to_string_builder()
      |> wisp.json_response(200)
    }
    _, _ ->
      json.object([
        #("code", json.int(404)),
        #("message", json.string("not found")),
      ])
      |> json.to_string_builder()
      |> wisp.json_response(404)
  }
}

pub fn middleware(
  req: Request,
  handle_request: fn(Request) -> Response,
) -> Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  handle_request(req)
}

fn login(req: Request, ctx: Context) {
  todo
}

fn login_page() -> Response {
  html.html([], [
    html.header([], [
      html.script([attribute.src("https://unpkg.com/htmx.org@2.0.3")], ""),
    ]),
    html.form([attribute.attribute("hx-post", "api/auth/login")], [
      html.input([attribute.name("email")]),
      html.input([attribute.name("password")]),
      html.button([], [html.text("Login now")]),
    ]),
  ])
  |> element.to_string_builder
  |> wisp.html_response(200)
}
