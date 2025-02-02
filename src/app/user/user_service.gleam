import app/common/response_utils.{DatabaseError, UserNotFoundError}
import app/types.{type Context}
import app/user/inputs/create_user_input.{type CreateUserInput}
import app/user/outputs/user.{User}
import argus
import gleam/dynamic/decode
import sqlight
import youid/uuid

pub fn user_decoder() {
  use id <- decode.field(0, decode.string)
  use email <- decode.field(1, decode.string)
  use password <- decode.field(2, decode.string)
  decode.success(#(id, email, password))
}

pub fn create(input: CreateUserInput, ctx: Context) {
  let assert Ok(hash) =
    argus.hash(argus.hasher(), input.password, argus.gen_salt())

  let sql =
    "insert into users (id, email, password) values (?, ?, ?) returning *"
  let id = uuid.v4_string()
  case
    sqlight.query(
      sql,
      on: ctx.connection,
      with: [
        sqlight.text(id),
        sqlight.text(input.email),
        sqlight.text(hash.encoded_hash),
      ],
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
