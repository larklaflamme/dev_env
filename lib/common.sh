# shellcheck shell=bash
# lib/common.sh — shared helpers for install.sh, modules/*.sh and bin/devenv.
# Sourced, never executed.

DEVENV_ROOT="${DEVENV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DEVENV_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/devenv"
DEVENV_BACKUP_ROOT="$HOME/.dotfiles-backup"
export DEVENV_ROOT DEVENV_STATE
export DEBIAN_FRONTEND=noninteractive
export MISE_YES=1

# ---------- colours (only when the real terminal supports them) ----------
if [[ "${DEVENV_COLOR:-}" == 1 || -t 1 ]]; then
  C_B=$'\e[1;34m' C_G=$'\e[1;32m' C_Y=$'\e[1;33m' C_R=$'\e[1;31m' C_D=$'\e[2m' C_0=$'\e[0m'
else
  C_B='' C_G='' C_Y='' C_R='' C_D='' C_0=''
fi

log()  { printf '\n%s==>%s %s\n' "$C_B" "$C_0" "$*"; }
info() { printf '    %s\n' "$*"; }
ok()   { printf '    %s✓%s %s\n' "$C_G" "$C_0" "$*"; }
warn() { printf '%s[warn]%s %s\n' "$C_Y" "$C_0" "$*" >&2; }
err()  { printf '%s[fail]%s %s\n' "$C_R" "$C_0" "$*" >&2; }
die()  { err "$*"; exit 1; }
dim()  { printf '%s%s%s\n' "$C_D" "$*" "$C_0"; }

have() { command -v "$1" >/dev/null 2>&1; }

# Running inside Docker/Podman/LXC? (the test harness uses this to skip hardware/systemd steps)
is_container() {
  [[ -f /.dockerenv || -f /run/.containerenv ]] && return 0
  grep -qaE 'container=(docker|podman|lxc)' /proc/1/environ 2>/dev/null
}
has_systemd() { [[ -d /run/systemd/system ]]; }
has_desktop() { [[ -n "${XDG_CURRENT_DESKTOP:-}" ]] || have gnome-shell; }

deb_arch()   { dpkg --print-architecture; }   # amd64 | arm64
uname_arch() { uname -m; }                     # x86_64 | aarch64

# ---------- PATH: every location this kit installs into ----------
devenv_path() {
  local d
  for d in "$HOME/go/bin" /usr/local/go/bin "$HOME/.cargo/bin" \
           "$HOME/.local/share/mise/shims" "$HOME/.local/bin"; do
    case ":$PATH:" in *":$d:"*) ;; *) PATH="$d:$PATH" ;; esac
  done
  export PATH
}
devenv_path

# ---------- apt ----------
# sudo resets the environment, so DEBIAN_FRONTEND must be passed explicitly or
# debconf prompts (iperf3, wireshark, ...) hang the run. Keep existing config files.
sudo_apt() {
  sudo DEBIAN_FRONTEND=noninteractive apt-get \
    -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold "$@"
}

apt_update_once() {
  local stamp="${DEVENV_STATE}/apt-updated-${DEVENV_RUN_ID:-$$}"
  [[ -f "$stamp" ]] && return 0
  sudo_apt update -qq
  mkdir -p "$DEVENV_STATE" && touch "$stamp"
}
apt_force_update() { rm -f "${DEVENV_STATE}/apt-updated-${DEVENV_RUN_ID:-$$}"; apt_update_once; }

apt_install() {
  apt_update_once
  sudo_apt install -y -qq --no-install-recommends "$@"
}

# Bulk install; if that fails, retry one-by-one so a single missing package
# never blocks the rest.
apt_install_best_effort() {
  apt_update_once
  if sudo_apt install -y -qq --no-install-recommends "$@"; then return 0; fi
  warn "bulk apt install failed; retrying packages individually"
  local p failed=()
  for p in "$@"; do
    sudo_apt install -y -qq --no-install-recommends "$p" >/dev/null 2>&1 || failed+=("$p")
  done
  if ((${#failed[@]})); then warn "apt packages not installed: ${failed[*]}"; fi
  return 0
}

# Print a package-list file without comments or blank lines.
read_list() { sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$1"; }

# ---------- downloads ----------
fetch() { curl -fsSL --retry 3 --retry-delay 2 "$@"; }

# ---------- files ----------
# Write stdin to a file only if it doesn't exist yet (never clobbers your edits).
#   write_if_missing PATH [sudo] <<'EOF' ... EOF
write_if_missing() {
  local path="$1" use_sudo="${2:-}"
  if [[ -e "$path" ]]; then
    info "exists, left alone: $path"; cat >/dev/null; return 0
  fi
  if [[ "$use_sudo" == sudo ]]; then
    sudo mkdir -p "$(dirname "$path")"; sudo tee "$path" >/dev/null
  else
    mkdir -p "$(dirname "$path")"; cat >"$path"
  fi
  ok "wrote $path"
}

# Move an existing path into the timestamped backup dir, keeping its relative location.
backup_path() {
  local target="$1" rel dest
  rel="${target#"$HOME"/}"
  dest="$DEVENV_BACKUP_ROOT/${DEVENV_RUN_ID:-manual}/$rel"
  mkdir -p "$(dirname "$dest")"
  mv "$target" "$dest"
  info "backed up $target -> $dest"
}

# Insert or replace a marked block in a file (idempotent).
#   ensure_block FILE TAG <<'EOF' ... EOF
ensure_block() {
  local file="$1" tag="$2" begin end tmp body
  begin="# >>> ${tag} >>>"; end="# <<< ${tag} <<<"
  body="$(cat)"
  touch "$file"
  tmp="$(mktemp)"
  awk -v b="$begin" -v e="$end" '$0==b {skip=1; next} $0==e {skip=0; next} !skip {print}' "$file" >"$tmp"
  printf '%s\n%s\n%s\n' "$begin" "$body" "$end" >>"$tmp"
  cat "$tmp" >"$file"; rm -f "$tmp"
}

# ---------- git clone-or-pull ----------
git_sync() {
  local url="$1" dir="$2"
  if [[ -d "$dir/.git" ]]; then
    git -C "$dir" pull --ff-only --quiet || warn "could not update $dir"
  else
    git clone --depth 1 --quiet "$url" "$dir"
  fi
}

# ---------- mise ----------
# Install one tool globally. Never fatal: a renamed tool or a GitHub rate limit
# must not abort the whole run.
mise_use_global() {
  local spec="$1"
  if mise use -g --quiet "$spec" >/dev/null 2>&1; then ok "$spec"
  else warn "mise could not install $spec (rate-limited? export GITHUB_TOKEN and re-run)"; fi
}
