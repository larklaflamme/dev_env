# shellcheck shell=bash
# desc: Neovim latest stable (official build in /opt/nvim) + LazyVim starter
# default: yes

latest_nvim_tag() {
  # Follow the /releases/latest redirect — no GitHub API, no rate limit.
  curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/neovim/neovim/releases/latest | sed 's#.*/##'
}

run() {
  log "neovim — official stable build"
  local arch tag current tmp
  case "$(uname_arch)" in x86_64) arch=x86_64 ;; aarch64) arch=arm64 ;; *) die "unsupported arch" ;; esac
  tag="$(latest_nvim_tag)"
  [[ "$tag" == v* ]] || die "could not determine latest Neovim release (got: '$tag')"
  current="$( /opt/nvim/bin/nvim --version 2>/dev/null | head -1 | awk '{print $2}' || true)"

  if [[ -n "$current" && "$current" == "$tag" ]]; then
    ok "neovim $current is current"
  else
    tmp="$(mktemp -d)"
    fetch -o "$tmp/nvim.tar.gz" "https://github.com/neovim/neovim/releases/download/${tag}/nvim-linux-${arch}.tar.gz"
    sudo rm -rf /opt/nvim
    sudo mkdir -p /opt/nvim
    sudo tar -C /opt/nvim --strip-components=1 -xzf "$tmp/nvim.tar.gz"
    rm -rf "$tmp"
    ok "neovim ${current:-none} -> $tag"
  fi
  # On PATH for every shell, sudo and scripts
  sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim

  # Python provider so plugins needing pynvim work regardless of the active conda env
  if [[ ! -x "$HOME/.local/share/nvim-venv/bin/python" ]]; then
    python3 -m venv "$HOME/.local/share/nvim-venv"
    "$HOME/.local/share/nvim-venv/bin/pip" install -q pynvim
    ok "pynvim venv -> ~/.local/share/nvim-venv"
  fi

  if [[ -e "$HOME/.config/nvim" ]]; then
    info "~/.config/nvim exists; leaving your config alone"
  else
    git clone --depth 1 --quiet https://github.com/LazyVim/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
    # Tell nvim where the provider lives
    cat >>"$HOME/.config/nvim/lua/config/options.lua" <<'EOF'

-- dev_env: dedicated Python provider (independent of conda/uv envs)
vim.g.python3_host_prog = vim.fn.expand("~/.local/share/nvim-venv/bin/python")
EOF
    ok "LazyVim starter -> ~/.config/nvim (plugins install on first launch)"
  fi

  # Pre-install plugins headlessly so the first launch is instant (best effort).
  if [[ "${DEVENV_NVIM_SYNC:-1}" == 1 ]]; then
    timeout 300 nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 || info "plugin pre-sync skipped; they install on first launch"
  fi
}
