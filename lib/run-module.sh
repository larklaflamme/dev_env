#!/usr/bin/env bash
# lib/run-module.sh MODULE — run one module in its own process with strict mode.
# A failing module exits non-zero here without killing install.sh.
set -Eeuo pipefail

DEVENV_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
source "$DEVENV_ROOT/lib/common.sh"

name="${1:?module name required}"
file="$(compgen -G "$DEVENV_ROOT/modules/[0-9][0-9]-${name}.sh" | head -1 || true)"
[[ -n "$file" ]] || die "unknown module: $name"

trap 'err "module ${name}: line ${LINENO}: ${BASH_COMMAND}"' ERR
# shellcheck source=/dev/null
source "$file"
run
