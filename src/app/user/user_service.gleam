import app/common/response_utils
import app/types.{type Context}
import app/user/inputs/create_user_input
import app/user/inputs/login_input
import app/user/outputs/auth_tokens.{AuthTokens}
import aragorn2
import birl
import birl/duration
import gleam/bit_array
import gleam/crypto
import gleam/dynamic
import gleam/int
import gleam/json
import gwt
import sqlight
import wisp.{type Request}

pub fn create(req: Request, ctx: Context) {
  use json <- wisp.require_json(req)
  use input <- response_utils.or_400(create_user_input.from_dynamic(json))
  let assert Ok(hash) =
    aragorn2.hash_password(
      aragorn2.hasher(),
      bit_array.from_string(input.password),
    )

  let sql = "insert into users (email, password) values (?, ?) returning *"

  let assert Ok([#(id, email, _)]) =
    sqlight.query(
      sql,
      on: ctx.connection,
      with: [sqlight.text(input.email), sqlight.text(hash)],
      expecting: dynamic.tuple3(dynamic.int, dynamic.string, dynamic.string),
    )

  json.object([#("id", json.int(id)), #("email", json.string(email))])
  |> json.to_string_builder()
  |> wisp.json_response(201)
}

pub fn login(req: Request, ctx: Context) {
  use json <- wisp.require_json(req)
  use input <- response_utils.or_400(login_input.from_dynamic(json))

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
        Ok(Nil) -> {
          auth_tokens.to_json(create_auth_tokens(id, ctx))
          |> json.to_string_builder()
          |> wisp.json_response(201)
        }
        _ -> wisp.not_found()
      }
    }
    Error(_) -> panic
    _ -> wisp.not_found()
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
