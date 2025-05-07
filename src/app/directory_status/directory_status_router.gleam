import app/auth/auth_guards
import app/common/response_utils
import app/common/valid
import app/directory/inputs/create_directory_input
import app/directory_status/directory_status_service
import app/directory_status/outputs/directory_status
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
    ["api", "directories", directory_id, "statuses"], http.Post ->
      create_directory_status(req, directory_id, ctx)
    ["api", "directory-statuses", directory_status_id], http.Delete ->
      delete_directory_status(req, directory_status_id, ctx)
    _, _ -> handle_request()
  }
}

fn create_directory_status(
  req: Request,
  directory_id: String,
  ctx: types.Context,
) {
  use profile <- auth_guards.require_profile(req, ctx)
  use <- auth_guards.require_team_member_from_directory(
    profile.id,
    directory_id,
    ctx,
  )

  use json <- wisp.require_json(req)
  use input <- response_utils.or_decode_error(
    create_directory_input.from_dynamic(json),
  )

  use input <- valid.or_bad_request_response(create_directory_input.validate(
    input,
  ))
  use result <- response_utils.map_service_errors(
    directory_status_service.create(directory_id, input, ctx),
  )

  directory_status.to_json(result)
  |> json.to_string_tree()
  |> wisp.json_response(201)
}

fn delete_directory_status(
  req: Request,
  directory_status_id: String,
  ctx: types.Context,
) {
  use profile <- auth_guards.require_profile(req, ctx)
  use directory_status <- response_utils.map_service_errors(
    directory_status_service.find_one(directory_status_id, ctx),
  )
  use <- auth_guards.require_team_member_from_directory(
    profile.id,
    directory_status.directory_id,
    ctx,
  )
  use result <- response_utils.map_service_errors(
    directory_status_service.delete_one(directory_status_id, ctx),
  )

  directory_status.to_json(result)
  |> json.to_string_tree()
  |> wisp.json_response(200)
}
