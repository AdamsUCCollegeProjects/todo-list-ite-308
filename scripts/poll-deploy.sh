#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPLOY_SCRIPT="$SCRIPT_DIR/deploy-local.sh"
LAST_DEPLOYED_FILE="$REPO_ROOT/.local-deploy.sha"
POLL_INTERVAL_SECONDS="${POLL_INTERVAL_SECONDS:-10}"
GIT_BRANCH="${GIT_BRANCH:-main}"
FETCH_MAX_ATTEMPTS="${FETCH_MAX_ATTEMPTS:-5}"

log() {
  printf '[poll] %s\n' "$*"
}

last_deployed_sha() {
  if [[ -f "$LAST_DEPLOYED_FILE" ]]; then
    tr -d '[:space:]' <"$LAST_DEPLOYED_FILE"
  fi
}

remote_sha() {
  git -C "$REPO_ROOT" rev-parse "origin/$GIT_BRANCH"
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

deploy_if_changed() {
  if ! fetch_with_retry; then
    log "Fetch failed; will retry on next poll"
    return 1
  fi

  local remote deployed
  remote="$(remote_sha)"
  deployed="$(last_deployed_sha)"

  if [[ "$remote" == "$deployed" ]]; then
    return 0
  fi

  log "New commit on origin/$GIT_BRANCH (${deployed:-none} -> $remote). Deploying..."
  PULL_BEFORE_BUILD=1 "$DEPLOY_SCRIPT" || return 1
}

main() {
  log "Watching origin/$GIT_BRANCH every ${POLL_INTERVAL_SECONDS}s"
  log "Last deployed: $(last_deployed_sha || echo none)"
  log "Push to GitHub, then refresh http://localhost:8080 (Ctrl+C to stop)"

  while true; do
    deploy_if_changed || log "Deploy failed; will retry on next poll"
    sleep "$POLL_INTERVAL_SECONDS"
  done
}

main "$@"
