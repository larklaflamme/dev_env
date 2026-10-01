# shellcheck shell=bash
# desc: Node.js LTS + pnpm + bun via mise (per-project versions via mise.toml / .nvmrc)
# default: yes

NPM_GLOBALS=(typescript tsx npm-check-updates)

run() {
  log "node — LTS via mise"
  have mise || die "mise missing; run: ./install.sh cli"
  mise settings set idiomatic_version_file_enable_tools node >/dev/null 2>&1 || true  # honour .nvmrc/.node-version
  mise_use_global node@lts
  mise_use_global pnpm@latest
  mise_use_global bun@latest
  mise reshim >/dev/null 2>&1 || true
  ok "node $(mise exec -- node --version), npm $(mise exec -- npm --version)"

  local p
  for p in "${NPM_GLOBALS[@]}"; do
    if mise exec -- npm install -g --silent "$p" >/dev/null 2>&1; then ok "npm -g $p"; else warn "npm -g $p failed"; fi
  done
  mise reshim >/dev/null 2>&1 || true
}
