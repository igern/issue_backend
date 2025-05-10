import app/common/response_utils
import app/directory_status_type/outputs/directory_status_type
import app/types
import gleam/dynamic/decode
import gleam/list
import sqlight

fn directory_status_type_decoder() {
  use name <- decode.field(0, decode.string)
  decode.success(#(name))
}

pub fn create(input: String, ctx: types.Context) {
  let sql = "insert into directory_status_types (name) values (?) returning *"

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [sqlight.text(input)],
      directory_status_type_decoder(),
    )

  case result {
    Ok([#(name), ..]) -> Ok(directory_status_type.DirectoryStatusType(name))
    Error(sqlight.SqlightError(sqlight.ConstraintPrimarykey, _, _)) ->
      Ok(directory_status_type.DirectoryStatusType(input))
    _ -> panic as "Could not create directory status type"
  }
}

pub fn find_all(ctx: types.Context) {
  let sql = "select * from directory_status_types"

  let result =
    sqlight.query(sql, ctx.connection, [], directory_status_type_decoder())

  case result {
    Ok(directory_status_types) -> {
      list.map(directory_status_types, fn(directory_status) {
        let #(name) = directory_status
        directory_status_type.DirectoryStatusType(name)
      })
      |> Ok
    }
    Error(error) -> Error(response_utils.DatabaseError(error))
  }
}
