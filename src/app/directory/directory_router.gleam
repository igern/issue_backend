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
    ["api", "teams", team_id, "directories"], http.Post ->
      create_directory(req, team_id, ctx)
    ["api", "teams", team_id, "directories"], http.Get ->
      find_directories(req, team_id, ctx)
    ["api", "directories", id], http.Get -> find_one_directory(req, id, ctx)
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

fn find_one_directory(req: Request, directory_id: String, ctx: Context) {
  use profile <- auth_guards.require_profile(req, ctx)

  use directory <- response_utils.map_service_errors(directory_service.find_one(
    directory_id,
    ctx,
  ))

  use team_profiles <- response_utils.map_service_errors(
    team_service.find_team_profiles_from_team(directory.team_id, ctx),
  )

  use _ <- response_utils.or_response(
    list.find(team_profiles, fn(team_profile) {
      team_profile.profile_id == profile.id
    }),
    response_utils.not_member_of_team_response(),
  )

  directory.to_json(directory)
  |> json.to_string_tree()
  |> wisp.json_response(200)
}

fn find_directories(req: Request, team_id: String, ctx: Context) {
  use profile <- auth_guards.require_profile(req, ctx)

  use team_profiles <- response_utils.map_service_errors(
    team_service.find_team_profiles_from_team(team_id, ctx),
  )

  use _ <- response_utils.or_response(
    list.find(team_profiles, fn(team_profile) {
      team_profile.profile_id == profile.id
    }),
    response_utils.not_member_of_team_response(),
  )

  use directories <- response_utils.map_service_errors(
    directory_service.find_from_team(team_id, ctx),
  )

  json.array(directories, directory.to_json)
  |> json.to_string_tree
  |> wisp.json_response(200)
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

  use _ <- response_utils.or_response(
    list.find(team_profiles, fn(team_profile) {
      team_profile.profile_id == profile.id
    }),
    response_utils.not_member_of_team_response(),
  )

  use json <- wisp.require_json(req)
  use input <- response_utils.or_decode_error(
    update_directory_input.from_dynamic(json),
  )

  use result <- response_utils.map_service_errors(directory_service.update_one(
    directory_id,
    input,
    ctx,
  ))

  directory.to_json(result)
  |> json.to_string_tree()
  |> wisp.json_response(200)
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

  use _ <- response_utils.or_response(
    list.find(team_profiles, fn(team_profile) {
      team_profile.profile_id == profile.id
    }),
    response_utils.not_member_of_team_response(),
  )

  use result <- response_utils.map_service_errors(directory_service.delete_one(
    directory_id,
    ctx,
  ))

  directory.to_json(result)
  |> json.to_string_tree()
  |> wisp.json_response(200)
}
