#!/usr/bin/env bash
# install.sh — provision an Ubuntu 24.04 dev machine. Safe to re-run.
#
#   ./install.sh                     run every default module, in order (NO GPU driver)
#   ./install.sh --gpu               ...and also install the NVIDIA driver
#   ./install.sh --hold-gpu base     freeze the current NVIDIA driver packages (apt-mark hold)
#   ./install.sh zsh python rust     run only these modules
#   ./install.sh --skip docker,hardening
#   ./install.sh --list              list modules and what they do
#
# Run as your normal user (not root); it calls sudo when needed.
# Interactive bits (git identity, SSH key, gh login) live in: devenv post
set -Eeuo pipefail

DEVENV_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DEVENV_ROOT
[[ -t 1 ]] && export DEVENV_COLOR=1
# shellcheck source=lib/common.sh
source "$DEVENV_ROOT/lib/common.sh"

DEVENV_RUN_ID="$(date +%Y%m%d-%H%M%S)"
export DEVENV_RUN_ID

# ---------- module discovery: modules/NN-name.sh, run in NN order ----------
module_files() { find "$DEVENV_ROOT/modules" -maxdepth 1 -name '[0-9][0-9]-*.sh' | sort; }
module_name()  { local b; b="$(basename "$1" .sh)"; echo "${b#[0-9][0-9]-}"; }
module_meta()  { sed -n "s/^# $2: //p" "$1" | head -1; }

list_modules() {
  local f
  printf '%-11s %-8s %s\n' MODULE DEFAULT DESCRIPTION
  while read -r f; do
    printf '%-11s %-8s %s\n' "$(module_name "$f")" "$(module_meta "$f" default || true)" "$(module_meta "$f" desc)"
  done < <(module_files)
}

usage() { sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; }

# ---------- args ----------
selected=() skip=","
while (($#)); do
  case "$1" in
    -l|--list) list_modules; exit 0 ;;
    -h|--help) usage; exit 0 ;;
    --gpu)     export DEVENV_GPU=1 ;;
    --hold-gpu) export DEVENV_GPU_HOLD=1 ;;   # apt-mark hold installed NVIDIA driver pkgs (base module)
    --skip)    skip+="${2:?--skip needs a comma list},"; shift ;;
    --skip=*)  skip+="${1#--skip=}," ;;
    -*)        die "unknown option: $1 (try --help)" ;;
    *)         selected+=("$1") ;;
  esac
  shift
done

if ((${#selected[@]} == 0)); then
  while read -r f; do
    m="$(module_name "$f")"
    # GPU driver is opt-in: only with --gpu (keeps a pre-installed driver untouched)
    if [[ "$m" == drivers && "${DEVENV_GPU:-0}" == 1 ]]; then selected+=("$m"); continue; fi
    [[ "$(module_meta "$f" default)" == no ]] && continue
    selected+=("$m")
  done < <(module_files)
elif [[ "${DEVENV_GPU:-0}" == 1 && " ${selected[*]} " != *" drivers "* ]]; then
  selected=(drivers "${selected[@]}")   # --gpu with an explicit list: driver first
fi
# Naming the module explicitly counts as opting in.
[[ " ${selected[*]} " == *" drivers "* ]] && export DEVENV_GPU=1

# ---------- preflight ----------
[[ $EUID -ne 0 ]] || die "run as your normal user, not root (sudo is used where needed)"
grep -q 'VERSION_ID="24.04"' /etc/os-release || warn "written for Ubuntu 24.04; continuing anyway"
have sudo || die "sudo is required"

mkdir -p "$DEVENV_STATE"
LOG="$DEVENV_STATE/install-$DEVENV_RUN_ID.log"
exec > >(tee -a "$LOG") 2>&1

cat <<'BANNER'

     _                                  
  __| | _____   __    ___ _ ____   __  
 / _` |/ _ \ \ / /   / _ \ '_ \ \ / /  
| (_| |  __/\ V /   |  __/ | | \ V /   
 \__,_|\___| \_/     \___|_| |_|\_/    Ubuntu 24.04 workstation bootstrap

BANNER
info "modules: ${selected[*]}"
if [[ "${DEVENV_GPU:-0}" != 1 ]]; then
  info "gpu:     NVIDIA driver will NOT be installed or upgraded (use --gpu to opt in)"
fi
info "log:     $LOG"

# Ask for sudo once and keep the ticket alive for the whole run.
sudo -v
( while kill -0 "$$" 2>/dev/null; do sudo -n true; sleep 50; done ) 2>/dev/null &
SUDO_KEEPALIVE=$!
trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null || true' EXIT

# Make our own scripts executable (exec bits can get lost when copied around).
chmod +x "$DEVENV_ROOT"/install.sh "$DEVENV_ROOT"/bootstrap.sh "$DEVENV_ROOT"/bin/* \
         "$DEVENV_ROOT"/lib/run-module.sh "$DEVENV_ROOT"/test/*.sh 2>/dev/null || true

# ---------- run ----------
declare -a done_ok=() done_fail=() done_skip=()
start=$SECONDS
for m in "${selected[@]}"; do
  if [[ "$skip" == *",$m,"* ]]; then done_skip+=("$m"); continue; fi
  t0=$SECONDS
  if bash "$DEVENV_ROOT/lib/run-module.sh" "$m"; then
    done_ok+=("$m"); dim "    ($m: $((SECONDS - t0))s)"
  else
    done_fail+=("$m"); err "module '$m' failed — continuing (re-run later: ./install.sh $m)"
  fi
done

# ---------- summary ----------
log "Summary  ($(( (SECONDS - start) / 60 ))m $(( (SECONDS - start) % 60 ))s)"
((${#done_ok[@]}))   && ok   "ok:      ${done_ok[*]}"
((${#done_skip[@]})) && info "skipped: ${done_skip[*]}"
((${#done_fail[@]})) && err  "failed:  ${done_fail[*]}   (details in $LOG)"

cat <<EOF

${C_B}Next:${C_0}
  1. Log out and back in   (login shell -> zsh, docker group)
  2. devenv post           (git identity, SSH key, GitHub login, commit signing)
  3. devenv doctor         (verify everything)
  4. Open Ghostty, run nvim once and let plugins install
EOF
[[ -f /var/run/reboot-required ]] && warn "a reboot is required (kernel/driver update)"
((${#done_fail[@]} == 0))
