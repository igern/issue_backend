import bucket
import bucket/put_object
import gleam/httpc
import gleam/int
import gleam/option
import gleam/result

pub fn upload_file(
  credentials: bucket.Credentials,
  bucket: String,
  key: String,
  body: BitArray,
) {
  let path =
    credentials.host
    <> ":"
    <> credentials.port |> option.unwrap(9090) |> int.to_string
    <> "/"
    <> bucket
    <> "/"
    <> key
  let response =
    put_object.request(bucket:, key:, body:)
    |> put_object.build(credentials)
    |> httpc.send_bits
  response |> result.replace(path)
}
