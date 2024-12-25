import app/common/inputs/pagination_input.{type PaginationInput}
import app/common/response_utils.{DatabaseError, IssueNotFoundError}
import app/issue/inputs/create_issue_input.{type CreateIssueInput}
import app/issue/inputs/update_issue_input.{type UpdateIssueInput}
import app/issue/outputs/issue.{Issue}
import app/issue/outputs/paginated_issues
import app/types.{type Context}
import gleam/dynamic
import gleam/io
import gleam/list
import gleam/option
import gleam/string
import sqlight.{ConstraintForeignkey}
import youid/uuid

fn issue_decoder() {
  dynamic.tuple5(
    dynamic.string,
    dynamic.string,
    dynamic.optional(dynamic.string),
    dynamic.string,
    dynamic.string,
  )
}

pub fn create(input: CreateIssueInput, creator_id: String, ctx: Context) {
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
        sqlight.text(input.directory_id),
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

pub fn find_paginated(input: PaginationInput, ctx: Context) {
  let items_sql = "select * from issues limit ? offset ?"
  let total_sql = "select count(*) from issues"

  let items_result =
    sqlight.query(
      items_sql,
      on: ctx.connection,
      with: [sqlight.int(input.take), sqlight.int(input.skip)],
      expecting: issue_decoder(),
    )
  let total_result =
    sqlight.query(
      total_sql,
      ctx.connection,
      [],
      dynamic.element(0, dynamic.int),
    )
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

fn sqlight_string_set(update: #(String, option.Option(String))) {
  case update.1 {
    option.Some(value) -> {
      let set = update.0 <> " = ?"
      let value = sqlight.text(value)
      option.Some(#(set, value))
    }
    option.None -> option.None
  }
}

fn create_set_and_values(updates: List(option.Option(#(String, sqlight.Value)))) {
  let updates =
    list.filter_map(updates, fn(update) {
      case update {
        option.Some(update) -> Ok(update)
        option.None -> Error(Nil)
      }
    })
  let set =
    list.map(updates, fn(update) { update.0 })
    |> string.join(", ")
  let values = list.map(updates, fn(update) { update.1 })
  case list.length(updates) > 0 {
    True -> Ok(#(set, values))
    False -> Error(Nil)
  }
}

pub fn update_one(id: String, input: UpdateIssueInput, ctx: Context) {
  let sql = "update issues set $set where id = ? returning *"
  io.debug(input)

  case
    create_set_and_values([
      sqlight_string_set(#("name", input.name)),
      sqlight_string_set(#("description", input.description)),
    ])
  {
    Ok(#(set, values)) -> {
      let sql = string.replace(sql, "$set", set)
      io.debug(sql)
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
