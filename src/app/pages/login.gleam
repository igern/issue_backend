import gleam/bytes_tree
import lustre/attribute
import lustre/element
import lustre/element/html
import wisp

pub fn login() {
  let html =
    html.html([], [
      html.script(
        [attribute.src("https://unpkg.com/@tailwindcss/browser@4")],
        "",
      ),
      html.style(
        [attribute.type_("text/tailwindcss")],
        "@theme {        --color-clifford: #da373d;      }",
      ),
      html.script([attribute.src("https://unpkg.com/htmx.org@2.0.4")], ""),
      html.script(
        [attribute.src("https://unpkg.com/htmx.org/dist/ext/json-enc.js")],
        "",
      ),
      html.title([], "Hello there"),
      html.body([], [
        html.form([attribute.class("gap-2")], [
          html.input([
            attribute.type_("text"),
            attribute.name("email"),
            attribute.class("border"),
          ]),
          html.input([
            attribute.type_("password"),
            attribute.name("password"),
            attribute.class("border"),
          ]),
          html.button(
            [
              attribute.type_("submit"),
              attribute.attribute("hx-post", "/api/auth/login"),
              attribute.attribute("hx-ext", "json-enc"),
            ],
            [html.text("Login")],
          ),
        ]),
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
