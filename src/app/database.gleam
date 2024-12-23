import sqlight.{type Connection}

pub fn init_schemas(connection: Connection) {
  let enable_foreign_keys_sql = "PRAGMA foreign_keys = ON;"
  let assert Ok(Nil) = sqlight.exec(enable_foreign_keys_sql, connection)

  let issues_sql =
    "CREATE TABLE IF NOT EXISTS issues (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
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
  created_at TEXT NOT NULL)
  "
  let assert Ok(Nil) = sqlight.exec(directory_sql, connection)
}
