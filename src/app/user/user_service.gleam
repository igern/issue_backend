import app/common/response_utils.{DatabaseError}
import app/types.{type Context}
import app/user/inputs/create_user_input.{type CreateUserInput}
import app/user/outputs/user.{User}
import aragorn2
import gleam/bit_array
import gleam/dynamic
import sqlight

pub fn create(input: CreateUserInput, ctx: Context) {
  let assert Ok(hash) =
    aragorn2.hash_password(
      aragorn2.hasher(),
      bit_array.from_string(input.password),
    )

  let sql = "insert into users (email, password) values (?, ?) returning *"

  case
    sqlight.query(
      sql,
      on: ctx.connection,
      with: [sqlight.text(input.email), sqlight.text(hash)],
      expecting: dynamic.tuple3(dynamic.int, dynamic.string, dynamic.string),
    )
  {
    Ok([#(id, email, _)]) -> Ok(User(id, email))
    _ -> Error(DatabaseError)
  }
}
