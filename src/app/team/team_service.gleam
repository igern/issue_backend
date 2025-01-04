import app/common/response_utils
import app/team/inputs/create_team_input.{type CreateTeamInput}
import app/team/outputs/team
import app/types
import gleam/dynamic
import sqlight
import youid/uuid

fn team_decoder() {
  dynamic.tuple3(dynamic.string, dynamic.string, dynamic.string)
}

pub fn create(input: CreateTeamInput, owner_id: String, ctx: types.Context) {
  let sql =
    "insert into teams (id, name, owner_id) values (?, ?, ?) returning *"
  let id = uuid.v4_string()

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [sqlight.text(id), sqlight.text(input.name), sqlight.text(owner_id)],
      team_decoder(),
    )

  case result {
    Ok([#(id, name, owner_id)]) -> Ok(team.Team(id, name, owner_id))
    Error(sqlight.SqlightError(sqlight.ConstraintForeignkey, _, _)) ->
      Error(response_utils.ProfileNotFoundError)
    Error(error) -> Error(response_utils.DatabaseError(error))
    _ -> panic as "More than one row was returned from an insert."
  }
}
