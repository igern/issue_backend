import app/auth/outputs/jwt_payload.{type JwtPayload, JwtPayload}
import app/common/response_utils
import app/directory/directory_service
import app/directory_status/directory_status_service
import app/profile/outputs/profile.{type Profile}
import app/profile/profile_service
import app/team/team_service
import app/types.{type Context}
import gleam/list
import gleam/string
import gwt
import wisp.{type Request, type Response}

pub fn require_jwt(
  req: Request,
  handle_request: fn(JwtPayload) -> Response,
) -> Response {
  use bearer_token <- response_utils.or_response(
    list.key_find(req.headers, "authorization"),
    response_utils.missing_authorization_header_response(),
  )
  use #(_, token) <- response_utils.or_response(
    string.split_once(bearer_token, " "),
    response_utils.invalid_bearer_format_response(),
  )
  use jwt <- response_utils.or_response(
    gwt.from_signed_string(token, "secret"),
    response_utils.invalid_jwt_response(),
  )
  let assert Ok(sub) = gwt.get_subject(jwt)
  let assert Ok(exp) = gwt.get_expiration(jwt)
  handle_request(JwtPayload(sub, exp))
}

pub fn require_profile(
  req: Request,
  ctx: Context,
  handle_request: fn(Profile) -> Response,
) -> Response {
  use payload <- require_jwt(req)
  use profile <- response_utils.or_response(
    profile_service.find_one_from_user_id(payload.sub, ctx),
    response_utils.profile_required_response(),
  )
  handle_request(profile)
}

pub fn require_team_member_from_directory(
  profile_id: String,
  directory_id: String,
  ctx: Context,
  handle_request: fn() -> Response,
) {
  use directory <- response_utils.map_service_errors(directory_service.find_one(
    directory_id,
    ctx,
  ))

  use team_profiles <- response_utils.map_service_errors(
    team_service.find_team_profiles_from_team(directory.team_id, ctx),
  )

  use _ <- response_utils.or_response(
    list.find(team_profiles, fn(team_profile) {
      team_profile.profile_id == profile_id
    }),
    response_utils.not_member_of_team_response(),
  )

  handle_request()
}

pub fn require_team_member_from_directory_status(
  profile_id: String,
  directory_status_id: String,
  ctx: types.Context,
  handle_request: fn() -> Response,
) {
  use directory_status <- response_utils.or_response(
    directory_status_service.find_one(directory_status_id, ctx),
    response_utils.directory_status_not_found_error_response(),
  )
  use <- require_team_member_from_directory(
    profile_id,
    directory_status.directory_id,
    ctx,
  )
  handle_request()
}
