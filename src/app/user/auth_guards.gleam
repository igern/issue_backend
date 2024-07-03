import app/common/response_utils
import gleam/list
import gleam/string
import gwt
import wisp.{type Request, type Response}

pub fn jwt(req: Request, handle_request: fn() -> Response) {
  use <- extract_jwt(req)
  handle_request()
}

fn extract_jwt(req: Request, handle_request: fn() -> Response) -> Response {
  use bearer_token <- response_utils.or_400(list.key_find(
    req.headers,
    "authorization",
  ))
  use #(_, token) <- response_utils.or_400(string.split_once(bearer_token, " "))

  case gwt.from_signed_string(token, "secret") {
    Ok(_) -> handle_request()
    _ -> wisp.bad_request()
  }
}
