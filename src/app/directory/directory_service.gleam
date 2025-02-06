import app/common/response_utils.{DatabaseError, DirectoryNotFoundError}
import app/common/valid
import app/directory/inputs/create_directory_input.{type CreateDirectoryInput}
import app/directory/inputs/update_directory_input.{type UpdateDirectoryInput}
import app/directory/outputs/directory.{Directory}
import app/types.{type Context}
import birl
import gleam/dynamic/decode
import gleam/list
import sqlight
import youid/uuid

pub fn directory_decoder() {
  use id <- decode.field(0, decode.string)
  use name <- decode.field(1, decode.string)
  use team_id <- decode.field(2, decode.string)
  use created_at <- decode.field(3, decode.string)
  decode.success(#(id, name, team_id, created_at))
}

pub fn create(
  team_id: String,
  input: valid.Valid(CreateDirectoryInput),
  ctx: Context,
) {
  let input = valid.inner(input)
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

pub fn find_one(directory_id: String, ctx: Context) {
  let sql = "select * from directories where id = ?"

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [sqlight.text(directory_id)],
      directory_decoder(),
    )

  case result {
    Ok([#(id, name, team_id, created_at)]) ->
      Ok(Directory(id, name, team_id, created_at))
    Error(error) -> Error(DatabaseError(error))
    Ok([]) -> Error(DirectoryNotFoundError)
    _ -> panic as "Should only return one row"
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

pub fn update_one(
  id: String,
  input: valid.Valid(UpdateDirectoryInput),
  ctx: Context,
) {
  let input = valid.inner(input)
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

pub fn find_from_team(team_id: String, ctx: Context) {
  let sql = "select * from directories where team_id = ?"

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [sqlight.text(team_id)],
      directory_decoder(),
    )

  case result {
    Ok(directories) -> {
      let directories =
        list.map(directories, fn(directory) {
          let #(id, name, team_id, created_at) = directory
          Directory(id, name, team_id, created_at)
        })
      Ok(directories)
    }
    Error(error) -> Error(DatabaseError(error))
  }
}
