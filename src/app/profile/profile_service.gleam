import app/common/response_utils.{
  DatabaseError, FileReadError, ProfileNotFoundError,
}
import app/profile/inputs/create_profile_input.{type CreateProfileInput}
import app/profile/outputs/profile.{Profile}
import app/storage/storage
import app/types.{type Context}
import gleam/dynamic/decode
import gleam/result
import simplifile
import sqlight
import youid/uuid

pub fn profile_decoder() {
  use id <- decode.field(0, decode.string)
  use user_id <- decode.field(1, decode.string)
  use name <- decode.field(2, decode.string)
  use profile_picture <- decode.field(3, decode.optional(decode.string))
  decode.success(#(id, user_id, name, profile_picture))
}

pub fn create(input: CreateProfileInput, user_id: String, ctx: Context) {
  let sql =
    "insert into profiles (id, user_id, name) values (?, ?, ?) returning *"
  let id = uuid.v4_string()

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [sqlight.text(id), sqlight.text(user_id), sqlight.text(input.name)],
      profile_decoder(),
    )

  case result {
    Ok([#(id, user_id, name, profile_picture)]) ->
      Ok(Profile(id, user_id, name, profile_picture))
    Error(error) -> Error(DatabaseError(error))
    _ -> panic as "Should only return one row from an insert"
  }
}

pub fn find_one_from_user_id(user_id: String, ctx: Context) {
  let sql = "select * from profiles where user_id = ?"

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [sqlight.text(user_id)],
      profile_decoder(),
    )

  case result {
    Ok([#(id, user_id, name, profile_picture)]) ->
      Ok(Profile(id, user_id, name, profile_picture))
    Ok(_) -> Error(ProfileNotFoundError)
    Error(error) -> Error(DatabaseError(error))
  }
}

pub fn upload_profile_picture(file_path: String, id: String, ctx: Context) {
  use file <- result.try(
    simplifile.read_bits(file_path)
    |> result.map_error(fn(error) { FileReadError(error) }),
  )

  use key <- result.try(
    storage.upload_file(
      ctx.storage_credentials,
      ctx.storage_bucket,
      "profile-pictures/" <> id <> ".jpg",
      file,
    )
    |> result.map_error(fn(error) { response_utils.FileUploadError(error) }),
  )

  let sql = "update profiles set profile_picture = ? where id = ? returning *"

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [sqlight.text(key), sqlight.text(id)],
      profile_decoder(),
    )

  case result {
    Ok([#(id, user_id, name, profile_picture)]) ->
      Ok(Profile(id, user_id, name, profile_picture))
    Error(error) -> Error(DatabaseError(error))
    _ -> Error(ProfileNotFoundError)
  }
}
