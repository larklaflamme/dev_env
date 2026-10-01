# syntax=docker/dockerfile:1
# Throwaway Ubuntu 24.04 to dry-run the installer before touching real hardware.
# Hardware/systemd modules (drivers, terminal, docker daemon, tweaks, hardening) skip
# themselves inside a container.   Usage: test/run.sh
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive TZ=America/Toronto
RUN apt-get update -qq && apt-get install -y -qq sudo curl git ca-certificates lsb-release pciutils locales \
 && locale-gen en_US.UTF-8 \
 && userdel -r ubuntu 2>/dev/null || true \
 && useradd -m -s /bin/bash dev \
 && echo 'dev ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/dev

ENV LANG=en_US.UTF-8
USER dev
WORKDIR /home/dev
COPY --chown=dev:dev . /home/dev/dev_env

# Optional GitHub token as a BuildKit secret (never stored in the image) to dodge API rate limits.
ARG MODULES=""
RUN --mount=type=secret,id=gh_token,uid=1000 \
    GITHUB_TOKEN="$(cat /run/secrets/gh_token 2>/dev/null || true)" DEVENV_NVIM_SYNC=0 \
    bash dev_env/install.sh $MODULES

CMD ["zsh", "-l"]
