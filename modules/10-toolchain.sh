# shellcheck shell=bash
# desc: compilers, linkers, debuggers, build systems and -dev headers
# default: yes

run() {
  log "toolchain — compilers, debuggers, headers"
  local pkgs
  mapfile -t pkgs < <(read_list "$DEVENV_ROOT/packages/apt-toolchain.txt")
  apt_install_best_effort "${pkgs[@]}"
  ok "gcc $(gcc -dumpversion), clang $(clang --version | head -1 | grep -oE '[0-9]+\.[0-9.]+' | head -1)"
}
