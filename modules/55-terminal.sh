# shellcheck shell=bash
# desc: Ghostty terminal (GPU-accelerated) via snap; skipped without a desktop
# default: yes

run() {
  log "terminal — Ghostty"
  if is_container || ! has_desktop; then info "no desktop session: skipping"; return 0; fi
  if have ghostty; then ok "ghostty already installed"; return 0; fi
  if have snap; then
    sudo snap install ghostty --classic
    ok "ghostty installed (config: ~/.config/ghostty/config)"
  else
    warn "snap unavailable; install Ghostty manually (https://ghostty.org) or keep GNOME Terminal"
  fi
}
