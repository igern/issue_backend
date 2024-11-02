import app/auth/auth_guards
import app/common/response_utils
import app/issue/inputs/create_issue_input
import app/issue/inputs/update_issue_input
import app/issue/issue_service
import app/issue/outputs/issue
import app/types.{type Context}
import gleam/http.{Delete, Get, Patch, Post}
import gleam/int
import gleam/json
import wisp.{type Request, type Response}

pub fn router(req: Request, ctx: Context, handle_request: fn() -> Response) {
  case wisp.path_segments(req), req.method {
    ["issues"], Post -> create_issue(req, ctx)
    ["issues"], Get -> find_issues(req, ctx)
    ["issues", id], Get -> find_issue(req, id, ctx)
    ["issues", id], Patch -> update_issue(req, id, ctx)
    ["issues", id], Delete -> delete_issue(req, id, ctx)
    _, _ -> handle_request()
  }
}

fn create_issue(req: Request, ctx: Context) {
  use <- auth_guards.jwt(req)
  use json <- wisp.require_json(req)
  use input <- response_utils.or_decode_error(create_issue_input.from_dynamic(
    json,
  ))

  use result <- response_utils.map_service_errors(issue_service.create(
    input,
    ctx,
  ))

  issue.to_json(result)
  |> json.to_string_builder()
  |> wisp.json_response(201)
}

fn find_issues(req: Request, ctx: Context) {
  use <- auth_guards.jwt(req)

  use result <- response_utils.map_service_errors(issue_service.find_all(ctx))

  json.array(result, issue.to_json)
  |> json.to_string_builder()
  |> wisp.json_response(200)
}

fn find_issue(req: Request, id: String, ctx: Context) {
  use <- auth_guards.jwt(req)
  use id <- response_utils.or_400(int.parse(id))

  use result <- response_utils.map_service_errors(issue_service.find_one(
    id,
    ctx,
  ))

  issue.to_json(result)
  |> json.to_string_builder()
  |> wisp.json_response(200)
}

fn update_issue(req: Request, id: String, ctx: Context) {
  use <- auth_guards.jwt(req)
  use id <- response_utils.or_400(int.parse(id))
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
  |> json.to_string_builder()
  |> wisp.json_response(200)
}

fn delete_issue(req: Request, id: String, ctx: Context) {
  use <- auth_guards.jwt(req)
  use id <- response_utils.or_400(int.parse(id))

  use result <- response_utils.map_service_errors(issue_service.delete_one(
    id,
    ctx,
  ))

  issue.to_json(result)
  |> json.to_string_builder()
  |> wisp.json_response(200)
}
