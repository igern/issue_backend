import app/common/response_utils
import app/issue/inputs/create_issue_input
import app/issue/inputs/update_issue_input.{UpdateIssueInput}
import app/issue/outputs/issue.{Issue}
import app/issue/outputs/paginated_issues
import app/router
import gleam/http
import gleam/json
import gleam/option
import gleeunit/should
import utils
import wisp/testing

pub fn create_issue_test() {
  use t <- utils.with_context

  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)

  use t, directory <- utils.next_create_directory(
    t,
    authorized_profile.auth_tokens.access_token,
  )

  use t, input <- utils.next_create_issue_input(t, directory.id)
  let json = create_issue_input.to_json(input)

  let response =
    router.handle_request(
      testing.post_json(
        "/api/issues",
        [utils.bearer_header(authorized_profile.auth_tokens.access_token)],
        json,
      ),
      t.context,
    )
  response.status |> should.equal(201)
  let assert Ok(data) =
    json.decode(testing.string_body(response), issue.decoder())
  data
  |> should.equal(Issue(
    id: data.id,
    name: input.name,
    description: input.description,
    creator_id: authorized_profile.profile.id,
    directory_id: input.directory_id,
  ))
}

pub fn create_issue_null_description_test() {
  use t <- utils.with_context

  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)

  use t, directory <- utils.next_create_directory(
    t,
    authorized_profile.auth_tokens.access_token,
  )

  use t, input <- utils.next_create_issue_input(t, directory.id)
  let input =
    create_issue_input.CreateIssueInput(..input, description: option.None)
  let json = create_issue_input.to_json(input)

  let response =
    router.handle_request(
      testing.post_json(
        "/api/issues",
        [utils.bearer_header(authorized_profile.auth_tokens.access_token)],
        json,
      ),
      t.context,
    )
  response.status |> should.equal(201)
  let assert Ok(data) =
    json.decode(testing.string_body(response), issue.decoder())
  data
  |> should.equal(Issue(
    id: data.id,
    name: input.name,
    description: input.description,
    creator_id: authorized_profile.profile.id,
    directory_id: input.directory_id,
  ))
}

pub fn create_issue_invalid_directory_id_test() {
  use t <- utils.with_context
  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)

  use t, input <- utils.next_create_issue_input(t, utils.mock_uuidv4)
  let json = create_issue_input.to_json(input)

  let response =
    router.handle_request(
      testing.post_json(
        "/api/issues",
        [utils.bearer_header(authorized_profile.auth_tokens.access_token)],
        json,
      ),
      t.context,
    )
  response
  |> utils.response_equal(response_utils.directory_not_found_error_response())
}

pub fn create_issue_missing_authorization_header_test() {
  utils.missing_authorization_header_tester(http.Post, "/api/issues")
}

pub fn create_issue_invalid_bearer_format_test() {
  utils.invalid_bearer_format_tester(http.Post, "/api/issues")
}

pub fn create_issue_invalid_jwt_test() {
  utils.invalid_jwt_tester(http.Post, "/api/issues")
}

pub fn create_issue_profile_required_test() {
  utils.profile_required_tester(http.Post, "/api/issues")
}

pub fn find_issues_0_test() {
  use t <- utils.with_context
  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)

  let response =
    router.handle_request(
      testing.get("/api/issues?skip=0&take=10", [
        utils.bearer_header(authorized_profile.auth_tokens.access_token),
      ]),
      t.context,
    )

  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), paginated_issues.decoder())
  data |> should.equal(paginated_issues.PaginatedIssues(0, False, []))
}

pub fn find_issues_1_test() {
  use t <- utils.with_context

  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)
  use t, directory <- utils.next_create_directory(
    t,
    authorized_profile.auth_tokens.access_token,
  )
  use t, issue <- utils.next_create_issue(
    t,
    authorized_profile.auth_tokens.access_token,
    directory.id,
  )

  let response =
    router.handle_request(
      testing.get("/api/issues?skip=0&take=10", [
        utils.bearer_header(authorized_profile.auth_tokens.access_token),
      ]),
      t.context,
    )

  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), paginated_issues.decoder())
  data |> should.equal(paginated_issues.PaginatedIssues(1, False, [issue]))
}

