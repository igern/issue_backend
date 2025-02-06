import app/user/inputs/create_user_input
import gleam/bytes_tree
import gleam/list
import gleam/option
import lustre/attribute
import lustre/element
import lustre/element/html
import wisp

pub fn create_user(
  input: option.Option(
    #(create_user_input.CreateUserInput, List(#(String, String))),
  ),
) {
  let html =
    html.html([], [
      html.script([attribute.src("/static/script.js")], ""),
      html.script(
        [attribute.src("https://unpkg.com/@tailwindcss/browser@4")],
        "",
      ),
      html.script([attribute.src("https://unpkg.com/htmx.org@2.0.4")], ""),
      html.script(
        [attribute.src("https://unpkg.com/htmx.org/dist/ext/json-enc.js")],
        "",
      ),
      html.title([], "Opret Profil"),
      html.body([attribute.attribute("hx-boost", "true")], [
        html.div(
          [
            attribute.class(
              "h-screen flex flex-col justify-center items-center",
            ),
          ],
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
                ]),
                html.span([attribute.class("text-red-700")], [
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
                html.input([
                  attribute.class("border"),
                  attribute.type_("password"),
                  attribute.name("password"),
                ]),
                html.span([attribute.class("text-red-700")], [
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
                  attribute.class("cursor-pointer"),
                  attribute.type_("button"),
                  attribute.attribute("hx-post", "/create-user"),
                  attribute.attribute("hx-ext", "json-enc"),
                  attribute.attribute("hx-target", "body"),
                  attribute.attribute("hx-push-url", "true"),
                  attribute.value(case input {
                    option.Some(#(input, _)) -> input.password
                    option.None -> ""
                  }),
                ],
                [html.text("Opret Bruger")],
              ),
            ]),
          ],
        ),
      ]),
    ])

  wisp.response(200)
  |> wisp.set_body(
    html
    |> element.to_document_string_builder
    |> bytes_tree.from_string_tree
    |> wisp.Bytes,
  )
}
