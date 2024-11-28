import app/issue/inputs/create_issue_input
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
  use t <- utils.with_context

  use t, authorized_user <- utils.create_next_user_and_login(t)

  use t, input <- utils.next_create_issue_input(t)
  let json = create_issue_input.to_json(input)

  let response =
    router.handle_request(
      testing.post_json(
        "/api/issues",
        [utils.bearer_header(authorized_user.auth_tokens.access_token)],
        json,
      ),
      t.context,
    )
  response.status |> should.equal(201)
  let assert Ok(data) =
    json.decode(testing.string_body(response), issue.decoder())
  data
  |> should.equal(Issue(
    id: 1,
    name: input.name,
    creator_id: authorized_user.user.id,
  ))
}

pub fn find_issues_0_test() {
  use t <- utils.with_context
  use t, authorized_user <- utils.create_next_user_and_login(t)
  let response =
    router.handle_request(
      testing.get("/api/issues", [
        utils.bearer_header(authorized_user.auth_tokens.access_token),
      ]),
      t.context,
    )

  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), dynamic.list(issue.decoder()))
  data |> should.equal([])
}

pub fn find_issues_1_test() {
  use t <- utils.with_context

  use t, authorized_user <- utils.create_next_user_and_login(t)
  use issue <- utils.create_issue(t, authorized_user.auth_tokens.access_token)

  let response =
    router.handle_request(
      testing.get("/api/issues", [
        utils.bearer_header(authorized_user.auth_tokens.access_token),
      ]),
      t.context,
    )

  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), dynamic.list(issue.decoder()))
  data |> should.equal([issue])
}

pub fn find_issues_2_test() {
  use t <- utils.with_context

  use t, authorized_user <- utils.create_next_user_and_login(t)
  use issue1 <- utils.create_issue(t, authorized_user.auth_tokens.access_token)
  use issue2 <- utils.create_issue(t, authorized_user.auth_tokens.access_token)

  let response =
    router.handle_request(
      testing.get("/api/issues", [
        utils.bearer_header(authorized_user.auth_tokens.access_token),
      ]),
      t.context,
    )

  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), dynamic.list(issue.decoder()))
  data |> should.equal([issue1, issue2])
}

pub fn find_one_issue_test() {
  use t <- utils.with_context

  use t, authorized_user <- utils.create_next_user_and_login(t)
  use issue <- utils.create_issue(t, authorized_user.auth_tokens.access_token)

  let response =
    router.handle_request(
      testing.get("/api/issues/" <> int.to_string(issue.id), [
        utils.bearer_header(authorized_user.auth_tokens.access_token),
      ]),
      t.context,
    )

  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), issue.decoder())
  data |> should.equal(issue)
}

pub fn find_one_issue_not_found_test() {
  use t <- utils.with_context
  use t, authorized_user <- utils.create_next_user_and_login(t)
  let response =
    router.handle_request(
      testing.get("/api/issues/" <> "1", [
        utils.bearer_header(authorized_user.auth_tokens.access_token),
      ]),
      t.context,
    )

  response.status |> should.equal(404)
}

pub fn find_one_issue_invalid_id_test() {
  use t <- utils.with_context

  use t, authorized_user <- utils.create_next_user_and_login(t)
  let response =
    router.handle_request(
      testing.get("/api/issues/" <> "Invalid", [
        utils.bearer_header(authorized_user.auth_tokens.access_token),
      ]),
      t.context,
    )

  response.status |> should.equal(400)
}

pub fn update_one_issue_test() {
  use t <- utils.with_context

  use t, authorized_user <- utils.create_next_user_and_login(t)
  use issue <- utils.create_issue(t, authorized_user.auth_tokens.access_token)
  let input = update_issue_input.to_json(UpdateIssueInput(name: "Mikkel"))

  let response =
    router.handle_request(
      testing.patch_json(
        "/api/issues/" <> int.to_string(issue.id),
        [utils.bearer_header(authorized_user.auth_tokens.access_token)],
        input,
      ),
      t.context,
    )

  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), issue.decoder())
  data |> should.equal(Issue(..issue, name: "Mikkel"))
}

pub fn update_one_issue_not_found_test() {
  use t <- utils.with_context

  use t, authorized_user <- utils.create_next_user_and_login(t)
  let input = update_issue_input.to_json(UpdateIssueInput(name: "Mikkel"))

  let response =
    router.handle_request(
      testing.patch_json(
        "/api/issues/" <> "1",
        [utils.bearer_header(authorized_user.auth_tokens.access_token)],
        input,
      ),
      t.context,
    )

  response.status |> should.equal(404)
}

pub fn update_one_issue_invalid_id_test() {
  use t <- utils.with_context

  use t, authorized_user <- utils.create_next_user_and_login(t)
  let input = update_issue_input.to_json(UpdateIssueInput(name: "Mikkel"))

  let response =
    router.handle_request(
      testing.patch_json(
        "/api/issues/" <> "Invalid",
        [utils.bearer_header(authorized_user.auth_tokens.access_token)],
        input,
      ),
      t.context,
    )

  response.status |> should.equal(400)
}

pub fn delete_one_issue_test() {
  use t <- utils.with_context

  use t, authorized_user <- utils.create_next_user_and_login(t)
  use issue <- utils.create_issue(t, authorized_user.auth_tokens.access_token)

  let response =
    router.handle_request(
      testing.delete(
        "/api/issues/" <> int.to_string(issue.id),
        [utils.bearer_header(authorized_user.auth_tokens.access_token)],
        "",
      ),
      t.context,
    )

  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), issue.decoder())
  data |> should.equal(issue)
}

pub fn delete_one_issue_not_found_test() {
  use t <- utils.with_context

  use t, authorized_user <- utils.create_next_user_and_login(t)

  let response =
    router.handle_request(
      testing.delete(
        "/api/issues/" <> "1",
        [utils.bearer_header(authorized_user.auth_tokens.access_token)],
        "",
      ),
      t.context,
    )

  response.status |> should.equal(404)
}

pub fn delete_one_issue_invalid_id_test() {
  use t <- utils.with_context

  use t, authorized_user <- utils.create_next_user_and_login(t)

  let response =
    router.handle_request(
      testing.delete(
        "/api/issues/" <> "Invalid",
        [utils.bearer_header(authorized_user.auth_tokens.access_token)],
        "",
      ),
      t.context,
    )

  response.status |> should.equal(400)
}
