import app/common/response_utils.{DatabaseError}
import app/directory/inputs/create_directory_input.{type CreateDirectoryInput}
import app/directory/outputs/directory.{Directory}
import app/types.{type Context}
import birl
import gleam/dynamic
import sqlight
import youid/uuid

pub fn directory_decoder() {
  dynamic.tuple3(dynamic.string, dynamic.string, dynamic.string)
}

pub fn create(input: CreateDirectoryInput, ctx: Context) {
  let sql =
    "insert into directories (id, name, created_at) values(?, ?, ?) returning *"

  let id = uuid.v4_string()
  let created_at = birl.now() |> birl.to_iso8601

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [sqlight.text(id), sqlight.text(input.name), sqlight.text(created_at)],
      directory_decoder(),
    )

  case result {
    Ok([#(id, name, created_at)]) -> Ok(Directory(id, name, created_at))
    Error(error) -> Error(DatabaseError(error))
    _ -> panic as "Should only return one row from an insert"
  }
}
