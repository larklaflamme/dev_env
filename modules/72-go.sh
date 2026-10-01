# shellcheck shell=bash
# desc: Go latest stable (official tarball in /usr/local/go) + gopls, dlv, linters
# default: yes
#
# No version manager needed: since Go 1.21, a go.mod `toolchain` line makes the go
# command fetch the exact toolchain a project wants (GOTOOLCHAIN=auto).

GO_TOOLS=(
  golang.org/x/tools/gopls@latest              # language server
  github.com/go-delve/delve/cmd/dlv@latest     # debugger
  golang.org/x/tools/cmd/goimports@latest
  mvdan.cc/gofumpt@latest                      # stricter gofmt
  honnef.co/go/tools/cmd/staticcheck@latest
  golang.org/x/vuln/cmd/govulncheck@latest
)

run() {
  log "go — official toolchain"
  local latest current tmp
  latest="$(fetch 'https://go.dev/VERSION?m=text' | sed -n 1p)"        # e.g. go1.25.1
  [[ "$latest" == go1.* ]] || die "could not determine latest Go version (got: '$latest')"
  current="$(/usr/local/go/bin/go env GOVERSION 2>/dev/null || true)"

  if [[ "$current" == "$latest" ]]; then
    ok "$current is current"
  else
    tmp="$(mktemp -d)"
    fetch -o "$tmp/go.tgz" "https://go.dev/dl/${latest}.linux-$(deb_arch).tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "$tmp/go.tgz"
    rm -rf "$tmp"
    ok "go ${current:-none} -> $latest"
  fi
  devenv_path

  log "go — developer tools"
  local t
  for t in "${GO_TOOLS[@]}"; do
    if go install "$t" >/dev/null 2>&1; then ok "${t%@*}"; else warn "go install $t failed"; fi
  done

  # golangci-lint ships prebuilt binaries; upstream advises against `go install`.
  mise_use_global golangci-lint@latest
}
