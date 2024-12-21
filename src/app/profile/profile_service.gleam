import app/common/response_utils.{
  DatabaseError, FileReadError, ProfileNotFoundError,
}
import app/profile/inputs/create_profile_input.{type CreateProfileInput}
import app/profile/outputs/profile.{Profile}
import app/storage/storage
import app/types.{type Context}
import gleam/dynamic
import gleam/int
import gleam/result
import simplifile
import sqlight

pub fn profile_decoder() {
  dynamic.tuple4(
    dynamic.int,
    dynamic.int,
    dynamic.string,
    dynamic.optional(dynamic.string),
  )
}

pub fn create(input: CreateProfileInput, user_id: Int, ctx: Context) {
  let sql = "insert into profiles (user_id, name) values (?, ?) returning *"

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [sqlight.int(user_id), sqlight.text(input.name)],
      profile_decoder(),
    )

  case result {
    Ok([#(id, user_id, name, profile_picture)]) ->
      Ok(Profile(id, user_id, name, profile_picture))
    Error(error) -> Error(DatabaseError(error))
    _ -> panic as "Should only return one row from an insert"
  }
}

pub fn find_one_from_user_id(user_id: Int, ctx: Context) {
  let sql = "select * from profiles where user_id = ?"

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [sqlight.int(user_id)],
      profile_decoder(),
    )

  case result {
    Ok([#(id, user_id, name, profile_picture)]) ->
      Ok(Profile(id, user_id, name, profile_picture))
    Ok(_) -> Error(ProfileNotFoundError)
    Error(error) -> Error(DatabaseError(error))
  }
}

pub fn upload_profile_picture(file_path: String, id: Int, ctx: Context) {
  use file <- result.try(
    simplifile.read_bits(file_path)
    |> result.map_error(fn(error) { FileReadError(error) }),
  )

  use key <- result.try(
    storage.upload_file(
      ctx.storage_credentials,
      ctx.storage_bucket,
      "profile-pictures/" <> id |> int.to_string <> ".jpg",
      file,
    )
    |> result.map_error(fn(error) { response_utils.FileUploadError(error) }),
  )

  let sql = "update profiles set profile_picture = ? where id = ? returning *"

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [sqlight.text(key), sqlight.int(id)],
      profile_decoder(),
    )

  case result {
    Ok([#(id, user_id, name, profile_picture)]) ->
      Ok(Profile(id, user_id, name, profile_picture))
    Error(error) -> Error(DatabaseError(error))
    _ -> Error(ProfileNotFoundError)
  }
}
