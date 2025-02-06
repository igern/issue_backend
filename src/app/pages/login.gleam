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
              attribute.attribute("hx-post", "/login"),
              attribute.attribute("hx-ext", "json-enc"),
              attribute.attribute("hx-target", "body"),
              attribute.attribute("hx-push-url", "true"),
            ],
            [html.text("Login")],
          ),
        ]),
        html.a(
          [
            attribute.attribute("hx-boost", "true"),
            attribute.href("/create-user"),
          ],
          [html.text("Opret Profil")],
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
