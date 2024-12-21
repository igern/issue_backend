import app/auth/auth_guards
import app/common/response_utils
import app/profile/inputs/create_profile_input
import app/profile/outputs/profile
import app/profile/profile_service
import app/types.{type Context}
import gleam/http.{Post}
import gleam/int
import gleam/json
import gleam/list
import wisp.{type Request, type Response}

pub fn router(req: Request, ctx: Context, handle_request: fn() -> Response) {
  case wisp.path_segments(req), req.method {
    ["api", "profiles"], Post -> create_profile(req, ctx)
    ["api", "profiles", id, "profile-picture"], Post ->
      upload_profile_picture(req, ctx, id)
    _, _ -> handle_request()
  }
}

pub fn create_profile(req: Request, ctx: Context) {
  use payload <- auth_guards.require_jwt(req)
  use json <- wisp.require_json(req)
  use input <- response_utils.or_decode_error(create_profile_input.from_dynamic(
    json,
  ))
  let assert Ok(user_id) = int.parse(payload.sub)
  use result <- response_utils.map_service_errors(profile_service.create(
    input,
    user_id,
    ctx,
  ))

  profile.to_json(result)
  |> json.to_string_tree()
  |> wisp.json_response(201)
}

pub fn upload_profile_picture(req: Request, ctx: Context, id: String) {
  use profile <- auth_guards.require_profile(req, ctx)

  use id <- response_utils.or_response(
    int.parse(id),
    response_utils.json_response(400, "invalid id"),
  )

  case profile.id == id {
    False -> response_utils.can_not_update_other_profile_response()
    True -> {
      use formdata <- wisp.require_form(req)
      use file <- response_utils.or_response(
        list.key_find(formdata.files, "file"),
        response_utils.json_response(400, "missing file"),
      )

      use result <- response_utils.map_service_errors(
        profile_service.upload_profile_picture(file.path, id, ctx),
      )

      profile.to_json(result)
      |> json.to_string_tree()
      |> wisp.json_response(201)
    }
  }
}
