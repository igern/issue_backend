import app/common/components/scaffold
import app/common/response_utils
import lustre/element/html

pub fn teams_page() {
  html.div([], [
    html.h1([], [
      html.text("DU ER LOGGET IND OG DU BØR KUNNE SE DINE TEAM HERUNDER"),
    ]),
  ])
  |> scaffold.scaffold()
  |> response_utils.html
}
