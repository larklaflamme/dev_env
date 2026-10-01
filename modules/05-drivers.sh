# shellcheck shell=bash
# desc: NVIDIA proprietary driver via ubuntu-drivers — OPT-IN: ./install.sh --gpu
# default: no
#
# Never replaces a driver that already works: if nvidia-smi responds, this module
# only reports the version and exits. Without --gpu, the base module also puts any
# installed NVIDIA driver packages on apt hold so upgrades can't change them.

run() {
  log "drivers — NVIDIA GPU driver (opt-in)"
  if is_container; then info "container: skipping"; return 0; fi
  if ! lspci 2>/dev/null | grep -qi nvidia; then info "no NVIDIA GPU detected, skipping"; return 0; fi

  if have nvidia-smi && nvidia-smi >/dev/null 2>&1; then
    ok "driver already working: $(nvidia-smi --query-gpu=name,driver_version --format=csv,noheader | sed -n 1p)"
    info "leaving it untouched (to change it: sudo ubuntu-drivers list / sudo apt install nvidia-driver-XXX)"
    return 0
  fi

  # Driver packages present but not loaded = usually just needs a reboot; don't stack another one.
  if dpkg -l 'nvidia-driver-*' 2>/dev/null | grep -q '^ii'; then
    warn "an NVIDIA driver package is installed but not loaded — reboot first, then re-check with nvidia-smi"
    dpkg -l 'nvidia-driver-*' | awk '/^ii/{print "    " $2, $3}'
    return 0
  fi

  apt_install ubuntu-drivers-common
  info "available drivers:"
  ubuntu-drivers devices 2>/dev/null | sed 's/^/    /' || true

  # Pin a specific branch with DEVENV_NVIDIA_DRIVER=nvidia-driver-570 (else Ubuntu's recommendation).
  if [[ -n "${DEVENV_NVIDIA_DRIVER:-}" ]]; then
    apt_install "$DEVENV_NVIDIA_DRIVER"
    ok "installed $DEVENV_NVIDIA_DRIVER"
  else
    sudo ubuntu-drivers install
    ok "installed Ubuntu's recommended driver"
  fi
  warn "reboot before nvidia-smi will work (Secure Boot may ask you to enrol a MOK key)"
}
