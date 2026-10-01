# 30-functions.zsh — small power tools (loaded before aliases so they use the classic tools). `functions <name>` shows the source of any of them.

# mkdir + cd
mkcd() { mkdir -p -- "$1" && cd -- "$1"; }

# yazi file manager; quitting with `q` leaves you in the directory you browsed to
y() {
  local tmp="$(mktemp -t yazi-cwd.XXXXXX)" cwd
  yazi "$@" --cwd-file="$tmp"
  cwd="$(<"$tmp")"
  [[ -n $cwd && $cwd != $PWD ]] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

# fe [query] — fuzzy-find a file and open it in nvim
fe() {
  local f; f="$(fzf --query="$*" --preview 'bat --color=always --style=numbers --line-range=:300 {}')" \
    && ${EDITOR:-nvim} "$f"
}

# rgv PATTERN — live ripgrep, preview the hit, Enter opens nvim at that line
rgv() {
  local sel
  sel="$(rg --color=always --line-number --no-heading --smart-case "${*:-}" |
    fzf --ansi --delimiter : \
        --preview 'bat --color=always {1} --highlight-line {2}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3')" || return
  ${EDITOR:-nvim} "${sel%%:*}" "+$(cut -d: -f2 <<<"$sel")"
}

# fkill — pick processes with fzf, kill them (default TERM; fkill 9 for KILL)
fkill() {
  local pids; pids="$(ps -ef | sed 1d | fzf -m --header='select process(es) to kill' | awk '{print $2}')"
  [[ -n $pids ]] && echo "$pids" | xargs kill -"${1:-15}"
}

# fbr — fuzzy switch git branch (local + remote)
fbr() {
  local b; b="$(git branch --all --sort=-committerdate --format='%(refname:short)' |
    grep -v HEAD | fzf --preview 'git log --oneline --graph --color=always -20 {}')" || return
  git switch "${b#origin/}" 2>/dev/null || git switch --track "$b"
}

# flog — browse git log, preview each commit with delta
flog() {
  git log --color=always --format='%C(auto)%h %s %C(dim)%an, %ar' "$@" |
    fzf --ansi --no-sort --preview 'git show --color=always {1} | delta' \
        --bind 'enter:execute(git show {1} | delta --paging=always)'
}

# dsh [shell] — exec into a running container picked with fzf
dsh() {
  local c; c="$(docker ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' | fzf | cut -f1)" || return
  docker exec -it "$c" "${1:-sh}" -c 'command -v bash >/dev/null && exec bash || exec sh'
}

# mkenv NAME [specs...] — create a conda env and activate it (default python=3.13)
mkenv() {
  [[ -n $1 ]] || { echo "usage: mkenv NAME [python=3.12 numpy ...]"; return 1; }
  local name=$1; shift
  conda create -y -n "$name" "${@:-python=3.13}" ipython pip && conda activate "$name"
}

# port N — what is listening on port N?
port() { ss -tulpn | awk -v p=":$1" 'NR==1 || $5 ~ p"$"'; }

# serve [port] — static file server for the current directory
serve() { python3 -m http.server "${1:-8000}" --bind 127.0.0.1; }

# bak FILE — timestamped copy
bak() { cp -a -- "$1" "$1.$(date +%Y%m%d-%H%M%S).bak"; }

# cheat TOPIC — community cheat sheets (cht.sh), e.g. `cheat rust/vec` or `cheat tar`
cheat() { curl -s "https://cht.sh/${(j:/:)@}"; }

# wttr [city] — weather in the terminal
wttr() { curl -s "https://wttr.in/${1:-}?F"; }

# up N — cd up N directories
up() { local p=""; repeat ${1:-1} p+="../"; cd "$p"; }
