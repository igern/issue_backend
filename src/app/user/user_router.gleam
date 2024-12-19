import app/auth/auth_guards
import app/common/response_utils
import app/types.{type Context}
import app/user/inputs/create_user_input
import app/user/outputs/user
import app/user/user_service
import gleam/http.{Delete, Post}
import gleam/int
import gleam/json
import wisp.{type Request, type Response}

pub fn router(req: Request, ctx: Context, handle_request: fn() -> Response) {
  case wisp.path_segments(req), req.method {
    ["api", "users"], Post -> create_user(req, ctx)
    ["api", "users", id], Delete -> delete_user(req, id, ctx)
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
  |> json.to_string_tree()
  |> wisp.json_response(201)
}

fn delete_user(req: Request, id: String, ctx: Context) {
  use payload <- auth_guards.require_jwt(req)
  let assert Ok(user_id) = int.parse(payload.sub)
  use id <- response_utils.or_response(
    int.parse(id),
    response_utils.json_response(400, "invalid id"),
  )

  case user_id == id {
    False -> response_utils.can_not_delete_other_user_response()
    True -> {
      use result <- response_utils.map_service_errors(user_service.delete_one(
        id,
        ctx,
      ))

      user.to_json(result)
      |> json.to_string_tree()
      |> wisp.json_response(200)
    }
  }
}
