import app/issue/inputs/create_issue_input.{CreateIssueInput}
import app/issue/inputs/update_issue_input.{UpdateIssueInput}
import app/issue/outputs/issue.{Issue}
import app/router
import gleam/dynamic
import gleam/int
import gleam/json
import gleeunit/should
import utils
import wisp/testing

pub fn create_issue_test() {
  use ctx <- utils.with_context

  let authorized_user = utils.create_user_and_login(ctx)

  let input = create_issue_input.to_json(CreateIssueInput(name: "Jonas"))

  let response =
    router.handle_request(
      testing.post_json(
        "/issues",
        [utils.bearer_header(authorized_user.auth_tokens.access_token)],
        input,
      ),
      ctx,
    )

  response.status |> should.equal(201)
  let assert Ok(data) =
    json.decode(testing.string_body(response), issue.decoder())
  data |> should.equal(Issue(id: 1, name: "Jonas"))
}

pub fn find_issues_0_test() {
  use ctx <- utils.with_context
  let authorized_user = utils.create_user_and_login(ctx)
  let response =
    router.handle_request(
      testing.get("/issues", [
        utils.bearer_header(authorized_user.auth_tokens.access_token),
      ]),
      ctx,
    )

  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), dynamic.list(issue.decoder()))
  data |> should.equal([])
}

pub fn find_issues_1_test() {
  use ctx <- utils.with_context

  let authorized_user = utils.create_user_and_login(ctx)
  let issue = utils.create_issue(ctx, authorized_user.auth_tokens.access_token)

  let response =
    router.handle_request(
      testing.get("/issues", [
        utils.bearer_header(authorized_user.auth_tokens.access_token),
      ]),
      ctx,
    )

  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), dynamic.list(issue.decoder()))
  data |> should.equal([issue])
}

pub fn find_issues_2_test() {
  use ctx <- utils.with_context

  let authorized_user = utils.create_user_and_login(ctx)
  let issue1 = utils.create_issue(ctx, authorized_user.auth_tokens.access_token)
  let issue2 = utils.create_issue(ctx, authorized_user.auth_tokens.access_token)

  let response =
    router.handle_request(
      testing.get("/issues", [
        utils.bearer_header(authorized_user.auth_tokens.access_token),
      ]),
      ctx,
    )

  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), dynamic.list(issue.decoder()))
  data |> should.equal([issue1, issue2])
}

pub fn find_one_issue_test() {
  use ctx <- utils.with_context

  let authorized_user = utils.create_user_and_login(ctx)
  let issue = utils.create_issue(ctx, authorized_user.auth_tokens.access_token)

  let response =
    router.handle_request(
      testing.get("issues/" <> int.to_string(issue.id), [
        utils.bearer_header(authorized_user.auth_tokens.access_token),
      ]),
      ctx,
    )

  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), issue.decoder())
  data |> should.equal(issue)
}

pub fn find_one_issue_not_found_test() {
  use ctx <- utils.with_context
  let authorized_user = utils.create_user_and_login(ctx)
  let response =
    router.handle_request(
      testing.get("issues/" <> "1", [
        utils.bearer_header(authorized_user.auth_tokens.access_token),
      ]),
      ctx,
    )

  response.status |> should.equal(404)
}

pub fn find_one_issue_invalid_id_test() {
  use ctx <- utils.with_context

  let authorized_user = utils.create_user_and_login(ctx)
  let response =
    router.handle_request(
      testing.get("issues/" <> "Invalid", [
        utils.bearer_header(authorized_user.auth_tokens.access_token),
      ]),
      ctx,
    )

  response.status |> should.equal(400)
}

pub fn update_one_issue_test() {
  use ctx <- utils.with_context

  let authorized_user = utils.create_user_and_login(ctx)
  let issue = utils.create_issue(ctx, authorized_user.auth_tokens.access_token)
  let input = update_issue_input.to_json(UpdateIssueInput(name: "Mikkel"))

  let response =
    router.handle_request(
      testing.patch_json(
        "issues/" <> int.to_string(issue.id),
        [utils.bearer_header(authorized_user.auth_tokens.access_token)],
        input,
      ),
      ctx,
    )

  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), issue.decoder())
  data |> should.equal(Issue(..issue, name: "Mikkel"))
}

pub fn update_one_issue_not_found_test() {
  use ctx <- utils.with_context

  let authorized_user = utils.create_user_and_login(ctx)
  let input = update_issue_input.to_json(UpdateIssueInput(name: "Mikkel"))

  let response =
    router.handle_request(
      testing.patch_json(
        "issues/" <> "1",
        [utils.bearer_header(authorized_user.auth_tokens.access_token)],
        input,
      ),
      ctx,
    )

  response.status |> should.equal(404)
}

pub fn update_one_issue_invalid_id_test() {
  use ctx <- utils.with_context

  let authorized_user = utils.create_user_and_login(ctx)
  let input = update_issue_input.to_json(UpdateIssueInput(name: "Mikkel"))

  let response =
    router.handle_request(
      testing.patch_json(
        "issues/" <> "Invalid",
        [utils.bearer_header(authorized_user.auth_tokens.access_token)],
        input,
      ),
      ctx,
    )

  response.status |> should.equal(400)
}

pub fn delete_one_issue_test() {
  use ctx <- utils.with_context

  let authorized_user = utils.create_user_and_login(ctx)
  let issue = utils.create_issue(ctx, authorized_user.auth_tokens.access_token)

  let response =
    router.handle_request(
      testing.delete(
        "issues/" <> int.to_string(issue.id),
        [utils.bearer_header(authorized_user.auth_tokens.access_token)],
        "",
      ),
      ctx,
    )

  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), issue.decoder())
  data |> should.equal(issue)
}

pub fn delete_one_issue_not_found_test() {
  use ctx <- utils.with_context

  let authorized_user = utils.create_user_and_login(ctx)

  let response =
    router.handle_request(
      testing.delete(
        "issues/" <> "1",
        [utils.bearer_header(authorized_user.auth_tokens.access_token)],
        "",
      ),
      ctx,
    )

  response.status |> should.equal(404)
}

pub fn delete_one_issue_invalid_id_test() {
  use ctx <- utils.with_context

  let authorized_user = utils.create_user_and_login(ctx)

  let response =
    router.handle_request(
      testing.delete(
        "issues/" <> "Invalid",
        [utils.bearer_header(authorized_user.auth_tokens.access_token)],
        "",
      ),
      ctx,
    )

  response.status |> should.equal(400)
}
