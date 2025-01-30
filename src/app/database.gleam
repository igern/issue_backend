import sqlight.{type Connection}

pub fn init_schemas(connection: Connection) {
  let enable_foreign_keys_sql = "PRAGMA foreign_keys = ON;"
  let assert Ok(Nil) = sqlight.exec(enable_foreign_keys_sql, connection)

  let issues_sql =
    "CREATE TABLE IF NOT EXISTS issues (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    creator_id TEXT NOT NULL,
    directory_id TEXT NOT NULL,
    FOREIGN KEY (directory_id) REFERENCES directories (id) ON DELETE CASCADE)
    "
  let assert Ok(Nil) = sqlight.exec(issues_sql, connection)
  let user_sql =
    "CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL,
    password TEXT NOT NULL)
    "
  let assert Ok(Nil) = sqlight.exec(user_sql, connection)

  let refresh_token_sql =
    "CREATE TABLE IF NOT EXISTS refresh_tokens (
    token TEXT PRIMARY KEY,
    userId TEXT NOT NULL,
    expiresAt TEXT NOT NULL)
    "
  let assert Ok(Nil) = sqlight.exec(refresh_token_sql, connection)

  let profile_sql =
    "
  CREATE TABLE IF NOT EXISTS profiles (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  profile_picture TEXT,
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
  )
  "
  let assert Ok(Nil) = sqlight.exec(profile_sql, connection)

  let directory_sql =
    "
  CREATE TABLE IF NOT EXISTS directories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  team_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (team_id) REFERENCES teams (id) ON DELETE CASCADE)
  "
  let assert Ok(Nil) = sqlight.exec(directory_sql, connection)

  let team_sql =
    "
  CREATE TABLE IF NOT EXISTS teams (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  owner_id TEXT NOT NULL,
  FOREIGN KEY (owner_id) REFERENCES profiles (id) ON DELETE CASCADE)
  "
  let assert Ok(Nil) = sqlight.exec(team_sql, connection)

  let team_profiles_sql =
    "
  CREATE TABLE IF NOT EXISTS team_profiles (
  team_id TEXT NOT NULL,
  profile_id TEXT NOT NULL,
  PRIMARY KEY (team_id, profile_id),
  FOREIGN KEY (team_id) REFERENCES teams (id) ON DELETE CASCADE,
  FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE
  )"

  let assert Ok(Nil) = sqlight.exec(team_profiles_sql, connection)
}
