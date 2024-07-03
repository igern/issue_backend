import sqlight.{type Connection}

pub fn init_schemas(connection: Connection) {
  let issues_sql =
    "CREATE TABLE IF NOT EXISTS issues (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL)
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
    userId TEXT NOT NULL,
    expiresAt TEXT NOT NULL)
    "
  let assert Ok(Nil) = sqlight.exec(refresh_token_sql, connection)
}
