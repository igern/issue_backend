import app/common/response_utils.{DatabaseError, ProfileNotFoundError}
import app/profile/inputs/create_profile_input.{type CreateProfileInput}
import app/profile/outputs/profile.{Profile}
import app/types.{type Context}
import gleam/dynamic
import sqlight

fn profile_decoder() {
  dynamic.tuple3(dynamic.int, dynamic.int, dynamic.string)
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
    Ok([#(id, user_id, name)]) -> Ok(Profile(id, user_id, name))
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
    Ok([#(id, user_id, name)]) -> Ok(Profile(id, user_id, name))
    Ok(_) -> Error(ProfileNotFoundError)
    Error(error) -> Error(DatabaseError(error))
  }
}
