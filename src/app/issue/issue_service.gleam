import app/common/response_utils
import app/issue/inputs/create_issue_input
import app/issue/inputs/update_issue_input
import app/types.{type Context}
import gleam/dynamic
import gleam/int
import gleam/json
import sqlight
import wisp.{type Request, type Response}

pub fn create(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)
  use input <- response_utils.or_400(create_issue_input.from_dynamic(json))

  let sql = "insert into issues (name) values (?) returning *"

  let assert Ok([#(id, name)]) =
    sqlight.query(
      sql,
      on: ctx.connection,
      with: [sqlight.text(input.name)],
      expecting: dynamic.tuple2(dynamic.int, dynamic.string),
    )

  json.object([#("id", json.int(id)), #("name", json.string(name))])
  |> json.to_string_builder()
  |> wisp.json_response(201)
}

pub fn find_all(ctx: Context) -> Response {
  let sql = "select * from issues"

  let assert Ok(results) =
    sqlight.query(
      sql,
      on: ctx.connection,
      with: [],
      expecting: dynamic.tuple2(dynamic.int, dynamic.string),
    )

  json.array(results, of: fn(issue) {
    let #(id, name) = issue
    json.object([#("id", json.int(id)), #("name", json.string(name))])
  })
  |> json.to_string_builder
  |> wisp.json_response(200)
}

pub fn find_one(id: String, ctx: Context) -> Response {
  use id <- response_utils.or_400(int.parse(id))

  let sql = "select * from issues where id = ?"

  let result =
    sqlight.query(
      sql,
      on: ctx.connection,
      with: [sqlight.int(id)],
      expecting: dynamic.tuple2(dynamic.int, dynamic.string),
    )

  case result {
    Ok([#(id, name)]) -> {
      json.object([#("id", json.int(id)), #("name", json.string(name))])
      |> json.to_string_builder()
      |> wisp.json_response(200)
    }
    _ -> wisp.not_found()
  }
}

pub fn delete_one(id: String, ctx: Context) -> Response {
  use id <- response_utils.or_400(int.parse(id))

  let sql = "delete from issues where id = ? returning *"

  let assert Ok(result) =
    sqlight.query(
      sql,
      on: ctx.connection,
      with: [sqlight.int(id)],
      expecting: dynamic.tuple2(dynamic.int, dynamic.string),
    )

  case result {
    [#(id, name)] -> {
      json.object([#("id", json.int(id)), #("name", json.string(name))])
      |> json.to_string_builder()
      |> wisp.json_response(200)
    }
    _ -> wisp.not_found()
  }
}

pub fn update_one(req: Request, id: String, ctx: Context) -> Response {
  use id <- response_utils.or_400(int.parse(id))
  use json <- wisp.require_json(req)
  use input <- response_utils.or_400(update_issue_input.from_dynamic(json))

  let sql = "update issues set name = ? where id = ? returning *"

  let assert Ok(result) =
    sqlight.query(
      sql,
      on: ctx.connection,
      with: [sqlight.text(input.name), sqlight.int(id)],
      expecting: dynamic.tuple2(dynamic.int, dynamic.string),
    )

  case result {
    [#(id, name)] -> {
      json.object([#("id", json.int(id)), #("name", json.string(name))])
      |> json.to_string_builder()
      |> wisp.json_response(200)
    }
    _ -> wisp.not_found()
  }
}
