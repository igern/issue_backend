import app/auth/outputs/jwt_payload.{type JwtPayload, JwtPayload}
import app/common/response_utils
import gleam/list
import gleam/string
import gwt
import wisp.{type Request, type Response}

pub fn jwt(req: Request, handle_request: fn(JwtPayload) -> Response) -> Response {
  use bearer_token <- response_utils.or_400(list.key_find(
    req.headers,
    "authorization",
  ))
  use #(_, token) <- response_utils.or_400(string.split_once(bearer_token, " "))

  case gwt.from_signed_string(token, "secret") {
    Ok(jwt) -> {
      let assert Ok(sub) = gwt.get_subject(jwt)
      let assert Ok(exp) = gwt.get_expiration(jwt)
      handle_request(JwtPayload(sub, exp))
    }
    _ -> wisp.bad_request()
  }
}
