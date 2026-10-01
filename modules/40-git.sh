# shellcheck shell=bash
# desc: latest git (git-core PPA), git-lfs, GitHub CLI
# default: yes

run() {
  log "git — git-core PPA + GitHub CLI"
  if ! grep -rqs "git-core/ppa" /etc/apt/sources.list.d/; then
    sudo add-apt-repository -y ppa:git-core/ppa
    apt_force_update
  fi

  if [[ ! -f /etc/apt/sources.list.d/github-cli.list ]]; then
    sudo install -m 0755 -d /etc/apt/keyrings
    fetch https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(deb_arch) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    apt_force_update
  fi

  apt_install git git-lfs gh
  # Make sure `git config --global` writes to ~/.gitconfig, never into the stowed
  # ~/.config/git/config (git would replace the symlink with a plain file).
  [[ -e "$HOME/.gitconfig" ]] || printf '# machine-local git config — see ~/.config/git/config for shared defaults\n' >"$HOME/.gitconfig"
  git lfs install --skip-repo >/dev/null
  ok "git $(git --version | awk '{print $3}'), gh $(gh --version | head -1 | awk '{print $3}')"
  info "identity, SSH key and signing: run  devenv post"
}
