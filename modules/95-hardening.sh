# shellcheck shell=bash
# desc: laptop baseline: ufw firewall (deny inbound), unattended security updates
# default: yes

run() {
  log "hardening — firewall and automatic security updates"
  if is_container || ! has_systemd; then info "container/no systemd: skipping"; return 0; fi

  apt_install ufw unattended-upgrades
  if ! sudo ufw status | grep -q "Status: active"; then
    sudo ufw default deny incoming >/dev/null
    sudo ufw default allow outgoing >/dev/null
    # sudo ufw allow ssh   # uncomment if you SSH *into* this laptop
    sudo ufw --force enable >/dev/null
  fi
  ok "ufw active (inbound denied)"
  info "note: Docker publishes ports via iptables and bypasses ufw — bind dev ports to 127.0.0.1:"
  info "      ports: [\"127.0.0.1:5432:5432\"]"

  echo 'unattended-upgrades unattended-upgrades/enable_auto_updates boolean true' | sudo debconf-set-selections
  sudo dpkg-reconfigure -f noninteractive unattended-upgrades >/dev/null
  ok "unattended security upgrades enabled"
}
