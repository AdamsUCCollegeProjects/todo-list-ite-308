#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/docker-compose.local.yml"
CONTAINER_NAME="todo-list-local"
PULL_BEFORE_BUILD="${PULL_BEFORE_BUILD:-1}"

log() {
  printf '[deploy] %s\n' "$*"
}

pull_latest() {
  if [[ "$PULL_BEFORE_BUILD" != "1" ]]; then
    log "Skipping git pull (PULL_BEFORE_BUILD=$PULL_BEFORE_BUILD)"
    return
  fi

  log "Pulling latest from origin/main..."
  git -C "$REPO_ROOT" fetch origin main
  git -C "$REPO_ROOT" pull --ff-only origin main
}

rebuild_and_restart() {
  log "Building and restarting container on http://localhost:8080 ..."
  docker compose -f "$COMPOSE_FILE" build
  docker compose -f "$COMPOSE_FILE" up -d --force-recreate --remove-orphans
}

wait_for_nginx() {
  local attempt
  for attempt in $(seq 1 15); do
    if curl -sf "http://localhost:8080/" >/dev/null 2>&1; then
      log "App is live at http://localhost:8080"
      return
    fi
    sleep 1
  done
  log "Warning: container started but http://localhost:8080 did not respond yet"
}

main() {
  cd "$REPO_ROOT"
  pull_latest
  rebuild_and_restart
  wait_for_nginx
  log "Done. Refresh http://localhost:8080 to see changes."
}

main "$@"
