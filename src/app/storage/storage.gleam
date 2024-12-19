import bucket
import bucket/put_object
import gleam/httpc
import gleam/io

pub fn upload_file(
  credentials: bucket.Credentials,
  bucket: String,
  key: String,
  body: BitArray,
) {
  io.debug(credentials)
  let response =
    put_object.request(bucket:, key:, body:)
    |> put_object.build(credentials)
    |> httpc.send_bits
  case response {
    Ok(response) -> {
      io.debug(put_object.response(response))
      Nil
    }
    Error(error) -> {
      Nil
    }
  }
}
