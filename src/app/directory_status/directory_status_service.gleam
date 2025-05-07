import app/common/response_utils
import app/common/valid
import app/directory/inputs/create_directory_input
import app/directory_status/outputs/directory_status.{DirectoryStatus}
import app/types
import gleam/dynamic/decode
import gleam/list
import sqlight.{ConstraintForeignkey}
import youid/uuid

fn directory_status_decoder() {
  use id <- decode.field(0, decode.string)
  use name <- decode.field(1, decode.string)
  use directory_id <- decode.field(2, decode.string)
  decode.success(#(id, name, directory_id))
}

pub fn create(
  directory_id: String,
  input: valid.Valid(create_directory_input.CreateDirectoryInput),
  ctx: types.Context,
) {
  let input = valid.inner(input)
  let sql =
    "insert into directory_statuses (id, name, directory_id) values(?, ?, ?) returning *"

  let id = uuid.v4_string()

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [sqlight.text(id), sqlight.text(input.name), sqlight.text(directory_id)],
      directory_status_decoder(),
    )

  case result {
    Ok([#(id, name, directory_id)]) ->
      Ok(DirectoryStatus(id, name, directory_id))
    Error(sqlight.SqlightError(ConstraintForeignkey, _, _)) ->
      Error(response_utils.DirectoryNotFoundError)
    Error(error) -> Error(response_utils.DatabaseError(error))
    _ -> panic as "Should only return one row from an insert"
  }
}

pub fn find_one(directory_status_id: String, ctx: types.Context) {
  let sql = "select * from directory_statuses where id = ?"

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [sqlight.text(directory_status_id)],
      directory_status_decoder(),
    )

  case result {
    Ok([#(id, name, directory_id), ..]) ->
      Ok(DirectoryStatus(id, name, directory_id))
    Ok([]) -> Error(response_utils.DirectoryStatusNotFoundError)
    Error(error) -> Error(response_utils.DatabaseError(error))
  }
}

pub fn find_all_from_directory(directory_id: String, ctx: types.Context) {
  let sql = "select * from directory_statuses where directory_id = ?"

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [sqlight.text(directory_id)],
      directory_status_decoder(),
    )

  case result {
    Ok(directory_statuses) -> {
      list.map(directory_statuses, fn(directory_status) {
        let #(id, name, directory_id) = directory_status
        DirectoryStatus(id, name, directory_id)
      })
      |> Ok
    }
    Error(error) -> Error(response_utils.DatabaseError(error))
  }
}

pub fn delete_one(id: String, ctx: types.Context) {
  let sql = "delete from directory_statuses where id = ? returning *"

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [sqlight.text(id)],
      directory_status_decoder(),
    )

  case result {
    Ok([#(id, name, directory_id), ..]) ->
      Ok(DirectoryStatus(id, name, directory_id))
    Ok([]) -> Error(response_utils.DirectoryStatusNotFoundError)
    Error(error) -> Error(response_utils.DatabaseError(error))
  }
}
