const express = require("express");
const path = require("path");
const db = require("./db");

const PORT = Number(process.env.PORT) || 3000;
const PUBLIC_DIR = path.join(__dirname, "public");

const app = express();

app.use(express.json());
app.use(express.static(PUBLIC_DIR));

app.get("/api/todos", (_request, response) => {
  response.json(db.getAllTodos());
});

app.post("/api/todos", (request, response) => {
  const text = typeof request.body.text === "string" ? request.body.text.trim() : "";

  if (!text) {
    response.status(400).json({ error: "text is required" });
    return;
  }

  response.status(201).json(db.createTodo(text));
});

app.patch("/api/todos/:id", (request, response) => {
  const { isCompleted } = request.body;

  if (typeof isCompleted !== "boolean") {
    response.status(400).json({ error: "isCompleted must be a boolean" });
    return;
  }

  const updated = db.updateTodo(request.params.id, isCompleted);

  if (!updated) {
    response.status(404).json({ error: "todo not found" });
    return;
  }

  response.json(updated);
});

app.delete("/api/todos/completed", (_request, response) => {
  const deletedCount = db.deleteCompletedTodos();
  response.json({ deletedCount });
});

app.delete("/api/todos/:id", (request, response) => {
  const wasDeleted = db.deleteTodo(request.params.id);

  if (!wasDeleted) {
    response.status(404).json({ error: "todo not found" });
    return;
  }

  response.status(204).send();
});

app.listen(PORT, () => {
  console.log(`Todo app listening on port ${PORT}`);
});
