# shellcheck shell=bash
# desc: symlink dotfiles/ into $HOME with GNU stow (existing files are backed up)
# default: yes

run() {
  log "dotfiles — stow dotfiles/* into \$HOME"
  have stow || apt_install stow

  local dir="$DEVENV_ROOT/dotfiles" pkgdir pkg f rel target
  for pkgdir in "$dir"/*/; do
    pkg="$(basename "$pkgdir")"
    # Anything already at a target path that isn't our symlink gets moved aside first,
    # so stow never refuses and nothing is ever lost.
    while IFS= read -r -d '' f; do
      rel="${f#"$dir/$pkg/"}"
      target="$HOME/$rel"
      if [[ -L "$target" && "$(readlink -f "$target")" == "$(readlink -f "$f")" ]]; then
        continue
      elif [[ -e "$target" || -L "$target" ]]; then
        backup_path "$target"
      fi
    done < <(find "$dir/$pkg" -type f -print0)
    # --no-folding: real directories, per-file symlinks, so apps writing new files
    # into ~/.config/<app>/ don't end up writing into this repo.
    stow --no-folding --restow --dir "$dir" --target "$HOME" "$pkg"
    ok "$pkg"
  done

  # ---- the `devenv` helper command ----
  mkdir -p "$HOME/.local/bin"
  chmod +x "$DEVENV_ROOT/bin/devenv"
  ln -sf "$DEVENV_ROOT/bin/devenv" "$HOME/.local/bin/devenv"
  ok "devenv -> ~/.local/bin/devenv"

  # ---- machine-local files (never committed) ----
  # `git config --global` writes here, so it never rewrites the stowed ~/.config/git/config.
  write_if_missing "$HOME/.gitconfig" <<'EOF'
# ~/.gitconfig — machine-local: identity, signing key, credential helpers.
# Shared defaults live in ~/.config/git/config (from the dev_env repo).
# Fill in with: devenv post
EOF

  write_if_missing "$HOME/.zshrc.pre.local" <<'EOF'
# ~/.zshrc.pre.local — machine-specific, sourced FIRST by ~/.zshrc. Not in git.

# Which classic commands get replaced by modern ones (see: devenv aliases)
#   all  - drop-ins plus grep->rg, find->fd, sed->sd, du->dust, df->duf,
#          ps->procs, dig->doggo, ping->gping, diff->delta
#   safe - only drop-ins: ls/tree->eza, cat->bat, cd->zoxide, top/htop->btop, vim->nvim
#   none - nothing overridden; new tools only under their own names
# The original is always one keystroke away:  \grep ...   or   command grep ...
export DEVENV_ALIASES=all

# Vi keys at the prompt? (default emacs)
# export DEVENV_VI_MODE=1
EOF

  write_if_missing "$HOME/.zshrc.local" <<'EOF'
# ~/.zshrc.local — machine-specific, sourced LAST by ~/.zshrc. Not in git.
# Put tokens, work proxies, extra PATH entries and overrides here.
# export GITHUB_TOKEN=...
EOF

  # bash keeps Ubuntu's default ~/.bashrc and just sources our layer.
  ensure_block "$HOME/.bashrc" "dev_env" <<'EOF'
[ -f "$HOME/.config/bash/devenv.bash" ] && . "$HOME/.config/bash/devenv.bash"
EOF
  ok "~/.bashrc sources ~/.config/bash/devenv.bash"
}
