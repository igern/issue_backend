import app/auth/auth_guards
import app/common/response_utils
import app/common/valid
import app/profile/inputs/create_profile_input
import app/profile/outputs/profile
import app/profile/profile_service
import app/types.{type Context}
import gleam/bit_array
import gleam/bool
import gleam/http.{Get, Post}
import gleam/json
import gleam/list
import simplifile
import wisp.{type Request, type Response}

pub fn router(req: Request, ctx: Context, handle_request: fn() -> Response) {
  case wisp.path_segments(req), req.method {
    ["api", "profiles"], Post -> create_profile(req, ctx)
    ["api", "profiles", "current"], Get -> find_one_current(req, ctx)
    ["api", "profiles", id], Get -> find_one(req, ctx, id)
    ["api", "profiles", id, "profile-picture"], Post ->
      upload_profile_picture(req, ctx, id)
    _, _ -> handle_request()
  }
}

pub fn find_one_current(req: Request, ctx: Context) {
  use profile <- auth_guards.require_profile(req, ctx)

  use result <- response_utils.map_service_errors(
    profile_service.find_one_from_id(profile.id, ctx),
  )

  profile.to_json(result)
  |> json.to_string_tree()
  |> wisp.json_response(200)
}

pub fn find_one(req: Request, ctx: Context, profile_id: String) {
  use profile <- auth_guards.require_profile(req, ctx)
  use <- bool.guard(
    profile_id != profile.id,
    response_utils.json_response(400, "forbidden"),
  )

  use result <- response_utils.map_service_errors(
    profile_service.find_one_from_id(profile_id, ctx),
  )

  profile.to_json(result)
  |> json.to_string_tree()
  |> wisp.json_response(200)
}

pub fn create_profile(req: Request, ctx: Context) {
  use payload <- auth_guards.require_jwt(req)
  use json <- wisp.require_json(req)
  use input <- response_utils.or_decode_error(create_profile_input.from_dynamic(
    json,
  ))

  use input <- valid.or_bad_request_response(create_profile_input.validate(
    input,
  ))

  use result <- response_utils.map_service_errors(profile_service.create(
    input,
    payload.sub,
    ctx,
  ))

  profile.to_json(result)
  |> json.to_string_tree()
  |> wisp.json_response(201)
}

pub fn upload_profile_picture(req: Request, ctx: Context, id: String) {
  use profile <- auth_guards.require_profile(req, ctx)

  case profile.id == id {
    False -> response_utils.can_not_update_other_profile_response()
    True -> {
      use formdata <- wisp.require_form(req)
      use file <- response_utils.or_response(
        list.key_find(formdata.files, "file"),
        response_utils.json_response(400, "missing file"),
      )
      use file_bits <- response_utils.or_response(
        simplifile.read_bits(file.path),
        response_utils.file_read_error_response(),
      )
      use <- bool.guard(
        bit_array.starts_with(file_bits, <<255, 216, 255>>) |> bool.negate,
        response_utils.json_response(400, "invalid file type"),
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
