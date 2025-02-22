import app/common/components/scaffold
import app/common/response_utils
import gleam/bytes_tree
import lustre/attribute
import lustre/element
import lustre/element/html
import wisp

pub fn login_page() {
  let html =
    html.div([], [
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
    ])
    |> scaffold.scaffold
    |> response_utils.html
}
