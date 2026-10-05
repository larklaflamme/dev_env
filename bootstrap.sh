#!/usr/bin/env bash
# bootstrap.sh — zero-to-installed on a fresh Ubuntu 24.04 box.
#
# Fresh machine (nothing installed yet, not even git):
#   curl -fsSL https://raw.githubusercontent.com/<you>/dev_env/main/bootstrap.sh | bash
#   (or copy this file over and: bash bootstrap.sh)
#
# Inside an existing clone it simply hands off to ./install.sh.
#
# Env overrides:
#   DEVENV_REPO   git URL of this repo   (default below — change it to yours)
#   DEVENV_DIR    where to clone it      (default ~/dev_env)
#   any args are passed through to install.sh  (e.g. --skip drivers)
set -euo pipefail

DEVENV_REPO="${DEVENV_REPO:-https://github.com/ki11erc0der/dev_env.git}"
DEVENV_DIR="${DEVENV_DIR:-$HOME/dev_env}"

here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [[ -n "$here" && -f "$here/install.sh" && -d "$here/modules" ]]; then
  exec bash "$here/install.sh" "$@"
fi

echo "==> installing git + curl"
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq git curl ca-certificates

if [[ -d "$DEVENV_DIR/.git" ]]; then
  echo "==> updating $DEVENV_DIR"
  git -C "$DEVENV_DIR" pull --ff-only
else
  echo "==> cloning $DEVENV_REPO -> $DEVENV_DIR"
  git clone "$DEVENV_REPO" "$DEVENV_DIR"
fi

# When piped from curl, stdin is the script itself; give install.sh the terminal.
if [[ -t 0 ]]; then
  exec bash "$DEVENV_DIR/install.sh" "$@"
else
  exec bash "$DEVENV_DIR/install.sh" "$@" </dev/tty
fi
