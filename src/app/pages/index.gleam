import gleam/bytes_tree
import lustre/attribute
import lustre/element
import lustre/element/html
import wisp

pub fn index() {
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
      html.title([], "Du er inde her"),
      html.body([], []),
    ])

  wisp.response(200)
  |> wisp.set_body(
    html
    |> element.to_document_string_builder
    |> bytes_tree.from_string_tree
    |> wisp.Bytes,
  )
}
