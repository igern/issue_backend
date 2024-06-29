import app/database
import app/router
import app/types.{Context}
import gleam/erlang/process
import mist
import sqlight
import wisp

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  use connection <- sqlight.with_connection(":memory:")
  let assert Ok(Nil) = database.init_schemas(connection)

  let context = Context(connection: connection)

  let handler = router.handle_request(_, context)
  let assert Ok(_) =
    handler
    |> wisp.mist_handler(secret_key_base)
    |> mist.new
    |> mist.port(3000)
    |> mist.start_http

  process.sleep_forever()
}
