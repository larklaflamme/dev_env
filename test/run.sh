#!/usr/bin/env bash
# test/run.sh — lint all scripts, then build the installer inside a clean Ubuntu 24.04 container.
#
#   test/run.sh               lint + full container install
#   test/run.sh lint          lint only (shellcheck + bash -n)
#   test/run.sh zsh cli       container install of just these modules
#
# Afterwards, poke around:  docker run --rm -it devenv-test
# Uses `gh auth token` (if logged in) as a build secret to avoid GitHub rate limits.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> lint"
scripts=(install.sh bootstrap.sh bin/devenv lib/*.sh modules/*.sh test/run.sh)   # bash 3 friendly (macOS)
for s in "${scripts[@]}"; do bash -n "$s"; done
if command -v shellcheck >/dev/null; then
  shellcheck -x -s bash -e SC1091 "${scripts[@]}"
  echo "    shellcheck clean"
fi
for z in dotfiles/zsh/.zshrc dotfiles/zsh/.zshenv dotfiles/zsh/.config/zsh/*.zsh; do
  command -v zsh >/dev/null && zsh -n "$z"
done
[[ "${1:-}" == lint ]] && exit 0

echo "==> container build"
secret_args=()
if command -v gh >/dev/null && gh auth token >/dev/null 2>&1; then
  tok="$(mktemp)"; gh auth token >"$tok"; trap 'rm -f "$tok"' EXIT
  secret_args=(--secret "id=gh_token,src=$tok")
fi
DOCKER_BUILDKIT=1 docker build --progress=plain ${secret_args[@]+"${secret_args[@]}"} \
  --build-arg MODULES="$*" -t devenv-test -f test/Dockerfile .
echo "==> ok — explore with: docker run --rm -it devenv-test"
