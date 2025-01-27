import app/issue/outputs/issue.{type Issue}
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json

pub type PaginatedIssues {
  PaginatedIssues(total: Int, has_more: Bool, items: List(Issue))
}

pub fn decoder() -> decode.Decoder(PaginatedIssues) {
  use total <- decode.field("total", decode.int)
  use has_more <- decode.field("has_more", decode.bool)
  use items <- decode.field("items", decode.list(issue.decoder()))
  decode.success(PaginatedIssues(total:, has_more:, items:))
}

pub fn from_dynamic(json: Dynamic) {
  decode.run(json, decoder())
}

pub fn to_json(paginated_issues: PaginatedIssues) {
  json.object([
    #("total", json.int(paginated_issues.total)),
    #("has_more", json.bool(paginated_issues.has_more)),
    #("items", json.array(paginated_issues.items, issue.to_json)),
  ])
}
