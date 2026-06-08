const Database = require("better-sqlite3");
const crypto = require("crypto");
const path = require("path");
const fs = require("fs");

const DEFAULT_DB_PATH = "/data/todos.sqlite";
const dbPath = process.env.DB_PATH || DEFAULT_DB_PATH;

const dbDir = path.dirname(dbPath);
if (!fs.existsSync(dbDir)) {
  fs.mkdirSync(dbDir, { recursive: true });
}

const db = new Database(dbPath);

db.exec(`
  CREATE TABLE IF NOT EXISTS todos (
    id TEXT PRIMARY KEY,
    text TEXT NOT NULL,
    is_completed INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL
  )
`);

function rowToTodo(row) {
  return {
    id: row.id,
    text: row.text,
    isCompleted: Boolean(row.is_completed),
  };
}

function getAllTodos() {
  const rows = db
    .prepare(
      "SELECT id, text, is_completed FROM todos ORDER BY created_at DESC"
    )
    .all();
  return rows.map(rowToTodo);
}

function createTodo(text) {
  const id = crypto.randomUUID();
  const createdAt = new Date().toISOString();
  db.prepare(
    "INSERT INTO todos (id, text, is_completed, created_at) VALUES (?, ?, 0, ?)"
  ).run(id, text, createdAt);

  return { id, text, isCompleted: false };
}

function updateTodo(id, isCompleted) {
  const result = db
    .prepare("UPDATE todos SET is_completed = ? WHERE id = ?")
    .run(isCompleted ? 1 : 0, id);

  if (result.changes === 0) {
    return null;
  }

  const row = db
    .prepare("SELECT id, text, is_completed FROM todos WHERE id = ?")
    .get(id);
  return rowToTodo(row);
}

function deleteTodo(id) {
  const result = db.prepare("DELETE FROM todos WHERE id = ?").run(id);
  return result.changes > 0;
}

function deleteCompletedTodos() {
  const result = db
    .prepare("DELETE FROM todos WHERE is_completed = 1")
    .run();
  return result.changes;
}

module.exports = {
  getAllTodos,
  createTodo,
  updateTodo,
  deleteTodo,
  deleteCompletedTodos,
};
