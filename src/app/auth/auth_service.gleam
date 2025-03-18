import app/auth/inputs/login_input.{type LoginInput}
import app/auth/inputs/refresh_auth_tokens_input.{type RefreshAuthTokensInput}
import app/auth/outputs/auth_tokens.{type AuthTokens, AuthTokens}
import app/common/response_utils.{
  type ServiceError, DatabaseError, InvalidCredentialsError,
  RefreshTokenExpiredError, RefreshTokenNotFoundError,
}
import app/common/valid
import app/types.{type Context}
import app/user/user_service
import argus
import birl
import birl/duration
import gleam/bit_array
import gleam/crypto
import gleam/dynamic/decode
import gleam/order
import gleam/result
import gwt
import sqlight.{ConstraintPrimarykey, SqlightError}

pub fn refresh_token_decoder() {
  use token <- decode.field(0, decode.string)
  use user_id <- decode.field(1, decode.string)
  use expires_at <- decode.field(2, decode.string)
  decode.success(#(token, user_id, expires_at))
}

pub fn login(
  input: valid.Valid(LoginInput),
  ctx: Context,
) -> Result(AuthTokens, ServiceError) {
  let input = valid.inner(input)
  let sql = "select * from users where email = ?"

  let result =
    sqlight.query(
      sql,
      on: ctx.connection,
      with: [sqlight.text(input.email)],
      expecting: user_service.user_decoder(),
    )
  case result {
    Ok([#(user_id, _, password)]) -> {
      case argus.verify(password, input.password) {
        Ok(True) -> {
          create_auth_tokens(user_id, ctx)
        }
        _ -> Error(InvalidCredentialsError)
      }
    }
    Error(error) -> Error(DatabaseError(error))
    _ -> Error(InvalidCredentialsError)
  }
}

pub fn refresh_auth_tokens(
  input: RefreshAuthTokensInput,
  ctx: Context,
) -> Result(AuthTokens, ServiceError) {
  let sql = "select * from refresh_tokens where token = ?"

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [sqlight.text(input.refresh_token)],
      refresh_token_decoder(),
    )

  case result {
    Ok([#(token, user_id, expires_at)]) -> {
      let assert Ok(expires_at) = birl.parse(expires_at)
      case birl.compare(birl.now(), expires_at) {
        order.Lt -> {
          let sql = "delete from refresh_tokens where token = ?"

          case
            sqlight.query(
              sql,
              ctx.connection,
              [sqlight.text(token)],
              refresh_token_decoder(),
            )
          {
            Ok(_) -> {
              create_auth_tokens(user_id, ctx)
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

fn create_refresh_token(
  user_id: String,
  ctx: Context,
) -> Result(String, ServiceError) {
  let sql =
    "insert into refresh_tokens (token, userId, expiresAt) values (?, ?, ?) returning *"

  let token = crypto.strong_random_bytes(16) |> bit_array.base16_encode

  let result =
    sqlight.query(
      sql,
      on: ctx.connection,
      with: [
        sqlight.text(token),
        sqlight.text(user_id),
        birl.now()
          |> birl.add(duration.months(6))
          |> birl.to_iso8601
          |> sqlight.text,
      ],
      expecting: refresh_token_decoder(),
    )

  case result {
    Ok([#(token, _, _)]) -> Ok(token)
    Error(SqlightError(ConstraintPrimarykey, _, _)) ->
      create_refresh_token(user_id, ctx)
    Error(error) -> Error(DatabaseError(error))
    _ -> panic as "More than one row was returned from an insert."
  }
}

fn create_auth_tokens(
  user_id: String,
  ctx: Context,
) -> Result(AuthTokens, ServiceError) {
  use refresh_token <- result.try(create_refresh_token(user_id, ctx))
  let access_token = create_access_token(user_id)
  Ok(AuthTokens(refresh_token: refresh_token, access_token: access_token))
}

fn create_access_token(sub: String) -> String {
  gwt.new()
  |> gwt.set_subject(sub)
  |> gwt.set_expiration(
    birl.now() |> birl.add(duration.seconds(5)) |> birl.to_unix,
  )
  |> gwt.to_signed_string(gwt.HS256, "secret")
}
