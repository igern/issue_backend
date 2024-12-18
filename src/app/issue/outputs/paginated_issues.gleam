import app/issue/outputs/issue.{type Issue}
import gleam/dynamic.{type Dynamic}
import gleam/json

pub type PaginatedIssues {
  PaginatedIssues(total: Int, has_more: Bool, items: List(Issue))
}

pub fn decoder() {
  dynamic.decode3(
    PaginatedIssues,
    dynamic.field("total", dynamic.int),
    dynamic.field("has_more", dynamic.bool),
    dynamic.field("items", dynamic.list(issue.decoder())),
  )
}

pub fn from_dynamic(json: Dynamic) {
  json |> decoder()
}

pub fn to_json(paginated_issues: PaginatedIssues) {
  json.object([
    #("total", json.int(paginated_issues.total)),
    #("has_more", json.bool(paginated_issues.has_more)),
    #("items", json.array(paginated_issues.items, issue.to_json)),
  ])
}
