# shellcheck shell=bash
# desc: system update, firmware check, base packages, universe repo
# default: yes

# Installed NVIDIA userspace/driver packages. Excludes linux-modules-nvidia-*: those are
# Ubuntu's signed prebuilt modules and must follow kernel updates, never be held.
nvidia_driver_pkgs() {
  dpkg-query -W -f='${Package} ${Status}\n' 2>/dev/null \
    | awk '$NF=="installed" && $1 ~ /^(nvidia-(driver|dkms|utils|compute-utils|kernel-common|kernel-source|firmware)-|libnvidia-|xserver-xorg-video-nvidia-)/ {print $1}'
}

gpu_driver_guard() {
  local pkgs; pkgs="$(nvidia_driver_pkgs)"
  [[ -z "$pkgs" ]] && return 0
  if [[ "${DEVENV_GPU_HOLD:-0}" == 1 ]]; then
    # shellcheck disable=SC2086
    sudo apt-mark hold $pkgs >/dev/null
    ok "NVIDIA driver packages on hold ($(wc -w <<<"$pkgs") pkgs) — undo: sudo apt-mark unhold \$(apt-mark showhold | grep nvidia)"
  elif [[ "${DEVENV_GPU:-0}" != 1 ]]; then
    info "existing NVIDIA driver found; dev_env won't install/replace it."
    info "note: system upgrades may still apply patch releases within its branch — to freeze it: ./install.sh --hold-gpu base"
  fi
}

run() {
  log "base — update system"
  apt_install software-properties-common ca-certificates curl wget gnupg lsb-release apt-transport-https
  if ! grep -rqsE '^(Components|deb).*universe' /etc/apt/sources.list /etc/apt/sources.list.d/; then
    sudo add-apt-repository -y universe
    apt_force_update
  fi
  gpu_driver_guard
  sudo apt-get full-upgrade -y -qq
  sudo apt-get autoremove -y -qq

  apt_install git stow unzip fontconfig

  if is_container; then info "container: skipping snap and firmware"; return 0; fi

  have snap && { sudo snap refresh >/dev/null 2>&1 || true; }
  apt_install fwupd
  sudo fwupdmgr refresh --force >/dev/null 2>&1 || true
  if sudo fwupdmgr get-updates >/dev/null 2>&1; then
    warn "firmware updates available — apply with: sudo fwupdmgr update  (may reboot)"
  else
    ok "firmware up to date (or nothing offered)"
  fi
}
