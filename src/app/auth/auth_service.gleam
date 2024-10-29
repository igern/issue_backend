import app/auth/inputs/login_input.{type LoginInput}
import app/auth/outputs/auth_tokens.{type AuthTokens, AuthTokens}
import app/common/response_utils.{DatabaseError, InvalidCredentialsError}
import app/types.{type Context}
import aragorn2
import birl
import birl/duration
import gleam/bit_array
import gleam/crypto
import gleam/dynamic
import gleam/int
import gwt
import sqlight

pub fn login(input: LoginInput, ctx: Context) {
  let sql = "select * from users where email = ?"

  let result =
    sqlight.query(
      sql,
      on: ctx.connection,
      with: [sqlight.text(input.email)],
      expecting: dynamic.tuple3(dynamic.int, dynamic.string, dynamic.string),
    )
  case result {
    Ok([#(id, _, password)]) -> {
      case
        aragorn2.verify_password(
          aragorn2.hasher(),
          bit_array.from_string(input.password),
          bit_array.from_string(password),
        )
      {
        Ok(Nil) -> Ok(create_auth_tokens(id, ctx))
        _ -> Error(InvalidCredentialsError)
      }
    }
    Error(_) -> Error(DatabaseError)
    _ -> Error(InvalidCredentialsError)
  }
}

fn create_auth_tokens(user_id: Int, ctx: Context) {
  let refresh_token = create_refresh_token(user_id, ctx)
  let access_token = create_access_token(int.to_string(user_id))
  AuthTokens(refresh_token: refresh_token, access_token: access_token)
}

fn create_refresh_token(user_id: Int, ctx: Context) {
  let sql =
    "insert into refresh_tokens (token, userId, expiresAt) values (?, ?, ?) returning *"

  let token = crypto.strong_random_bytes(16) |> bit_array.base16_encode

  let result =
    sqlight.query(
      sql,
      on: ctx.connection,
      with: [
        sqlight.text(token),
        sqlight.int(user_id),
        birl.now()
          |> birl.add(duration.months(6))
          |> birl.to_iso8601
          |> sqlight.text,
      ],
      expecting: dynamic.tuple3(dynamic.string, dynamic.string, dynamic.string),
    )

  case result {
    Ok([#(token, _, _)]) -> token
    _ -> create_refresh_token(user_id, ctx)
  }
}

fn create_access_token(sub: String) {
  gwt.new()
  |> gwt.set_subject(sub)
  |> gwt.set_expiration(
    birl.now() |> birl.add(duration.seconds(60)) |> birl.to_unix,
  )
  |> gwt.to_signed_string(gwt.HS256, "secret")
}
