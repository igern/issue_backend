import gleam/list
import gleam/option
import gleam/string
import sqlight

pub fn sqlight_string_optional(
  update: #(String, option.Option(String)),
) -> option.Option(#(String, sqlight.Value)) {
  case update.1 {
    option.Some(value) -> {
      let set = update.0 <> " = ?"
      let value = sqlight.text(value)
      option.Some(#(set, value))
    }
    option.None -> option.None
  }
}

pub fn sqlight_string_optional_null(
  update: #(String, option.Option(option.Option(String))),
) -> option.Option(#(String, sqlight.Value)) {
  case update.1 {
    option.Some(option.Some(value)) -> {
      let set = update.0 <> " = ?"
      let value = sqlight.text(value)
      option.Some(#(set, value))
    }
    option.Some(option.None) -> {
      let set = update.0 <> " = ?"
      let value = sqlight.null()
      option.Some(#(set, value))
    }
    option.None -> option.None
  }
}

pub fn sqlight_patch_helper(
  updates: List(option.Option(#(String, sqlight.Value))),
) {
  let updates =
    list.filter_map(updates, fn(update) {
      case update {
        option.Some(update) -> Ok(update)
        option.None -> Error(Nil)
      }
    })
  let set =
    list.map(updates, fn(update) { update.0 })
    |> string.join(", ")
  let values = list.map(updates, fn(update) { update.1 })
  case list.length(updates) > 0 {
    True -> Ok(#(set, values))
    False -> Error(Nil)
  }
}
