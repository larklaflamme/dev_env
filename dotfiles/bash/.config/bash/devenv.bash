# ~/.config/bash/devenv.bash — dev_env layer for bash (zsh is the main shell;
# this keeps bash pleasant for scripts, sudo -i, recovery and muscle memory).
# Sourced from a marked block at the end of Ubuntu's default ~/.bashrc.

# --- PATH (no duplicates) ------------------------------------
for _d in "$HOME/miniconda3/condabin" "$HOME/.local/share/mise/shims" /usr/local/go/bin \
          "$HOME/go/bin" "$HOME/.cargo/bin" "$HOME/.local/bin"; do
  case ":$PATH:" in *":$_d:"*) ;; *) PATH="$_d:$PATH" ;; esac
done
unset _d
export PATH GOPATH="$HOME/go" RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"

case $- in *i*) ;; *) return ;; esac   # the rest is for interactive shells only

# --- Editor --------------------------------------------------
if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim VISUAL=nvim
  alias vim='nvim' vi='nvim'
fi

# --- History: big, deduplicated, written immediately ---------
HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%F %T  '
HISTIGNORE='ls:ll:la:cd:pwd:exit:clear:history'
shopt -s histappend cmdhist
case "$PROMPT_COMMAND" in *"history -a"*) ;; *) PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;; esac

# --- Shell behaviour -----------------------------------------
shopt -s globstar autocd cdspell dirspell checkjobs

# --- Tool hooks (each only if installed) ---------------------
command -v mise   >/dev/null 2>&1 && eval "$(mise activate bash)"
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook bash)"
if [ -x "$HOME/miniconda3/bin/conda" ]; then
  conda() { unset -f conda; eval "$("$HOME/miniconda3/bin/conda" shell.bash hook)"; conda "$@"; }
fi
if command -v fzf >/dev/null 2>&1; then
  if _fzf_init="$(fzf --bash 2>/dev/null)"; then eval "$_fzf_init"
  elif [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then . /usr/share/doc/fzf/examples/key-bindings.bash
  fi
  unset _fzf_init
fi

# --- Aliases (drop-in replacements only; bash is the conservative shell) ---
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -lah --git --group-directories-first'
  alias lt='eza --tree --level=2 --git-ignore'
else
  alias ll='ls -alFh'
fi
command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'
command -v lazygit >/dev/null 2>&1 && alias lg='lazygit'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias cp='cp -i'
alias mv='mv -i'
alias dc='docker compose'

# --- Machine-specific settings and secrets (never committed) -
[ -f "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"

# --- Prompt and smart cd: keep these last --------------------
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
command -v zoxide   >/dev/null 2>&1 && eval "$(zoxide init bash)"