pub fn find_issues_2_test() {
  use t <- utils.with_context

  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)
  use t, directory <- utils.next_create_directory(
    t,
    authorized_profile.auth_tokens.access_token,
  )
  use t, issue1 <- utils.next_create_issue(
    t,
    authorized_profile.auth_tokens.access_token,
    directory.id,
  )
  use t, issue2 <- utils.next_create_issue(
    t,
    authorized_profile.auth_tokens.access_token,
    directory.id,
  )

  let response =
    router.handle_request(
      testing.get("/api/issues?skip=0&take=10", [
        utils.bearer_header(authorized_profile.auth_tokens.access_token),
      ]),
      t.context,
    )

  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), paginated_issues.decoder())
  data
  |> should.equal(paginated_issues.PaginatedIssues(2, False, [issue1, issue2]))
}

pub fn find_issues_3_test() {
  use t <- utils.with_context

  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)
  use t, directory <- utils.next_create_directory(
    t,
    authorized_profile.auth_tokens.access_token,
  )
  use t, issue1 <- utils.next_create_issue(
    t,
    authorized_profile.auth_tokens.access_token,
    directory.id,
  )
  use t, issue2 <- utils.next_create_issue(
    t,
    authorized_profile.auth_tokens.access_token,
    directory.id,
  )
  use t, issue3 <- utils.next_create_issue(
    t,
    authorized_profile.auth_tokens.access_token,
    directory.id,
  )

  let response =
    router.handle_request(
      testing.get("/api/issues?skip=0&take=1", [
        utils.bearer_header(authorized_profile.auth_tokens.access_token),
      ]),
      t.context,
    )

  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), paginated_issues.decoder())
  data |> should.equal(paginated_issues.PaginatedIssues(3, True, [issue1]))

  let response =
    router.handle_request(
      testing.get("/api/issues?skip=1&take=2", [
        utils.bearer_header(authorized_profile.auth_tokens.access_token),
      ]),
      t.context,
    )

  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), paginated_issues.decoder())
  data
  |> should.equal(paginated_issues.PaginatedIssues(3, False, [issue2, issue3]))
}

pub fn find_issues_missing_authorization_header_test() {
  utils.missing_authorization_header_tester(http.Get, "/api/issues")
}

pub fn find_issues_invalid_bearer_format_test() {
  utils.invalid_bearer_format_tester(http.Get, "/api/issues")
}

pub fn find_issues_invalid_jwt_test() {
  utils.invalid_jwt_tester(http.Get, "/api/issues")
}

pub fn find_issues_profile_required_test() {
  utils.profile_required_tester(http.Get, "/api/issues")
}

pub fn find_one_issue_test() {
  use t <- utils.with_context

  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)
  use t, directory <- utils.next_create_directory(
    t,
    authorized_profile.auth_tokens.access_token,
  )
  use t, issue <- utils.next_create_issue(
    t,
    authorized_profile.auth_tokens.access_token,
    directory.id,
  )

  let response =
    router.handle_request(
      testing.get("/api/issues/" <> issue.id, [
        utils.bearer_header(authorized_profile.auth_tokens.access_token),
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
  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)
  let response =
    router.handle_request(
      testing.get("/api/issues/" <> "1", [
        utils.bearer_header(authorized_profile.auth_tokens.access_token),
      ]),
      t.context,
    )

  response.status |> should.equal(404)
}

pub fn find_one_missing_authorization_header_test() {
  utils.missing_authorization_header_tester(http.Get, "/api/issues/1")
}

pub fn find_one_invalid_bearer_format_test() {
  utils.invalid_bearer_format_tester(http.Get, "/api/issues/1")
}

pub fn find_one_invalid_jwt_test() {
  utils.invalid_jwt_tester(http.Get, "/api/issues/1")
}

pub fn find_one_profile_required_test() {
  utils.profile_required_tester(http.Get, "/api/issues/1")
}

pub fn update_one_issue_test() {
  use t <- utils.with_context

  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)
  use t, directory <- utils.next_create_directory(
    t,
    authorized_profile.auth_tokens.access_token,
  )
  use t, issue <- utils.next_create_issue(
    t,
    authorized_profile.auth_tokens.access_token,
    directory.id,
  )
  let input =
    update_issue_input.to_json(UpdateIssueInput(
      name: option.Some("Mikkel"),
      description: option.Some(option.Some("Nice")),
    ))

  let response =
    router.handle_request(
      testing.patch_json(
        "/api/issues/" <> issue.id,
        [utils.bearer_header(authorized_profile.auth_tokens.access_token)],
        input,
      ),
      t.context,
    )

  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), issue.decoder())
  data
  |> should.equal(
    Issue(..issue, name: "Mikkel", description: option.Some("Nice")),
  )
}

