import app/auth/inputs/login_input.{type LoginInput}
import app/auth/inputs/refresh_auth_tokens_input.{type RefreshAuthTokensInput}
import app/auth/outputs/auth_tokens.{type AuthTokens, AuthTokens}
import app/common/response_utils.{
  DatabaseError, InvalidCredentialsError, RefreshTokenExpiredError,
  RefreshTokenNotFoundError,
}
import app/types.{type Context}
import aragorn2
import birl
import birl/duration
import gleam/bit_array
import gleam/crypto
import gleam/dynamic
import gleam/int
import gleam/order
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
    Error(error) -> Error(DatabaseError(error))
    _ -> Error(InvalidCredentialsError)
  }
}

pub fn refresh_auth_tokens(input: RefreshAuthTokensInput, ctx: Context) {
  let sql = "select * from refresh_tokens where token = ?"

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [sqlight.text(input.refresh_token)],
      dynamic.tuple3(dynamic.string, dynamic.int, dynamic.string),
    )

  case result {
    Ok([#(token, user_id, expires_at)]) -> {
      let assert Ok(expires_at) = birl.parse(expires_at)
      case birl.compare(birl.now(), expires_at) {
        order.Lt -> {
          let sql = "delete from refresh_tokens where token = ?"

          let _ = case
            sqlight.query(
              sql,
              ctx.connection,
              [sqlight.text(token)],
              dynamic.tuple3(dynamic.string, dynamic.int, dynamic.string),
            )
          {
            Ok(_) -> {
              let auth_tokens = create_auth_tokens(user_id, ctx)
              Ok(auth_tokens)
            }
            Error(error) -> Error(DatabaseError(error))
          }
        }
        _ -> Error(RefreshTokenExpiredError)
      }
    }
    Error(error) -> Error(DatabaseError(error))
    _ -> Error(RefreshTokenNotFoundError)
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
      expecting: dynamic.tuple3(dynamic.string, dynamic.int, dynamic.string),
    )

  case result {
    Ok([#(token, _, _)]) -> token
    Error(error) ->
      todo as "should handle if there is an error with the database"
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
