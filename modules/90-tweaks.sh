# shellcheck shell=bash
# desc: dev-friendly kernel limits (inotify watchers), SSD trim, journal size cap
# default: yes

run() {
  log "tweaks — system limits for dev workloads"
  if is_container || ! has_systemd; then info "container/no systemd: skipping"; return 0; fi

  # IDEs, file watchers (vite, cargo-watch, nvim LSPs) and docker bind mounts burn
  # through the default 8k-ish inotify watches quickly.
  write_if_missing /etc/sysctl.d/60-devenv.conf sudo <<'EOF'
# dev_env: file watchers for IDEs/LSPs/bundlers
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024
# Let unprivileged users run perf for profiling
kernel.perf_event_paranoid = 1
EOF
  sudo sysctl --system >/dev/null
  ok "inotify + perf limits applied"

  sudo systemctl enable --now fstrim.timer >/dev/null 2>&1 && ok "weekly SSD trim enabled"

  write_if_missing /etc/systemd/journald.conf.d/60-devenv.conf sudo <<'EOF'
[Journal]
SystemMaxUse=1G
EOF
  sudo systemctl restart systemd-journald
  ok "journal capped at 1G"
}
