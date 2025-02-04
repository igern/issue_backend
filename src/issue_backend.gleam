import app/database
import app/router
import app/types.{Context}
import bucket
import dot_env
import dot_env/env
import gleam/erlang/process
import gleam/http
import gleam/option
import mist
import radiate
import sqlight
import wisp
import wisp/wisp_mist

pub fn main() {
  let _ = radiate.new() |> radiate.add_dir("src") |> radiate.start()

  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  dot_env.load_default()
  let assert Ok(host) = env.get_string("STORAGE_HOST")
  let assert Ok(access) = env.get_string("STORAGE_ACCESS")
  let assert Ok(secret) = env.get_string("STORAGE_SECRET")
  let assert Ok(region) = env.get_string("STORAGE_SECRET")
  let assert Ok(port) = env.get_int("STORAGE_PORT")
  let creds =
    bucket.Credentials(
      host:,
      port: option.Some(port),
      scheme: http.Http,
      region:,
      access_key_id: access,
      secret_access_key: secret,
    )

  let assert Ok(bucket) = env.get_string("STORAGE_BUCKET")

  use connection <- sqlight.with_connection(":memory:")
  let assert Ok(Nil) = database.init_schemas(connection)

  let context =
    Context(
      connection: connection,
      storage_credentials: creds,
      storage_bucket: bucket,
    )

  let handler = router.handle_request(_, context)
  let assert Ok(_) =
    handler
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.port(8080)
    |> mist.start_http

  process.sleep_forever()
}
