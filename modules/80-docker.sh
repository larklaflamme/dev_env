# shellcheck shell=bash
# desc: Docker Engine + Buildx + Compose v2 (official repo), log rotation, NVIDIA runtime if GPU
# default: yes

run() {
  log "docker — official Docker CE repository"
  if [[ ! -f /etc/apt/sources.list.d/docker.sources ]]; then
    # Remove distro packages that conflict with docker-ce
    local conflicts
    conflicts="$(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc \
      podman-docker containerd runc 2>/dev/null | awk '$2=="install"{print $1}' || true)"
    # shellcheck disable=SC2086
    [[ -n "$conflicts" ]] && sudo_apt remove -y -qq $conflicts

    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(deb_arch)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
    apt_force_update
  fi
  apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Sane daemon defaults: rotate container logs so they can't fill the disk.
  write_if_missing /etc/docker/daemon.json sudo <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" },
  "features": { "buildkit": true },
  "live-restore": true
}
EOF

  if ! id -nG "$USER" | grep -qw docker; then
    sudo usermod -aG docker "$USER"
    warn "added $USER to the docker group — log out/in (or: newgrp docker)"
  fi

  if is_container || ! has_systemd; then
    info "no systemd: not starting the daemon"; return 0
  fi
  sudo systemctl enable --now docker.service containerd.service >/dev/null 2>&1

  # GPU containers (docker run --gpus all ...). The toolkit never touches the driver itself;
  # install it when a driver already works, or when --gpu was given.
  if lspci 2>/dev/null | grep -qi nvidia \
     && { [[ "${DEVENV_GPU:-0}" == 1 ]] || { have nvidia-smi && nvidia-smi >/dev/null 2>&1; }; }; then
    log "docker — NVIDIA Container Toolkit"
    if [[ ! -f /etc/apt/sources.list.d/nvidia-container-toolkit.list ]]; then
      fetch https://nvidia.github.io/libnvidia-container/gpgkey \
        | sudo gpg --dearmor --yes -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
      fetch https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
        | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
        | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null
      apt_force_update
    fi
    apt_install nvidia-container-toolkit
    sudo nvidia-ctk runtime configure --runtime=docker >/dev/null
    ok "nvidia runtime configured (test after reboot: docker run --rm --gpus all ubuntu nvidia-smi)"
  fi

  sudo systemctl restart docker
  ok "$(docker --version)"
  ok "$(docker compose version)"
}
