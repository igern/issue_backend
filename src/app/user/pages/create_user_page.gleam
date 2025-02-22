import app/common/components/scaffold
import app/common/response_utils
import app/user/inputs/create_user_input
import gleam/list
import gleam/option
import lustre/attribute
import lustre/element/html

pub fn create_user_page(
  input: option.Option(
    #(create_user_input.CreateUserInput, List(#(String, String))),
  ),
  autovalidate: Bool,
) {
  html.div(
    [attribute.class("h-screen flex flex-col justify-center items-center")],
    [
      html.form([attribute.class("flex flex-col gap-2 w-full max-w-sm")], [
        html.div([attribute.class("flex flex-col")], [
          html.label([], [html.text("Email")]),
          html.input([
            attribute.class("border"),
            attribute.type_("email"),
            attribute.name("email"),
            attribute.autofocus(True),
            attribute.value(case input {
              option.Some(#(input, _)) -> input.email
              option.None -> ""
            }),
            attribute.attribute("hx-ext", "json-enc"),
            case autovalidate {
              True ->
                attribute.attribute(
                  "hx-post",
                  "/create-user-input/validate/email",
                )
              False -> attribute.none()
            },
            case autovalidate {
              True -> attribute.attribute("hx-target", "next .error")
              False -> attribute.none()
            },
            case autovalidate {
              True ->
                attribute.attribute(
                  "hx-trigger",
                  "change, keyup delay:200ms changed",
                )
              False -> attribute.none()
            },
          ]),
          html.span([attribute.class("error text-red-700")], [
            case input {
              option.Some(#(_, errors)) -> {
                case list.key_find(errors, "email") {
                  Ok(error) -> html.text(error)
                  Error(_) -> html.text("")
                }
              }
              option.None -> html.text("")
            },
          ]),
        ]),
        html.div([attribute.class("flex flex-col")], [
          html.label([], [html.text("Password")]),
          html.input(
            [
              [
                attribute.class("border"),
                attribute.type_("password"),
                attribute.name("password"),
              ],
              case autovalidate {
                True -> [
                  attribute.attribute("hx-ext", "json-enc"),
                  attribute.attribute(
                    "hx-post",
                    "/create-user-input/validate/password",
                  ),
                  attribute.attribute("hx-target", "next .error"),
                  attribute.attribute(
                    "hx-trigger",
                    "change, keyup delay:200ms changed",
                  ),
                ]
                False -> []
              },
            ]
            |> list.flatten,
          ),
          html.span([attribute.class("error text-red-700")], [
            case input {
              option.Some(#(_, errors)) -> {
                case list.key_find(errors, "password") {
                  Ok(error) -> html.text(error)
                  Error(_) -> html.text("")
                }
              }
              option.None -> html.text("")
            },
          ]),
        ]),
        html.button(
          [
            attribute.class("cursor-pointer border"),
            attribute.type_("button"),
            attribute.attribute("hx-post", "/create-user"),
            attribute.attribute("hx-ext", "json-enc"),
            attribute.attribute("hx-target", "body"),
            attribute.attribute("hx-push-url", "true"),
          ],
          [html.text("Create user")],
        ),
      ]),
    ],
  )
  |> scaffold.scaffold()
  |> response_utils.html
}
