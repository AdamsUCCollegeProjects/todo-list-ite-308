#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPLOY_SCRIPT="$SCRIPT_DIR/deploy-local.sh"
POLL_INTERVAL_SECONDS="${POLL_INTERVAL_SECONDS:-10}"
GIT_BRANCH="${GIT_BRANCH:-main}"

log() {
  printf '[poll] %s\n' "$*"
}

remote_sha() {
  git -C "$REPO_ROOT" rev-parse "origin/$GIT_BRANCH"
}

local_sha() {
  git -C "$REPO_ROOT" rev-parse HEAD
}

fetch_remote() {
  git -C "$REPO_ROOT" fetch origin "$GIT_BRANCH" --quiet
}

deploy_if_changed() {
  fetch_remote
  local remote local_head
  remote="$(remote_sha)"
  local_head="$(local_sha)"

  if [[ "$remote" == "$local_head" ]]; then
    return
  fi

  log "New commit detected ($local_head -> $remote). Deploying..."
  PULL_BEFORE_BUILD=1 "$DEPLOY_SCRIPT" || return 1
}

main() {
  log "Watching origin/$GIT_BRANCH every ${POLL_INTERVAL_SECONDS}s"
  log "Push to GitHub, then refresh http://localhost:8080 (Ctrl+C to stop)"

  while true; do
    deploy_if_changed || log "Deploy failed; will retry on next poll"
    sleep "$POLL_INTERVAL_SECONDS"
  done
}

main "$@"
