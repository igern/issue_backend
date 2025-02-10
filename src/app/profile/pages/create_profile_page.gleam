import app/common/components/scaffold
import app/common/response_utils
import app/profile/inputs/create_profile_input
import gleam/list
import gleam/option
import lustre/attribute
import lustre/element/html

pub fn create_profile_page(
  input: option.Option(
    #(create_profile_input.CreateProfileInput, List(#(String, String))),
  ),
  autovalidate: Bool,
) {
  html.div(
    [attribute.class("h-screen flex flex-col justify-center items-center")],
    [
      html.form([attribute.class("flex flex-col gap-2 w-full max-w-sm")], [
        html.div([attribute.class("flex flex-col")], [
          html.label([], [html.text("Name")]),
          html.input(
            [
              [
                attribute.class("border"),
                attribute.name("name"),
                attribute.autofocus(True),
              ],
              case autovalidate {
                True -> [
                  attribute.attribute("hx-ext", "json-enc"),
                  attribute.attribute(
                    "hx-post",
                    "/create-profile-input/validate/name",
                  ),
                  attribute.attribute("hx-target", "next .error"),
                  attribute.attribute("hx-trigger", "change, keyup delay:200ms"),
                ]
                False -> []
              },
            ]
            |> list.flatten,
          ),
          html.span([attribute.class("error text-red-700")], [
            case input {
              option.Some(#(_, errors)) -> {
                case list.key_find(errors, "name") {
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
            attribute.attribute("hx-post", "/create-profile"),
            attribute.attribute("hx-ext", "json-enc"),
            attribute.attribute("hx-target", "body"),
            attribute.attribute("hx-push-url", "true"),
          ],
          [html.text("Create profile")],
        ),
      ]),
    ],
  )
  |> scaffold.scaffold
  |> response_utils.html
}
