#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RUNNER_DIR="$REPO_ROOT/actions-runner"
RUNNER_VERSION="${RUNNER_VERSION:-2.334.0}"
RUNNER_ARCH="${RUNNER_ARCH:-arm64}"

repo_url() {
  git -C "$REPO_ROOT" config --get remote.origin.url
}

download_runner() {
  local archive="actions-runner-osx-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"
  local url="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${archive}"

  mkdir -p "$RUNNER_DIR"
  curl -fsSL "$url" -o "/tmp/${archive}"
  tar xzf "/tmp/${archive}" -C "$RUNNER_DIR"
  rm "/tmp/${archive}"
}

configure_runner() {
  local token repo
  repo="$(repo_url)"
  printf 'Paste the registration token from GitHub (Settings → Actions → Runners → New): '
  read -r token

  cd "$RUNNER_DIR"
  ./config.sh \
    --url "$repo" \
    --token "$token" \
    --name "localhost-$(hostname -s)" \
    --work "_work" \
    --unattended false
}

main() {
  echo "GitHub Actions self-hosted runner setup"
  echo "Repository: $(repo_url)"
  echo "Install dir: $RUNNER_DIR"
  echo

  if [[ ! -x "$RUNNER_DIR/config.sh" ]]; then
    echo "Downloading runner v${RUNNER_VERSION} (${RUNNER_ARCH})..."
    download_runner
  fi

  configure_runner
  echo
  echo "Start the runner with:"
  echo "  cd actions-runner && ./run.sh"
  echo
  echo "Then push to main — the deploy-localhost workflow rebuilds http://localhost:8080"
}

main "$@"
