# 40-aliases.zsh — modern replacements for classic tools, plus shortcuts.
# Loaded after 30-functions.zsh on purpose: zsh expands aliases inside function
# bodies at definition time, so functions keep using the classic tools.
#
# DEVENV_ALIASES (set in ~/.zshrc.pre.local) picks how far the replacement goes:
#   safe  drop-in replacements only (same everyday usage)
#   all   safe + tools whose flags differ from the classic ones (rg, fd, sd, dust...)
#   none  nothing overridden
# The real command is always reachable:  \grep foo   or   command grep foo
# `devenv aliases` prints the current mapping.

_has() { (( $+commands[$1] )) }

# ======================================================= tier: safe (drop-ins)
if [[ $DEVENV_ALIASES == (safe|all) ]]; then
  if _has eza; then
    alias ls='eza --group-directories-first --icons=auto'
    alias tree='eza --tree --icons=auto --git-ignore'
  fi
  _has bat  && alias cat='bat --paging=never'
  _has btop && alias top='btop' htop='btop'
  _has nvim && alias vim='nvim' vi='nvim'
  # cd -> zoxide is wired in 90-prompt.zsh (zoxide init --cmd cd)
fi

# ======================================================= tier: all (different flags!)
if [[ $DEVENV_ALIASES == all ]]; then
  _has rg     && alias grep='rg'          # careful: rg -r means --replace, not recursive (rg is always recursive)
  _has fd     && alias find='fd'          # fd PATTERN [DIR]  vs  find DIR -name PATTERN
  _has sd     && alias sed='sd'           # sd 'from' 'to' file   (in-place by default!)
  _has dust   && alias du='dust'
  _has duf    && alias df='duf'
  _has procs  && alias ps='procs'
  _has doggo  && alias dig='doggo'
  _has gping  && alias ping='gping'
  _has delta  && alias diff='delta'
fi

# ======================================================= listings (always)
if _has eza; then
  alias l='eza -l --group-directories-first --icons=auto --git'
  alias ll='eza -lah --group-directories-first --icons=auto --git'
  alias la='eza -a --group-directories-first --icons=auto'
  alias lt='eza --tree --level=2 --icons=auto --git-ignore'
  alias lT='eza --tree --level=4 --icons=auto --git-ignore'
  alias lm='eza -lah --sort=modified --icons=auto'          # newest last
else
  alias ll='ls -alFh --color=auto'
fi

# ======================================================= tool shortcuts
alias v='nvim'
alias lg='lazygit'
alias lzd='lazydocker'
alias help='tldr'
alias bench='hyperfine'
alias loc='tokei'
alias mdv='glow'                   # markdown viewer

# ---- docker ----
alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcr='docker compose restart'
alias dcl='docker compose logs -f --tail=200'
alias dps='docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
alias dprune='docker system prune -af --volumes'

# ---- python ----
alias py='python3'
alias ca='conda activate'
alias cdeact='conda deactivate'
alias cenvs='conda env list'
alias venv='uv venv && source .venv/bin/activate'
alias act='source .venv/bin/activate'

# ---- rust / go ----
alias cr='cargo run'
alias cb='cargo build'
alias ct='cargo nextest run'
alias clip='cargo clippy --all-targets -- -W clippy::pedantic'
alias gor='go run .'
alias got='go test ./...'

# ---- safety nets & quality of life ----
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -I'                   # one prompt for >3 files or recursive
alias mkdir='mkdir -pv'
alias reload='exec zsh'
alias path='print -l $path'
alias ports='ss -tulpn'
alias myip='curl -s https://ifconfig.me; echo'
alias copy='clipcopy'              # oh-my-zsh: Wayland/X11-aware  (clippaste to paste)
alias please='sudo $(fc -ln -1)'
alias zshrc='${EDITOR} ~/.zshrc'
alias dotfiles='cd $DEVENV_ROOT'
