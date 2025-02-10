import app/auth/auth_guards
import app/auth/auth_service
import app/auth/inputs/login_input
import app/common/response_utils
import app/common/valid
import app/types.{type Context}
import app/user/inputs/create_user_input
import app/user/outputs/user
import app/user/pages/create_user_page
import app/user/user_service
import gleam/http.{Delete, Post}
import gleam/json
import gleam/list
import gleam/option
import gleam/string_tree
import wisp.{type Request, type Response}

pub fn router(req: Request, ctx: Context, handle_request: fn() -> Response) {
  case wisp.path_segments(req), req.method {
    ["create-user"], http.Get ->
      create_user_page.create_user_page(option.None, False)
    ["create-user"], http.Post -> create_user(req, ctx)
    ["create-user-input", "validate", field], http.Post ->
      create_user_input_validate_field(req, field, ctx)
    ["api", "users"], Post -> post_api_users(req, ctx)
    ["api", "users", id], Delete -> delete_user(req, id, ctx)
    _, _ -> handle_request()
  }
}

fn post_api_users(req: Request, ctx: Context) {
  use json <- wisp.require_json(req)
  use input <- response_utils.or_decode_error(create_user_input.from_dynamic(
    json,
  ))

  use valided_input <- valid.or_bad_request_response(create_user_input.validate(
    input,
  ))

  use result <- response_utils.map_service_errors(user_service.create(
    valided_input,
    ctx,
  ))

  user.to_json(result)
  |> json.to_string_tree()
  |> wisp.json_response(201)
}

fn delete_user(req: Request, id: String, ctx: Context) {
  use payload <- auth_guards.require_jwt(req)
  case payload.sub == id {
    False -> response_utils.can_not_delete_other_user_response()
    True -> {
      use result <- response_utils.map_service_errors(user_service.delete_one(
        id,
        ctx,
      ))

      user.to_json(result)
      |> json.to_string_tree()
      |> wisp.json_response(200)
    }
  }
}

fn create_user(req: wisp.Request, ctx: Context) {
  use json <- wisp.require_json(req)
  use input <- response_utils.or_decode_error(create_user_input.from_dynamic(
    json,
  ))

  let input = create_user_input.validate(input)
  case input {
    Ok(input) -> {
      case user_service.create(input, ctx) {
        Ok(_) -> {
          use input <- response_utils.or_decode_error(login_input.from_dynamic(
            json,
          ))
          let assert Ok(input) = login_input.validate(input)
          let assert Ok(auth_tokens) = auth_service.login(input, ctx)

          wisp.ok()
          |> wisp.set_header("X-Access-Token", auth_tokens.access_token)
          |> wisp.set_header("X-Refresh-Token", auth_tokens.refresh_token)
          |> wisp.set_header("HX-Redirect", "/create-profile")
        }
        Error(response_utils.EmailAlreadyExistsError) ->
          create_user_page.create_user_page(
            option.Some(
              #(valid.inner(input), [#("email", "email already in use")]),
            ),
            True,
          )
        _ -> panic as "Something bad happened"
      }
    }
    Error(invalid) ->
      create_user_page.create_user_page(
        option.Some(valid.errors(invalid)),
        True,
      )
  }
}

fn create_user_input_validate_field(
  req: wisp.Request,
  field: String,
  ctx: Context,
) {
  use json <- wisp.require_json(req)
  use input <- response_utils.or_decode_error(create_user_input.from_dynamic(
    json,
  ))
  let validated_input = create_user_input.validate(input)
  let duplicate_email = case field == "email" {
    True -> {
      case user_service.find_one_from_email(input.email, ctx) {
        Error(response_utils.UserNotFoundError) -> []
        Ok(_) -> [#("email", "email already in use")]
        Error(_) -> panic as "Database error"
      }
    }
    False -> []
  }

  case validated_input {
    Ok(_) -> wisp.ok()
    Error(errors) -> {
      let #(_, errors) = valid.errors(errors)
      let error = case
        list.key_find([errors, duplicate_email] |> list.flatten, field)
      {
        Ok(error) -> error
        Error(_) -> ""
      }
      wisp.ok() |> wisp.string_tree_body(string_tree.from_string(error))
    }
  }
}
