import app/auth/auth_guards
import app/common/response_utils
import app/team/inputs/add_to_team_input
import app/team/inputs/create_team_input
import app/team/outputs/team
import app/team/team_service
import app/types
import gleam/http
import gleam/json
import gleam/list
import wisp

pub fn router(
  req: wisp.Request,
  ctx: types.Context,
  handle_request: fn() -> wisp.Response,
) {
  case wisp.path_segments(req), req.method {
    ["api", "teams"], http.Post -> create_team(req, ctx)
    ["api", "teams", id], http.Get -> find_team(req, id, ctx)
    ["api", "teams", id], http.Delete -> delete_team(req, id, ctx)
    ["api", "teams", id], http.Post -> add_to_team(req, id, ctx)
    ["api", "teams", team_id, "profiles", profile_id], http.Delete ->
      delete_from_team(req, team_id, profile_id, ctx)
    _, _ -> handle_request()
  }
}

fn create_team(req: wisp.Request, ctx: types.Context) {
  use profile <- auth_guards.require_profile(req, ctx)
  use json <- wisp.require_json(req)
  use input <- response_utils.or_decode_error(create_team_input.from_dynamic(
    json,
  ))

  use result <- response_utils.map_service_errors(team_service.create(
    input,
    profile.id,
    ctx,
  ))

  let _ =
    team_service.add_to_team(
      result.id,
      add_to_team_input.AddToTeamInput(profile.id),
      ctx,
    )

  team.to_json(result)
  |> json.to_string_tree
  |> wisp.json_response(201)
}

fn delete_team(req: wisp.Request, id: String, ctx: types.Context) {
  use profile <- auth_guards.require_profile(req, ctx)
  use team <- response_utils.map_service_errors(team_service.find_one(id, ctx))

  case team.owner_id == profile.id {
    True -> {
      use result <- response_utils.map_service_errors(team_service.delete_one(
        id,
        ctx,
      ))

      team.to_json(result)
      |> json.to_string_tree
      |> wisp.json_response(200)
    }
    False -> response_utils.can_not_delete_other_teams_response()
  }
}

fn add_to_team(req: wisp.Request, id: String, ctx: types.Context) {
  use profile <- auth_guards.require_profile(req, ctx)
  use team <- response_utils.map_service_errors(team_service.find_one(id, ctx))

  case team.owner_id == profile.id {
    True -> {
      use json <- wisp.require_json(req)
      use input <- response_utils.or_decode_error(
        add_to_team_input.from_dynamic(json),
      )

      use _ <- response_utils.map_service_errors(team_service.add_to_team(
        id,
        input,
        ctx,
      ))

      json.object([])
      |> json.to_string_tree
      |> wisp.json_response(201)
    }
    False -> response_utils.not_team_owner_response()
  }
}

fn delete_from_team(
  req: wisp.Request,
  team_id: String,
  profile_id: String,
  ctx: types.Context,
) {
  use profile <- auth_guards.require_profile(req, ctx)
  use team <- response_utils.map_service_errors(team_service.find_one(
    team_id,
    ctx,
  ))

  case team.owner_id == profile.id {
    True -> {
      use _ <- response_utils.map_service_errors(team_service.delete_from_team(
        team_id,
        profile_id,
        ctx,
      ))

      json.object([])
      |> json.to_string_tree
      |> wisp.json_response(200)
    }
    False -> response_utils.not_team_owner_response()
  }
}

fn find_team(req: wisp.Request, id: String, ctx: types.Context) {
  use profile <- auth_guards.require_profile(req, ctx)
  use team_profiles <- response_utils.map_service_errors(
    team_service.find_team_profiles_from_team(id, ctx),
  )

  case
    list.find(team_profiles, fn(team_profile) {
      team_profile.profile_id == profile.id
    })
  {
    Ok(_) -> {
      use team <- response_utils.map_service_errors(team_service.find_one(
        id,
        ctx,
      ))
      team.to_json(team) |> json.to_string_tree |> wisp.json_response(200)
    }
    Error(_) -> response_utils.not_member_of_team_response()
  }
}
