# Todo List

A simple todo app served as static files with **nginx**.

## Run with Docker through Nginx

```bash
docker build -t todo-list .
docker run -p 8080:80 todo-list
```

Open **[http://localhost:8080](http://localhost:8080)** (the app is served over HTTP on port 8080).

## Localhost auto-deploy (no manual `git pull`)

Push to `main` on GitHub, wait a few seconds, then refresh **[http://localhost:8080](http://localhost:8080)**.

### Option A — Poll watcher (easiest)

One command starts the app and watches GitHub for new commits:

```bash
chmod +x scripts/*.sh
./scripts/start-local-cicd.sh
```

This will:

1. `git pull` and rebuild the Docker container on port 8080
2. Poll `origin/main` every 10 seconds and redeploy when you push

Useful commands:

```bash
./scripts/start-local-cicd.sh status   # is the watcher running?
./scripts/start-local-cicd.sh stop     # stop the watcher
tail -f .local-deploy.log              # watch deploy output
```

Manual one-off deploy:

```bash
./scripts/deploy-local.sh
```

### Option B — GitHub Actions self-hosted runner (CI/CD)

For deploy-on-push via GitHub Actions on your Mac:

```bash
./scripts/setup-self-hosted-runner.sh
cd actions-runner && ./run.sh
```

Keep the runner terminal open. Each push to `main` runs `.github/workflows/deploy-localhost.yml`, which rebuilds and restarts the container on **[http://localhost:8080](http://localhost:8080)**.

## Notes

- Port **8080** is used by the todo app (`docker-compose.local.yml`). The Nextcloud stack in `docker-compose.yml` also maps 8080 — do not run both at once.
- Poll interval defaults to 30s. Override with `POLL_INTERVAL_SECONDS=15 ./scripts/poll-deploy.sh`.

