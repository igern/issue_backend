import app/auth/auth_guards
import app/common/response_utils
import app/directory_status_type/directory_status_type_service
import app/directory_status_type/outputs/directory_status_type
import app/types
import gleam/http
import gleam/json
import wisp.{type Request, type Response}

pub fn router(
  req: Request,
  ctx: types.Context,
  handle_request: fn() -> Response,
) {
  case wisp.path_segments(req), req.method {
    ["api", "directory_status_types"], http.Get ->
      find_all_directory_status_types(req, ctx)
    _, _ -> handle_request()
  }
}

fn find_all_directory_status_types(req: Request, ctx: types.Context) {
  use _ <- auth_guards.require_jwt(req)

  use result <- response_utils.map_service_errors(
    directory_status_type_service.find_all(ctx),
  )

  json.array(result, directory_status_type.to_json)
  |> json.to_string_tree
  |> wisp.json_response(200)
}
