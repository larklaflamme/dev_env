# shellcheck shell=bash
# desc: Nerd Fonts (JetBrainsMono, FiraCode) for prompt/eza/nvim icons
# default: yes

run() {
  log "fonts — Nerd Fonts"
  have fc-cache || apt_install fontconfig
  local font dir tmp changed=0
  for font in JetBrainsMono FiraCode; do
    dir="$HOME/.local/share/fonts/${font}Nerd"
    if [[ -d "$dir" ]] && compgen -G "$dir/*.ttf" >/dev/null; then
      ok "$font Nerd Font already installed"; continue
    fi
    tmp="$(mktemp -d)"
    fetch -o "$tmp/$font.tar.xz" \
      "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font.tar.xz"
    mkdir -p "$dir"
    tar -xJf "$tmp/$font.tar.xz" -C "$dir"
    rm -rf "$tmp"
    ok "$font Nerd Font -> $dir"
    changed=1
  done
  ((changed)) && fc-cache -f >/dev/null
  return 0
}
