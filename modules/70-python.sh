# shellcheck shell=bash
# desc: Miniconda3 (conda-forge channel, base not auto-activated) + uv, ruff, pre-commit
# default: yes
#
# Env knobs:
#   DEVENV_CONDA_PREFIX=~/miniconda3      install location
#   DEVENV_CONDA_DEFAULTS=1               keep Anaconda's 'defaults' channels (accepts their ToS)
#   DEVENV_CONDA_ENV="dev python=3.13"    also create a starter env (name + specs)

run() {
  local prefix="${DEVENV_CONDA_PREFIX:-$HOME/miniconda3}" arch installer conda

  log "python — Miniconda3"
  if [[ -x "$prefix/bin/conda" ]]; then
    ok "miniconda present at $prefix"
  else
    case "$(uname_arch)" in x86_64) arch=x86_64 ;; aarch64) arch=aarch64 ;; *) die "unsupported arch" ;; esac
    installer="$(mktemp --suffix=.sh)"
    fetch -o "$installer" "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-${arch}.sh"
    bash "$installer" -b -p "$prefix" >/dev/null
    rm -f "$installer"
    ok "installed -> $prefix"
  fi
  conda="$prefix/bin/conda"

  # Shell integration is done by our zsh/bash config (lazy-loaded), so we do NOT run
  # `conda init` — it would append a block to the stowed ~/.zshrc.
  "$conda" config --set auto_activate false 2>/dev/null \
    || "$conda" config --set auto_activate_base false
  "$conda" config --set changeps1 false          # starship shows the env instead
  "$conda" config --set solver libmamba 2>/dev/null || true

  if [[ "${DEVENV_CONDA_DEFAULTS:-0}" == 1 ]]; then
    local ch
    for ch in https://repo.anaconda.com/pkgs/main https://repo.anaconda.com/pkgs/r; do
      "$conda" tos accept --override-channels --channel "$ch" >/dev/null 2>&1 || true
    done
    info "using Anaconda 'defaults' channels (ToS accepted)"
  else
    # conda-forge only: community-built, no commercial-use terms, usually newer.
    "$conda" config --remove-key channels 2>/dev/null || true
    "$conda" config --add channels conda-forge
    "$conda" config --set channel_priority strict
    ok "channels: conda-forge (strict)"
  fi

  if [[ -n "${DEVENV_CONDA_ENV:-}" ]]; then
    # shellcheck disable=SC2086
    set -- $DEVENV_CONDA_ENV
    if "$conda" env list | awk '{print $1}' | grep -qx "$1"; then
      info "conda env '$1' exists"
    else
      local name="$1"; shift
      "$conda" create -y -q -n "$name" "$@" ipython pip
      ok "conda env '$name' created"
    fi
  fi

  log "python — uv (fast pip/venv/pipx replacement) + global tools"
  if ! have uv; then
    fetch https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh >/dev/null
    devenv_path
  fi
  ok "$(uv --version)"
  local t
  for t in ruff pre-commit ipython; do
    if uv tool install --quiet "$t" >/dev/null 2>&1; then ok "uv tool: $t"; else warn "uv tool install $t failed"; fi
  done
}
