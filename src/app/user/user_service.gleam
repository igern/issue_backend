import app/common/response_utils
import app/types.{type Context}
import app/user/inputs/create_user_input
import aragorn2
import gleam/bit_array
import gleam/dynamic
import gleam/json
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

  wisp.log_info(hash)

  json.object([#("id", json.int(id)), #("email", json.string(email))])
  |> json.to_string_builder()
  |> wisp.json_response(201)
}
