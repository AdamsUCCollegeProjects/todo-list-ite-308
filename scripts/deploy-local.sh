#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/docker-compose.local.yml"
LAST_DEPLOYED_FILE="$REPO_ROOT/.local-deploy.sha"
PULL_BEFORE_BUILD="${PULL_BEFORE_BUILD:-1}"
GIT_BRANCH="${GIT_BRANCH:-main}"
FETCH_MAX_ATTEMPTS="${FETCH_MAX_ATTEMPTS:-5}"

log() {
  printf '[deploy] %s\n' "$*"
}

fetch_with_retry() {
  local attempt
  for attempt in $(seq 1 "$FETCH_MAX_ATTEMPTS"); do
    if git -C "$REPO_ROOT" fetch origin "$GIT_BRANCH" --quiet 2>/dev/null; then
      return 0
    fi
    log "Fetch busy (attempt $attempt/$FETCH_MAX_ATTEMPTS), retrying..."
    sleep "$((attempt * 2))"
  done
  return 1
}

pull_latest() {
  if [[ "$PULL_BEFORE_BUILD" != "1" ]]; then
    log "Skipping git pull (PULL_BEFORE_BUILD=$PULL_BEFORE_BUILD)"
    return
  fi

  log "Pulling latest from origin/$GIT_BRANCH..."
  if ! fetch_with_retry; then
    log "Fetch failed; rebuilding from current local files"
    return
  fi

  git -C "$REPO_ROOT" pull --ff-only origin "$GIT_BRANCH"
}

record_deployed_sha() {
  git -C "$REPO_ROOT" rev-parse HEAD >"$LAST_DEPLOYED_FILE"
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
  record_deployed_sha
  log "Done. Refresh http://localhost:8080 to see changes."
}

main "$@"
