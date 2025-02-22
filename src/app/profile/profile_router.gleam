import app/auth/auth_guards
import app/common/response_utils
import app/common/valid
import app/profile/inputs/create_profile_input
import app/profile/outputs/profile
import app/profile/pages/create_profile_page
import app/profile/profile_service
import app/types.{type Context}
import gleam/bit_array
import gleam/bool
import gleam/http.{Post}
import gleam/json
import gleam/list
import gleam/option
import simplifile
import wisp.{type Request, type Response}

pub fn router(req: Request, ctx: Context, handle_request: fn() -> Response) {
  case wisp.path_segments(req), req.method {
    ["create-profile"], http.Get ->
      create_profile_page.create_profile_page(option.None, False)
    ["create-profile"], http.Post -> create_profile(req, ctx)
    ["api", "profiles"], Post -> post_api_profiles(req, ctx)
    ["api", "profiles", id, "profile-picture"], Post ->
      upload_profile_picture(req, ctx, id)
    _, _ -> handle_request()
  }
}

pub fn create_profile(req: wisp.Request, ctx: Context) {
  use payload <- auth_guards.require_jwt(req)
  use json <- wisp.require_json(req)
  use input <- response_utils.or_decode_error(create_profile_input.from_dynamic(
    json,
  ))

  let input = create_profile_input.validate(input)

  case input {
    Ok(input) -> {
      case profile_service.create(input, payload.sub, ctx) {
        Ok(profile) -> wisp.redirect("/teams")
        _ -> panic as "Unknown"
      }
    }
    Error(invalid) ->
      create_profile_page.create_profile_page(
        option.Some(valid.errors(invalid)),
        True,
      )
  }
}

pub fn post_api_profiles(req: Request, ctx: Context) {
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
