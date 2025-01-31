import app/auth/auth_guards
import app/common/inputs/pagination_input.{PaginationInput}
import app/common/response_utils
import app/directory/directory_service
import app/issue/inputs/create_issue_input
import app/issue/inputs/update_issue_input
import app/issue/issue_service
import app/issue/outputs/issue.{type Issue}
import app/issue/outputs/paginated_issues
import app/team/team_service
import app/types.{type Context}
import gleam/http.{Delete, Get, Patch, Post}
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/uri
import wisp.{type Request, type Response}

pub fn router(req: Request, ctx: Context, handle_request: fn() -> Response) {
  case wisp.path_segments(req), req.method {
    ["api", "directories", directory_id, "issues"], Post ->
      create_issue(req, directory_id, ctx)
    ["api", "directories", directory_id, "issues"], Get ->
      find_issues(req, directory_id, ctx)
    ["api", "issues", id], Get -> find_issue(req, id, ctx)
    ["api", "issues", id], Patch -> update_issue(req, id, ctx)
    ["api", "issues", id], Delete -> delete_issue(req, id, ctx)
    _, _ -> handle_request()
  }
}

fn require_team_member_from_directory(
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

fn require_team_member_from_issue(
  profile_id: String,
  issue_id: String,
  ctx: Context,
  handle_request: fn(Issue) -> Response,
) {
  use issue <- response_utils.map_service_errors(issue_service.find_one(
    issue_id,
    ctx,
  ))

  use directory <- response_utils.map_service_errors(directory_service.find_one(
    issue.directory_id,
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

  handle_request(issue)
}

fn create_issue(req: Request, directory_id: String, ctx: Context) {
  use profile <- auth_guards.require_profile(req, ctx)
  use <- require_team_member_from_directory(profile.id, directory_id, ctx)

  use json <- wisp.require_json(req)
  use input <- response_utils.or_decode_error(create_issue_input.from_dynamic(
    json,
  ))
  use result <- response_utils.map_service_errors(issue_service.create(
    directory_id,
    profile.id,
    input,
    ctx,
  ))

  issue.to_json(result)
  |> json.to_string_tree()
  |> wisp.json_response(201)
}

fn parse_pagination_input(query: option.Option(String)) {
  use query <- result.try(option.to_result(query, Nil))
  use params <- result.try(uri.parse_query(query))
  use skip <- result.try(list.find(params, fn(param) { param.0 == "skip" }))
  use skip <- result.try(int.parse(skip.1))
  use take <- result.try(list.find(params, fn(param) { param.0 == "take" }))
  use take <- result.try(int.parse(take.1))
  Ok(PaginationInput(skip, take))
}

fn find_issues(req: Request, directory_id: String, ctx: Context) {
  use profile <- auth_guards.require_profile(req, ctx)
  use <- require_team_member_from_directory(profile.id, directory_id, ctx)

  use input <- response_utils.or_response(
    parse_pagination_input(req.query),
    response_utils.json_response(400, "invalid pagination input"),
  )

  use result <- response_utils.map_service_errors(issue_service.find_paginated(
    input,
    ctx,
  ))

  result
  |> paginated_issues.to_json
  |> json.to_string_tree()
  |> wisp.json_response(200)
}

fn find_issue(req: Request, id: String, ctx: Context) {
  use profile <- auth_guards.require_profile(req, ctx)
  use issue <- require_team_member_from_issue(profile.id, id, ctx)

  issue.to_json(issue)
  |> json.to_string_tree()
  |> wisp.json_response(200)
}

fn update_issue(req: Request, id: String, ctx: Context) {
  use profile <- auth_guards.require_profile(req, ctx)
  use _ <- require_team_member_from_issue(profile.id, id, ctx)
  use json <- wisp.require_json(req)
  use input <- response_utils.or_decode_error(update_issue_input.from_dynamic(
    json,
  ))

  use result <- response_utils.map_service_errors(issue_service.update_one(
    id,
    input,
    ctx,
  ))

  issue.to_json(result)
  |> json.to_string_tree()
  |> wisp.json_response(200)
}

fn delete_issue(req: Request, id: String, ctx: Context) {
  use profile <- auth_guards.require_profile(req, ctx)
  use _ <- require_team_member_from_issue(profile.id, id, ctx)

  use result <- response_utils.map_service_errors(issue_service.delete_one(
    id,
    ctx,
  ))

  issue.to_json(result)
  |> json.to_string_tree()
  |> wisp.json_response(200)
}
