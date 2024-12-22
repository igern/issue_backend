import app/common/response_utils.{DatabaseError, UserNotFoundError}
import app/types.{type Context}
import app/user/inputs/create_user_input.{type CreateUserInput}
import app/user/outputs/user.{User}
import aragorn2
import gleam/bit_array
import gleam/dynamic
import sqlight
import youid/uuid

pub fn user_decoder() {
  dynamic.tuple3(dynamic.string, dynamic.string, dynamic.string)
}

pub fn create(input: CreateUserInput, ctx: Context) {
  let assert Ok(hash) =
    aragorn2.hash_password(
      aragorn2.hasher(),
      bit_array.from_string(input.password),
    )

  let sql =
    "insert into users (id, email, password) values (?, ?, ?) returning *"
  let id = uuid.v4_string()
  case
    sqlight.query(
      sql,
      on: ctx.connection,
      with: [sqlight.text(id), sqlight.text(input.email), sqlight.text(hash)],
      expecting: user_decoder(),
    )
  {
    Ok([#(id, email, _)]) -> Ok(User(id, email))
    Error(error) -> Error(DatabaseError(error))
    _ -> panic as "More than one row was returned from an insert."
  }
}

pub fn delete_one(id: String, ctx: Context) {
  let sql = "delete from users where id = ? returning *"

  let result =
    sqlight.query(sql, ctx.connection, [sqlight.text(id)], user_decoder())

  case result {
    Ok([#(id, email, _)]) -> Ok(User(id, email))
    Error(error) -> Error(DatabaseError(error))
    _ -> Error(UserNotFoundError)
  }
}
