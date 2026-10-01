# shellcheck shell=bash
# desc: Rust via rustup (stable + rust-analyzer), cargo-binstall and cargo dev tools
# default: yes

CARGO_TOOLS=(
  cargo-nextest    # faster, nicer test runner
  cargo-edit       # cargo add/rm/upgrade
  cargo-update     # cargo install-update -a
  cargo-audit      # RustSec advisories
  cargo-outdated
  cargo-expand     # see macro expansion
  bacon            # background checker / test watcher
)

run() {
  log "rust — rustup"
  if ! have rustup; then
    fetch --proto '=https' --tlsv1.2 https://sh.rustup.rs \
      | sh -s -- -y --no-modify-path --profile default --default-toolchain stable >/dev/null
    devenv_path
  else
    rustup self update >/dev/null 2>&1 || true
    rustup update stable --no-self-update >/dev/null
  fi
  rustup component add rust-analyzer rust-src clippy rustfmt >/dev/null
  ok "$(rustc --version)"

  log "rust — cargo-binstall + tools (prebuilt binaries, no compiling)"
  if ! have cargo-binstall; then
    fetch https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash >/dev/null
  fi
  local t
  for t in "${CARGO_TOOLS[@]}"; do
    if cargo binstall -y "$t" >/dev/null 2>&1; then ok "$t"; else warn "cargo binstall $t failed"; fi
  done

  # Opt-in faster linking with mold — written commented-out; uncomment to enable.
  write_if_missing "$HOME/.cargo/config.toml" <<'EOF'
# ~/.cargo/config.toml (created by dev_env; yours to edit)

# Faster incremental builds: link with mold via clang. Uncomment to enable.
# [target.x86_64-unknown-linux-gnu]
# linker = "clang"
# rustflags = ["-C", "link-arg=-fuse-ld=mold"]

[net]
git-fetch-with-cli = true   # use system git (SSH agent, credential helpers)
EOF
}
