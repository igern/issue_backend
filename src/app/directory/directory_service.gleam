import app/common/response_utils.{DatabaseError, DirectoryNotFoundError}
import app/directory/inputs/create_directory_input.{type CreateDirectoryInput}
import app/directory/inputs/update_directory_input.{type UpdateDirectoryInput}
import app/directory/outputs/directory.{Directory}
import app/types.{type Context}
import birl
import gleam/dynamic
import sqlight
import youid/uuid

pub fn directory_decoder() {
  dynamic.tuple4(dynamic.string, dynamic.string, dynamic.string, dynamic.string)
}

pub fn create(team_id: String, input: CreateDirectoryInput, ctx: Context) {
  let sql =
    "insert into directories (id, name, team_id, created_at) values(?, ?, ?, ?) returning *"

  let id = uuid.v4_string()
  let created_at = birl.now() |> birl.to_iso8601

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [
        sqlight.text(id),
        sqlight.text(input.name),
        sqlight.text(team_id),
        sqlight.text(created_at),
      ],
      directory_decoder(),
    )

  case result {
    Ok([#(id, name, team_id, created_at)]) ->
      Ok(Directory(id, name, team_id, created_at))
    Error(error) -> Error(DatabaseError(error))
    _ -> panic as "Should only return one row from an insert"
  }
}

pub fn delete_one(id: String, ctx: Context) {
  let sql = "delete from directories where id = ? returning *"

  let result =
    sqlight.query(sql, ctx.connection, [sqlight.text(id)], directory_decoder())

  case result {
    Ok([#(id, name, team_id, created_at)]) ->
      Ok(Directory(id, name, team_id, created_at))
    Error(error) -> Error(DatabaseError(error))
    Ok([]) -> Error(DirectoryNotFoundError)
    _ -> panic as "Should only return one row from a delete"
  }
}

pub fn update_one(id: String, input: UpdateDirectoryInput, ctx: Context) {
  let sql = "update directories set name = ? where id = ? returning *"

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [sqlight.text(input.name), sqlight.text(id)],
      directory_decoder(),
    )

  case result {
    Ok([#(id, name, team_id, created_at)]) ->
      Ok(Directory(id, name, team_id, created_at))
    Error(error) -> Error(DatabaseError(error))
    Ok([]) -> Error(DirectoryNotFoundError)
    _ -> panic as "Should only return one row from a delete"
  }
}
