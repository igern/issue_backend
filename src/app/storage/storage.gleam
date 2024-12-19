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
  let response =
    put_object.request(bucket:, key:, body:)
    |> put_object.build(credentials)
    |> httpc.send_bits
  case response {
    Ok(response) -> {
      Nil
    }
    Error(error) -> {
      Nil
    }
  }
}
