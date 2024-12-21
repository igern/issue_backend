import bucket.{type Credentials}
import sqlight.{type Connection}

pub type Context {
  Context(
    connection: Connection,
    storage_credentials: Credentials,
    storage_bucket: String,
  )
}
