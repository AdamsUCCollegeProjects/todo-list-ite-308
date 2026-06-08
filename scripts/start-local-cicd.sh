#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PID_FILE="$REPO_ROOT/.local-deploy.pid"
LOG_FILE="$REPO_ROOT/.local-deploy.log"

usage() {
  cat <<'EOF'
Usage: ./scripts/start-local-cicd.sh [poll|stop|status]

  poll    Deploy now, then watch origin/main and auto-redeploy (default)
  stop    Stop the background poll watcher
  status  Show whether the watcher is running

After pushing to GitHub, wait ~10s and refresh http://localhost:8080
EOF
}

is_running() {
  [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

start_poll_watcher() {
  if is_running; then
    echo "Poll watcher already running (pid $(cat "$PID_FILE")). Log: $LOG_FILE"
    exit 0
  fi

  chmod +x "$SCRIPT_DIR/deploy-local.sh" "$SCRIPT_DIR/poll-deploy.sh"
  PULL_BEFORE_BUILD=1 "$SCRIPT_DIR/deploy-local.sh"

  nohup "$SCRIPT_DIR/poll-deploy.sh" >>"$LOG_FILE" 2>&1 &
  echo $! >"$PID_FILE"
  echo "Poll watcher started (pid $(cat "$PID_FILE"))."
  echo "Log: $LOG_FILE"
  echo "Push to main, then refresh http://localhost:8080"
}

stop_watcher() {
  if ! is_running; then
    echo "Poll watcher is not running."
    rm -f "$PID_FILE"
    exit 0
  fi

  kill "$(cat "$PID_FILE")"
  rm -f "$PID_FILE"
  echo "Poll watcher stopped."
}

show_status() {
  if is_running; then
    echo "Poll watcher running (pid $(cat "$PID_FILE"))."
    echo "Log: $LOG_FILE"
  else
    echo "Poll watcher not running."
    rm -f "$PID_FILE"
  fi
}

main() {
  case "${1:-poll}" in
    poll) start_poll_watcher ;;
    stop) stop_watcher ;;
    status) show_status ;;
    *) usage; exit 1 ;;
  esac
}

main "$@"