pub fn update_one_issue_null_test() {
  use t <- utils.with_context

  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)
  use t, directory <- utils.next_create_directory(
    t,
    authorized_profile.auth_tokens.access_token,
  )
  use t, issue <- utils.next_create_issue(
    t,
    authorized_profile.auth_tokens.access_token,
    directory.id,
  )
  let input =
    update_issue_input.to_json(UpdateIssueInput(
      name: option.None,
      description: option.Some(option.None),
    ))

  let response =
    router.handle_request(
      testing.patch_json(
        "/api/issues/" <> issue.id,
        [utils.bearer_header(authorized_profile.auth_tokens.access_token)],
        input,
      ),
      t.context,
    )
  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), issue.decoder())
  data
  |> should.equal(Issue(..issue, description: option.None))
}

pub fn update_one_issue_not_found_test() {
  use t <- utils.with_context

  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)

  let input =
    update_issue_input.to_json(UpdateIssueInput(
      name: option.Some("Mikkel"),
      description: option.Some(option.Some("Mikkel")),
    ))

  let response =
    router.handle_request(
      testing.patch_json(
        "/api/issues/" <> "1",
        [utils.bearer_header(authorized_profile.auth_tokens.access_token)],
        input,
      ),
      t.context,
    )

  response.status |> should.equal(404)
}

pub fn update_one_issue_none_test() {
  use t <- utils.with_context

  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)
  use t, directory <- utils.next_create_directory(
    t,
    authorized_profile.auth_tokens.access_token,
  )
  use t, issue <- utils.next_create_issue(
    t,
    authorized_profile.auth_tokens.access_token,
    directory.id,
  )
  let input =
    update_issue_input.to_json(UpdateIssueInput(
      name: option.None,
      description: option.None,
    ))

  let response =
    router.handle_request(
      testing.patch_json(
        "/api/issues/" <> issue.id,
        [utils.bearer_header(authorized_profile.auth_tokens.access_token)],
        input,
      ),
      t.context,
    )
  response.status |> should.equal(200)
  let assert Ok(data) =
    json.decode(testing.string_body(response), issue.decoder())
  data |> should.equal(issue)
}

pub fn update_one_missing_authorization_header_test() {
  utils.missing_authorization_header_tester(http.Patch, "/api/issues/1")
}

pub fn update_one_invalid_bearer_format_test() {
  utils.invalid_bearer_format_tester(http.Patch, "/api/issues/1")
}

pub fn update_one_invalid_jwt_test() {
  utils.invalid_jwt_tester(http.Patch, "/api/issues/1")
}

pub fn update_one_profile_required_test() {
  utils.profile_required_tester(http.Patch, "/api/issues/1")
}

pub fn delete_one_issue_test() {
  use t <- utils.with_context

  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)
  use t, directory <- utils.next_create_directory(
    t,
    authorized_profile.auth_tokens.access_token,
  )
  use t, issue <- utils.next_create_issue(
    t,
    authorized_profile.auth_tokens.access_token,
    directory.id,
  )

  let response =
    router.handle_request(
      testing.delete(
        "/api/issues/" <> issue.id,
        [utils.bearer_header(authorized_profile.auth_tokens.access_token)],
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

  use t, authorized_profile <- utils.next_create_user_and_profile_and_login(t)

  let response =
    router.handle_request(
      testing.delete(
        "/api/issues/" <> "1",
        [utils.bearer_header(authorized_profile.auth_tokens.access_token)],
        "",
      ),
      t.context,
    )

  response.status |> should.equal(404)
}

pub fn delete_one_missing_authorization_header_test() {
  utils.missing_authorization_header_tester(http.Delete, "/api/issues/1")
}

pub fn delete_one_invalid_bearer_format_test() {
  utils.invalid_bearer_format_tester(http.Delete, "/api/issues/1")
}

pub fn delete_one_invalid_jwt_test() {
  utils.invalid_jwt_tester(http.Delete, "/api/issues/1")
}

pub fn delete_one_profile_required_test() {
  utils.profile_required_tester(http.Delete, "/api/issues/1")
}
