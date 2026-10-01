# shellcheck shell=bash
# desc: zsh + oh-my-zsh + community plugins, set as login shell
# default: yes

run() {
  log "zsh — oh-my-zsh and plugins"
  have zsh || apt_install zsh

  local ZSH="$HOME/.oh-my-zsh"
  if [[ ! -d "$ZSH" ]]; then
    # --keep-zshrc: our stowed ~/.zshrc stays; CHSH/RUNZSH=no: we handle those ourselves.
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(fetch https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
  else
    info "oh-my-zsh present; updating"
    git -C "$ZSH" pull --ff-only --quiet || warn "oh-my-zsh update failed"
  fi

  local custom="${ZSH_CUSTOM:-$ZSH/custom}/plugins"
  mkdir -p "$custom"
  # name|repo — loaded from ~/.zshrc's plugins=() (zsh-completions goes on fpath instead)
  local p name repo
  for p in \
    "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions" \
    "zsh-completions|https://github.com/zsh-users/zsh-completions" \
    "fast-syntax-highlighting|https://github.com/zdharma-continuum/fast-syntax-highlighting" \
    "fzf-tab|https://github.com/Aloxaf/fzf-tab" \
    "you-should-use|https://github.com/MichaelAquilina/zsh-you-should-use" \
    "zsh-autopair|https://github.com/hlissner/zsh-autopair"; do
    name="${p%%|*}"; repo="${p#*|}"
    git_sync "$repo" "$custom/$name" && ok "$name"
  done

  # Login shell
  local zsh_path; zsh_path="$(command -v zsh)"
  if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$zsh_path" ]]; then
    sudo usermod -s "$zsh_path" "$USER"
    ok "login shell -> $zsh_path (takes effect at next login)"
  else
    ok "login shell already zsh"
  fi

  # Compile the completion dump on first interactive start; nothing else to do here.
  mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
}
