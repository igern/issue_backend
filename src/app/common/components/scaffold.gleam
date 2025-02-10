import lustre/attribute
import lustre/element/html
import lustre/internals/vdom

pub fn scaffold(child: vdom.Element(a)) -> vdom.Element(a) {
  html.html([], [
    html.script([attribute.src("/static/script.js")], ""),
    html.script([attribute.src("https://unpkg.com/@tailwindcss/browser@4")], ""),
    html.script([attribute.src("https://unpkg.com/htmx.org@2.0.4")], ""),
    html.script(
      [attribute.src("https://unpkg.com/htmx.org/dist/ext/json-enc.js")],
      "",
    ),
    html.title([], "Opret Profil"),
    html.body([attribute.attribute("hx-boost", "true")], [child]),
  ])
}
