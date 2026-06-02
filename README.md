# Todo List + Nextcloud Lab

This repository includes:
- a todo app Docker image (`Dockerfile`)
- a Docker Compose lab for **Nginx + Nextcloud + MariaDB** (`docker-compose.yml`)

## 1) Nginx + Nextcloud

Start the stack:

```bash
docker compose up -d
```

Services and URLs:

- Nextcloud via nginx reverse proxy: `http://localhost:8080`
- Nextcloud direct container port (bypasses nginx): `http://localhost:8081`

### Configure Nginx and Nextcloud

- Nginx reverse proxy config: `nextcloud-nginx/default.conf`
- Nextcloud app + DB config: `docker-compose.yml`

### Stop Nginx and test Nextcloud effect

```bash
docker compose stop nextcloud-nginx
```

Validation:

- `http://localhost:8080` should be unavailable (nginx path)
- `http://localhost:8081` should still work (direct Nextcloud container)

Start nginx again:

```bash
docker compose start nextcloud-nginx
```

### Upload and download file in Nextcloud

1. Open `http://localhost:8080` and finish first-time admin setup.
2. Upload a file from the Files page.
3. Download the same file to verify both operations.

## 2) Git/GitHub

Show git version:

```bash
git --version
```

Create a branch:

```bash
git checkout -b chore/nextcloud-nginx-setup
```

Push branch:

```bash
git push -u origin chore/nextcloud-nginx-setup
```

## 3) Docker

- `Dockerfile` runs the todo app with nginx.
- `docker-compose.yml` runs the Nextcloud lab (nextcloud + mariadb + nginx proxy).

## Project layout

- `index.html` / `styles.css` — todo app
- `nginx/default.conf` — nginx config for todo static files
- `Dockerfile` — todo app image (nginx Alpine)
- `docker-compose.yml` — multi-service setup
- `nextcloud-nginx/default.conf` — nginx reverse proxy for Nextcloud
