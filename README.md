# Todo List

A simple todo app served as static files with **nginx**.

## Run with Docker

```bash
docker build -t todo-list .
docker run -p 8080:80 todo-list
```

## Check if server is running on ngrok:
```
curl -sI http://localhost:8080/
```

Open http://localhost:8080

## Project layout

- `index.html` / `styles.css` — app
- `nginx/default.conf` — nginx server config (document root, caching for static assets)
- `Dockerfile` — nginx Alpine image with the config and static files
