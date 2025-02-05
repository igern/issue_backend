import app/common/inputs/pagination_input.{type PaginationInput}
import app/common/response_utils.{DatabaseError, IssueNotFoundError}
import app/common/sqlight_utils
import app/common/valid
import app/issue/inputs/create_issue_input.{type CreateIssueInput}
import app/issue/inputs/update_issue_input.{type UpdateIssueInput}
import app/issue/outputs/issue.{Issue}
import app/issue/outputs/paginated_issues
import app/types.{type Context}
import gleam/dynamic/decode
import gleam/list
import gleam/string
import sqlight.{ConstraintForeignkey}
import youid/uuid

pub fn issue_decoder() {
  use id <- decode.field(0, decode.string)
  use name <- decode.field(1, decode.string)
  use description <- decode.field(2, decode.optional(decode.string))
  use creator_id <- decode.field(3, decode.string)
  use directory_id <- decode.field(4, decode.string)
  decode.success(#(id, name, description, creator_id, directory_id))
}

pub fn create(
  directory_id: String,
  creator_id: String,
  input: valid.Valid(CreateIssueInput),
  ctx: Context,
) {
  let input = valid.inner(input)
  let sql =
    "insert into issues (id, name, description, creator_id, directory_id) values (?, ?, ?, ?, ?) returning *"
  let id = uuid.v4_string()

  let result =
    sqlight.query(
      sql,
      on: ctx.connection,
      with: [
        sqlight.text(id),
        sqlight.text(input.name),
        sqlight.nullable(sqlight.text, input.description),
        sqlight.text(creator_id),
        sqlight.text(directory_id),
      ],
      expecting: issue_decoder(),
    )

  case result {
    Ok([#(id, name, description, creator_id, directory_id)]) ->
      Ok(Issue(id, name, description, creator_id, directory_id))
    Error(sqlight.SqlightError(ConstraintForeignkey, _, _)) ->
      Error(response_utils.DirectoryNotFoundError)
    Error(error) -> Error(DatabaseError(error))
    _ -> panic as "More than one row was returned from an insert."
  }
}

pub fn find_paginated(input: valid.Valid(PaginationInput), ctx: Context) {
  let input = valid.inner(input)
  let items_sql = "select * from issues limit ? offset ?"
  let total_sql = "select count(*) from issues"

  let items_result =
    sqlight.query(
      items_sql,
      on: ctx.connection,
      with: [sqlight.int(input.take), sqlight.int(input.skip)],
      expecting: issue_decoder(),
    )

  let count_decoder = {
    use total <- decode.field(0, decode.int)
    decode.success(total)
  }
  let total_result = sqlight.query(total_sql, ctx.connection, [], count_decoder)
  case items_result, total_result {
    Ok(items_result), Ok(totals) -> {
      let assert [total] = totals
      let issues =
        list.map(items_result, fn(issue) {
          let #(id, name, description, creator_id, directory_id) = issue
          Issue(id, name, description, creator_id, directory_id)
        })
      let issues_length = list.length(issues)
      let paginated_issues =
        paginated_issues.PaginatedIssues(
          total: total,
          has_more: total > issues_length + input.skip,
          items: issues,
        )
      Ok(paginated_issues)
    }
    Error(error), _ -> Error(DatabaseError(error))
    _, Error(error) -> Error(DatabaseError(error))
  }
}

pub fn find_one(id: String, ctx: Context) {
  let sql = "select * from issues where id = ?"

  let result =
    sqlight.query(
      sql,
      on: ctx.connection,
      with: [sqlight.text(id)],
      expecting: issue_decoder(),
    )

  case result {
    Ok([#(id, name, description, creator_id, directory_id)]) ->
      Ok(Issue(id, name, description, creator_id, directory_id))
    Error(error) -> Error(DatabaseError(error))
    _ -> Error(IssueNotFoundError)
  }
}

pub fn update_one(
  id: String,
  input: valid.Valid(UpdateIssueInput),
  ctx: Context,
) {
  let input = valid.inner(input)
  let sql = "update issues set $set where id = ? returning *"

  case
    sqlight_utils.sqlight_patch_helper([
      sqlight_utils.sqlight_string_optional(#("name", input.name)),
      sqlight_utils.sqlight_string_optional_null(#(
        "description",
        input.description,
      )),
    ])
  {
    Ok(#(set, values)) -> {
      let sql = string.replace(sql, "$set", set)
      let result =
        sqlight.query(
          sql,
          on: ctx.connection,
          with: list.flatten([values, [sqlight.text(id)]]),
          expecting: issue_decoder(),
        )

      case result {
        Ok([#(id, name, description, creator_id, directory_id)]) ->
          Ok(Issue(id, name, description, creator_id, directory_id))
        Error(error) -> Error(DatabaseError(error))
        _ -> Error(IssueNotFoundError)
      }
    }
    _ -> find_one(id, ctx)
  }
}

pub fn delete_one(id: String, ctx: Context) {
  let sql = "delete from issues where id = ? returning *"

  let result =
    sqlight.query(
      sql,
      on: ctx.connection,
      with: [sqlight.text(id)],
      expecting: issue_decoder(),
    )

  case result {
    Ok([#(id, name, description, creator_id, directory_id)]) ->
      Ok(Issue(id, name, description, creator_id, directory_id))
    Error(error) -> Error(DatabaseError(error))
    _ -> Error(IssueNotFoundError)
  }
}
