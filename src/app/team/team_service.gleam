import app/common/response_utils.{DatabaseError, TeamNotFoundError}
import app/common/valid
import app/team/inputs/add_to_team_input.{type AddToTeamInput}
import app/team/inputs/create_team_input.{type CreateTeamInput}
import app/team/outputs/team
import app/team/outputs/team_profile.{TeamProfile}
import app/types
import gleam/dynamic/decode
import gleam/list
import sqlight
import youid/uuid

fn team_decoder() {
  use id <- decode.field(0, decode.string)
  use name <- decode.field(1, decode.string)
  use owner_id <- decode.field(2, decode.string)
  decode.success(#(id, name, owner_id))
}

fn team_profile_decoder() {
  use team_id <- decode.field(0, decode.string)
  use profile_id <- decode.field(1, decode.string)
  decode.success(#(team_id, profile_id))
}

pub fn create(
  input: valid.Valid(CreateTeamInput),
  owner_id: String,
  ctx: types.Context,
) {
  let input = valid.inner(input)
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
    Error(error) -> Error(DatabaseError(error))
    _ -> panic as "More than one row was returned from an insert."
  }
}

pub fn find_one(id: String, ctx: types.Context) {
  let sql = "select * from teams where id = ?"

  let result =
    sqlight.query(sql, ctx.connection, [sqlight.text(id)], team_decoder())

  case result {
    Ok([#(id, name, owner_id)]) -> Ok(team.Team(id, name, owner_id))
    Error(error) -> Error(DatabaseError(error))
    Ok([]) -> Error(TeamNotFoundError)
    _ -> panic as "More than one row was returned from an insert."
  }
}

pub fn delete_one(id: String, ctx: types.Context) {
  let sql = "delete from teams where id = ? returning *"

  let result =
    sqlight.query(sql, ctx.connection, [sqlight.text(id)], team_decoder())

  case result {
    Ok([#(id, name, owner_id)]) -> Ok(team.Team(id, name, owner_id))
    Error(error) -> Error(DatabaseError(error))
    Ok([]) -> Error(TeamNotFoundError)
    _ -> panic as "More than one row was returned from a delete."
  }
}

pub fn add_to_team(id: String, input: AddToTeamInput, ctx: types.Context) {
  let sql =
    "insert into team_profiles (team_id, profile_id) values (?, ?) returning *"

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [sqlight.text(id), sqlight.text(input.profile_id)],
      team_profile_decoder(),
    )

  case result {
    Ok([_]) -> Ok(Nil)
    Error(sqlight.SqlightError(sqlight.ConstraintForeignkey, _, _)) -> {
      Error(response_utils.ProfileNotFoundError)
    }
    Error(error) -> Error(DatabaseError(error))
    _ -> panic as "More than one row was returned from an insert."
  }
}

pub fn delete_from_team(team_id: String, profile_id: String, ctx: types.Context) {
  let sql =
    "delete from team_profiles where team_id = ? and profile_id = ? returning *"

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [sqlight.text(team_id), sqlight.text(profile_id)],
      team_profile_decoder(),
    )

  case result {
    Ok([_]) -> Ok(Nil)
    Ok([]) -> Error(response_utils.ProfileNotFoundError)
    Error(error) -> Error(DatabaseError(error))
    _ -> panic as "More than one row was returned from a delete."
  }
}

pub fn find_team_profiles_from_team(team_id: String, ctx: types.Context) {
  let sql = "select * from team_profiles where team_id = ?"

  let result =
    sqlight.query(
      sql,
      ctx.connection,
      [sqlight.text(team_id)],
      team_profile_decoder(),
    )

  case result {
    Ok(team_profiles) -> {
      let team_profiles =
        list.map(team_profiles, fn(team_profile) {
          let #(team_id, profile_id) = team_profile
          TeamProfile(team_id, profile_id)
        })
      Ok(team_profiles)
    }
    Error(error) -> Error(DatabaseError(error))
  }
}
