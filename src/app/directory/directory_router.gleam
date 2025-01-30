import app/auth/auth_guards
import app/common/response_utils
import app/directory/directory_service
import app/directory/inputs/create_directory_input
import app/directory/inputs/update_directory_input
import app/directory/outputs/directory
import app/team/team_service
import app/types.{type Context}
import gleam/http
import gleam/json
import gleam/list
import wisp.{type Request, type Response}

pub fn router(req: Request, ctx: Context, handle_request: fn() -> Response) {
  case wisp.path_segments(req), req.method {
    ["api", "teams", id, "directories"], http.Post ->
      create_directory(req, id, ctx)
    ["api", "directories", id], http.Patch -> update_directory(req, id, ctx)
    ["api", "directories", id], http.Delete -> delete_directory(req, id, ctx)
    _, _ -> handle_request()
  }
}

fn create_directory(req: Request, team_id: String, ctx: Context) {
  use profile <- auth_guards.require_profile(req, ctx)

  use team_profiles <- response_utils.map_service_errors(
    team_service.find_team_profiles_from_team(team_id, ctx),
  )

  case
    list.find(team_profiles, fn(team_profile) {
      team_profile.profile_id == profile.id
    })
  {
    Ok(_) -> {
      use json <- wisp.require_json(req)
      use input <- response_utils.or_decode_error(
        create_directory_input.from_dynamic(json),
      )
      use result <- response_utils.map_service_errors(directory_service.create(
        team_id,
        input,
        ctx,
      ))

      directory.to_json(result)
      |> json.to_string_tree()
      |> wisp.json_response(201)
    }
    Error(_) -> response_utils.not_member_of_team_response()
  }
}

fn update_directory(req: Request, directory_id: String, ctx: Context) {
  use profile <- auth_guards.require_profile(req, ctx)

  use directory <- response_utils.map_service_errors(directory_service.find_one(
    directory_id,
    ctx,
  ))

  use team_profiles <- response_utils.map_service_errors(
    team_service.find_team_profiles_from_team(directory.team_id, ctx),
  )

  case
    list.find(team_profiles, fn(team_profile) {
      team_profile.profile_id == profile.id
    })
  {
    Ok(_) -> {
      use json <- wisp.require_json(req)
      use input <- response_utils.or_decode_error(
        update_directory_input.from_dynamic(json),
      )

      use result <- response_utils.map_service_errors(
        directory_service.update_one(directory_id, input, ctx),
      )

      directory.to_json(result)
      |> json.to_string_tree()
      |> wisp.json_response(200)
    }
    Error(_) -> response_utils.not_member_of_team_response()
  }
}

fn delete_directory(req: Request, directory_id: String, ctx: Context) {
  use profile <- auth_guards.require_profile(req, ctx)

  use directory <- response_utils.map_service_errors(directory_service.find_one(
    directory_id,
    ctx,
  ))

  use team_profiles <- response_utils.map_service_errors(
    team_service.find_team_profiles_from_team(directory.team_id, ctx),
  )

  case
    list.find(team_profiles, fn(team_profile) {
      team_profile.profile_id == profile.id
    })
  {
    Ok(_) -> {
      use result <- response_utils.map_service_errors(
        directory_service.delete_one(directory_id, ctx),
      )

      directory.to_json(result)
      |> json.to_string_tree()
      |> wisp.json_response(200)
    }
    Error(_) -> response_utils.not_member_of_team_response()
  }
}
