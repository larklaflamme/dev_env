# shellcheck shell=bash
# desc: modern CLI tools (apt core + mise-managed binaries) and the fd/bat name fixes
# default: yes

run() {
  log "cli — apt packages"
  local pkgs tool
  mapfile -t pkgs < <(read_list "$DEVENV_ROOT/packages/apt-cli.txt")
  apt_install_best_effort "${pkgs[@]}"

  # Debian renames these two; give them their upstream names.
  mkdir -p "$HOME/.local/bin"
  have fdfind && ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  have batcat && ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"

  log "cli — mise (polyglot tool manager)"
  if ! have mise; then
    fetch https://mise.run | sh
    devenv_path
  fi
  mise --version | sed 's/^/    mise /'

  # Unauthenticated GitHub API = 60 req/h; reuse a token if one is around.
  if [[ -z "${GITHUB_TOKEN:-}" ]] && have gh && gh auth status >/dev/null 2>&1; then
    GITHUB_TOKEN="$(gh auth token)"; export GITHUB_TOKEN
  fi

  log "cli — mise tools (packages/mise-tools.txt)"
  while read -r tool; do
    [[ "$tool" == *@* ]] || tool="$tool@latest"
    mise_use_global "$tool"
  done < <(read_list "$DEVENV_ROOT/packages/mise-tools.txt")
  mise reshim >/dev/null 2>&1 || true

  # bat: build the theme/syntax cache once so the first `cat` is instant
  have bat && bat cache --build >/dev/null 2>&1 || true
  # tldr: fetch pages so `help <cmd>` works offline
  mise exec -- tldr --update >/dev/null 2>&1 || true
}
