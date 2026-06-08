# Todo List

A simple todo app served as static files with **nginx**.

## Run with Docker through Nginx

Nginx only:

```bash
docker build -t todo-list .

# Build without cache:
docker build --no-cache --pull -t todo-list .

docker run -p 8080:80 todo-list
```

