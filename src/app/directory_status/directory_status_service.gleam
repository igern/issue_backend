import app/common/response_utils
import app/common/sqlight_utils
import app/common/valid
import app/directory_status/inputs/create_directory_status_input
import app/directory_status/inputs/update_directory_status_input
import app/directory_status/outputs/directory_status.{DirectoryStatus}
import app/directory_status_type/directory_status_type_service
import app/types
import gleam/dynamic/decode
import gleam/list
import gleam/result
import gleam/string
import sqlight.{ConstraintForeignkey}
import youid/uuid

fn directory_status_decoder() {
  use id <- decode.field(0, decode.string)
  use name <- decode.field(1, decode.string)
  use directory_id <- decode.field(2, decode.string)
  use directory_status_type_name <- decode.field(3, decode.string)
  decode.success(#(id, name, directory_id, directory_status_type_name))
}

pub fn create(
  directory_id: String,
  input: valid.Valid(create_directory_status_input.CreateDirectoryStatusInput),
  ctx: types.Context,
) {
  let input = valid.inner(input)

  use directory_status_types <- result.try(
    directory_status_type_service.find_all(ctx),
  )
  use _ <- result.try(
    list.find(directory_status_types, fn(directory_status_type) {
      directory_status_type.name == input.directory_status_type_name
    })
    |> result.replace_error(response_utils.DirectoryStatusTypeNotFoundError),
  )
  let sql =
    "insert into directory_statuses (id, name, directory_id, directory_status_type_name) values(?, ?, ?, ?) returning *"

  let id = uuid.v4_string()

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [
        sqlight.text(id),
        sqlight.text(input.name),
        sqlight.text(directory_id),
        sqlight.text(input.directory_status_type_name),
      ],
      directory_status_decoder(),
    )

  case result {
    Ok([#(id, name, directory_id, directory_status_type_name)]) ->
      Ok(DirectoryStatus(id, name, directory_id, directory_status_type_name))
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
    Ok([#(id, name, directory_id, directory_status_type_name), ..]) ->
      Ok(DirectoryStatus(id, name, directory_id, directory_status_type_name))
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
        let #(id, name, directory_id, directory_status_type_name) =
          directory_status
        DirectoryStatus(id, name, directory_id, directory_status_type_name)
      })
      |> Ok
    }
    Error(error) -> Error(response_utils.DatabaseError(error))
  }
}

pub fn update_one(
  id: String,
  input: valid.Valid(update_directory_status_input.UpdateDirectoryStatusInput),
  ctx: types.Context,
) {
  let input = valid.inner(input)
  let sql = "update directory_statuses set $set where id = ? returning *"

  case
    sqlight_utils.sqlight_patch_helper([
      sqlight_utils.sqlight_string_optional(#("name", input.name)),
      sqlight_utils.sqlight_string_optional(#(
        "directory_status_type_name",
        input.directory_status_type_name,
      )),
    ])
  {
    Ok(#(set, values)) -> {
      let sql = string.replace(sql, "$set", set)
      let result =
        sqlight.query(
          sql,
          ctx.connection,
          list.flatten([values, [sqlight.text(id)]]),
          directory_status_decoder(),
        )

      case result {
        Ok([#(id, name, directory_id, directory_status_type_name), ..]) ->
          Ok(DirectoryStatus(id, name, directory_id, directory_status_type_name))
        Ok([]) -> Error(response_utils.DirectoryStatusNotFoundError)
        Error(sqlight.SqlightError(ConstraintForeignkey, _, _)) ->
          Error(response_utils.DirectoryStatusTypeNotFoundError)
        Error(error) -> Error(response_utils.DatabaseError(error))
      }
    }
    _ -> find_one(id, ctx)
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
    Ok([#(id, name, directory_id, directory_status_type_name), ..]) ->
      Ok(DirectoryStatus(id, name, directory_id, directory_status_type_name))
    Ok([]) -> Error(response_utils.DirectoryStatusNotFoundError)
    Error(error) -> Error(response_utils.DatabaseError(error))
  }
}
