import app/auth/auth_guards
import app/common/response_utils
import app/directory/directory_service
import app/directory/inputs/create_directory_input
import app/directory/inputs/update_directory_input
import app/directory/outputs/directory
import app/types.{type Context}
import gleam/http
import gleam/json
import wisp.{type Request, type Response}

pub fn router(req: Request, ctx: Context, handle_request: fn() -> Response) {
  case wisp.path_segments(req), req.method {
    ["api", "directories"], http.Post -> create_directory(req, ctx)
    ["api", "directories", id], http.Patch -> update_directory(req, id, ctx)
    ["api", "directories", id], http.Delete -> delete_directory(req, id, ctx)

    _, _ -> handle_request()
  }
}

fn create_directory(req: Request, ctx: Context) {
  use _ <- auth_guards.require_profile(req, ctx)
  use json <- wisp.require_json(req)
  use input <- response_utils.or_decode_error(
    create_directory_input.from_dynamic(json),
  )
  use result <- response_utils.map_service_errors(directory_service.create(
    input,
    ctx,
  ))

  directory.to_json(result) |> json.to_string_tree() |> wisp.json_response(201)
}

fn delete_directory(req: Request, id: String, ctx: Context) {
  use _ <- auth_guards.require_profile(req, ctx)
  use result <- response_utils.map_service_errors(directory_service.delete_one(
    id,
    ctx,
  ))

  directory.to_json(result) |> json.to_string_tree() |> wisp.json_response(200)
}

fn update_directory(req: Request, id: String, ctx: Context) {
  use _ <- auth_guards.require_profile(req, ctx)
  use json <- wisp.require_json(req)
  use input <- response_utils.or_decode_error(
    update_directory_input.from_dynamic(json),
  )

  use result <- response_utils.map_service_errors(directory_service.update_one(
    id,
    input,
    ctx,
  ))

  directory.to_json(result) |> json.to_string_tree() |> wisp.json_response(200)
}
