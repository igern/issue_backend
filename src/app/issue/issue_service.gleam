import app/common/response_utils.{DatabaseError, IssueNotFoundError}
import app/issue/inputs/create_issue_input.{type CreateIssueInput}
import app/issue/inputs/update_issue_input.{type UpdateIssueInput}
import app/issue/outputs/issue.{Issue}
import app/types.{type Context}
import gleam/dynamic
import gleam/list
import sqlight

fn issue_decoder() {
  dynamic.tuple3(dynamic.int, dynamic.string, dynamic.int)
}

pub fn create(input: CreateIssueInput, user_id: Int, ctx: Context) {
  let sql = "insert into issues (name, creator_id) values (?, ?) returning *"

  let result =
    sqlight.query(
      sql,
      on: ctx.connection,
      with: [sqlight.text(input.name), sqlight.int(user_id)],
      expecting: issue_decoder(),
    )

  case result {
    Ok([#(id, name, creator_id)]) -> Ok(Issue(id, name, creator_id))
    Error(error) -> Error(DatabaseError(error))
    _ -> panic as "More than one row was returned from an insert."
  }
}

pub fn find_all(ctx: Context) {
  let sql = "select * from issues"

  let result =
    sqlight.query(sql, on: ctx.connection, with: [], expecting: issue_decoder())

  case result {
    Ok(result) -> {
      let issues =
        list.map(result, fn(issue) {
          let #(id, name, creator_id) = issue
          Issue(id, name, creator_id)
        })
      Ok(issues)
    }
    Error(error) -> Error(DatabaseError(error))
  }
}

pub fn find_one(id: Int, ctx: Context) {
  let sql = "select * from issues where id = ?"

  let result =
    sqlight.query(
      sql,
      on: ctx.connection,
      with: [sqlight.int(id)],
      expecting: issue_decoder(),
    )

  case result {
    Ok([#(id, name, creator_id)]) -> Ok(Issue(id, name, creator_id))
    Error(error) -> Error(DatabaseError(error))
    _ -> Error(IssueNotFoundError)
  }
}

pub fn update_one(id: Int, input: UpdateIssueInput, ctx: Context) {
  let sql = "update issues set name = ? where id = ? returning *"

  let result =
    sqlight.query(
      sql,
      on: ctx.connection,
      with: [sqlight.text(input.name), sqlight.int(id)],
      expecting: issue_decoder(),
    )

  case result {
    Ok([#(id, name, creator_id)]) -> Ok(Issue(id, name, creator_id))
    Error(error) -> Error(DatabaseError(error))
    _ -> Error(IssueNotFoundError)
  }
}

pub fn delete_one(id: Int, ctx: Context) {
  let sql = "delete from issues where id = ? returning *"

  let result =
    sqlight.query(
      sql,
      on: ctx.connection,
      with: [sqlight.int(id)],
      expecting: issue_decoder(),
    )

  case result {
    Ok([#(id, name, creator_id)]) -> Ok(Issue(id, name, creator_id))
    Error(error) -> Error(DatabaseError(error))
    _ -> Error(IssueNotFoundError)
  }
}
