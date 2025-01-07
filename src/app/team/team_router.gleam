import app/auth/auth_guards
import app/common/response_utils
import app/team/inputs/create_team_input
import app/team/outputs/team
import app/team/team_service
import app/types
import gleam/http
import gleam/json
import wisp

pub fn router(
  req: wisp.Request,
  ctx: types.Context,
  handle_request: fn() -> wisp.Response,
) {
  case wisp.path_segments(req), req.method {
    ["api", "teams"], http.Post -> create_team(req, ctx)
    ["api", "teams", id], http.Delete -> delete_team(req, id, ctx)
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
