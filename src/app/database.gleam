import sqlight.{type Connection}

pub fn init_schemas(connection: Connection) {
  let enable_foreign_keys_sql = "PRAGMA foreign_keys = ON;"
  let assert Ok(Nil) = sqlight.exec(enable_foreign_keys_sql, connection)

  let issues_sql =
    "CREATE TABLE IF NOT EXISTS issues (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    creator_id INTEGER NOT NULL)
    "
  let assert Ok(Nil) = sqlight.exec(issues_sql, connection)
  let user_sql =
    "CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL,
    password TEXT NOT NULL)
    "
  let assert Ok(Nil) = sqlight.exec(user_sql, connection)

  let refresh_token_sql =
    "CREATE TABLE IF NOT EXISTS refresh_tokens (
    token TEXT PRIMARY KEY,
    userId INTEGER NOT NULL,
    expiresAt TEXT NOT NULL)
    "
  let assert Ok(Nil) = sqlight.exec(refresh_token_sql, connection)

  let profile_sql =
    "
  CREATE TABLE IF NOT EXISTS profiles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
  )
  "
  let assert Ok(Nil) = sqlight.exec(profile_sql, connection)
}
