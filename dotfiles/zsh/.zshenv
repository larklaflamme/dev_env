# ~/.zshenv — read by EVERY zsh, including scripts. Keep it to PATH and env vars.
# Managed by dev_env (dotfiles/zsh/.zshenv).

# Ubuntu's /etc/zsh/zshrc runs compinit; oh-my-zsh runs it again. Skip the first one.
skip_global_compinit=1

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

typeset -U path PATH        # no duplicate entries, ever
path=(
  $HOME/.local/bin
  $HOME/.cargo/bin
  $HOME/go/bin
  /usr/local/go/bin
  $HOME/.local/share/mise/shims    # for non-interactive shells; interactive ones use `mise activate`
  $HOME/miniconda3/condabin        # the `conda` command only — envs are activated explicitly
  $path
)

export EDITOR=nvim VISUAL=nvim
export PAGER=less LESS='-R -F -i -j.3 --mouse'
(( $+commands[bat] )) && export MANPAGER="sh -c 'col -bx | bat -l man -p'" MANROFFOPT='-c'
export GOPATH="$HOME/go"
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"
export DOCKER_BUILDKIT=1
