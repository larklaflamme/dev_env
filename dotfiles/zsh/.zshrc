# ~/.zshrc — interactive zsh. Managed by dev_env (dotfiles/zsh/.zshrc).
#
#   ~/.zshrc.pre.local   machine-local, sourced first  (DEVENV_ALIASES, vi mode, ...)
#   ~/.config/zsh/*.zsh  the dev_env layer, in name order
#   ~/.zshrc.local       machine-local, sourced last   (tokens, overrides)
#
# Profile startup time:  DEVENV_PROFILE=1 zsh -i -c exit

[[ -n $DEVENV_PROFILE ]] && zmodload zsh/zprof
[[ -f ~/.zshrc.pre.local ]] && source ~/.zshrc.pre.local
: ${DEVENV_ALIASES:=all}
# The repo this file is symlinked from (~/.zshrc -> <repo>/dotfiles/zsh/.zshrc)
export DEVENV_ROOT="${${:-$HOME/.zshrc}:A:h:h:h}"

# ---------------------------------------------------------------- oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$ZSH/custom"
ZSH_THEME=""                                  # starship draws the prompt
ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"
zstyle ':omz:update' mode disabled            # `devenv update` handles updates
COMPLETION_WAITING_DOTS=true
HIST_STAMPS="yyyy-mm-dd"

# Extra completions: zsh-completions + whatever 20-tools.zsh generates
fpath=("$ZSH_CUSTOM/plugins/zsh-completions/src" "$XDG_DATA_HOME/zsh/site-functions" $fpath)

plugins=(
  git gh docker docker-compose rust golang npm python pip
  sudo                      # Esc Esc: prefix last command with sudo
  extract                   # `x anyarchive.tar.zst`
  copypath copyfile         # copy cwd / file contents to clipboard
  command-not-found         # suggest the apt package
  history-substring-search  # Up/Down search by what you've typed
  fzf-tab                   # fuzzy Tab completion (before autosuggest/highlighting)
  zsh-autopair
  you-should-use            # nags you when an alias exists for what you typed
  zsh-autosuggestions
  fast-syntax-highlighting  # must be last
)

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=40
YSU_MESSAGE_POSITION="after"

mkdir -p "$XDG_CACHE_HOME/zsh" "$XDG_DATA_HOME/zsh/site-functions"
if [[ -f $ZSH/oh-my-zsh.sh ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit && compinit -d "$ZSH_COMPDUMP"   # fallback: no oh-my-zsh yet
fi

# ---------------------------------------------------------------- dev_env layer
for _f in "$XDG_CONFIG_HOME"/zsh/*.zsh(N); do source "$_f"; done
unset _f

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
[[ -n $DEVENV_PROFILE ]] && zprof
true
