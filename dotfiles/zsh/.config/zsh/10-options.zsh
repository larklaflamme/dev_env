# 10-options.zsh — history, shell options, key bindings

# ---- history: big, shared across sessions, deduplicated ----
HISTFILE="$XDG_STATE_HOME/zsh/history"
[[ -d ${HISTFILE:h} ]] || mkdir -p "${HISTFILE:h}"
HISTSIZE=200000
SAVEHIST=200000
setopt EXTENDED_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS \
       HIST_VERIFY SHARE_HISTORY INC_APPEND_HISTORY
HISTORY_IGNORE='(ls|ll|la|lt|cd|cd ..|pwd|exit|clear|history)'

# ---- behaviour ----
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT   # `cd -<Tab>` = dir stack
setopt INTERACTIVE_COMMENTS EXTENDED_GLOB NO_BEEP
# Stricter options some people love — uncomment in ~/.zshrc.local if you do:
#   setopt NO_CLOBBER   # `>` won't overwrite an existing file; `>|` forces
#   setopt CORRECT      # offer to fix typos in command names

# ---- completion styling (fzf-tab drives the menu) ----
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' menu no
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' fzf-flags --height=50%
zstyle ':fzf-tab:complete:(cd|__zoxide_z|__zoxide_zi):*' fzf-preview 'eza -1 --color=always --icons=auto $realpath'
zstyle ':fzf-tab:complete:(nvim|vim|bat|cat|less):*' fzf-preview 'bat --color=always --style=numbers --line-range=:200 $realpath 2>/dev/null || eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'

# ---- keys ----
if [[ -n $DEVENV_VI_MODE ]]; then
  bindkey -v; export KEYTIMEOUT=1
else
  bindkey -e
fi
bindkey '^[[A' history-substring-search-up       # Up
bindkey '^[[B' history-substring-search-down     # Down
bindkey '^ '   autosuggest-accept                # Ctrl-Space: take the suggestion
bindkey '^[[1;5C' forward-word                   # Ctrl-Right
bindkey '^[[1;5D' backward-word                  # Ctrl-Left
autoload -Uz edit-command-line && zle -N edit-command-line
bindkey '^X^E' edit-command-line                 # Ctrl-X Ctrl-E: edit command in nvim
