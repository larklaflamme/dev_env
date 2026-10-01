# 20-tools.zsh — hook the toolchain into the shell. Every block is skipped if the tool is missing.

_has() { (( $+commands[$1] )) }

# ---- mise: per-directory tool versions (node, golangci-lint, CLI tools...) ----
_has mise && eval "$(mise activate zsh)"

# ---- conda: lazy-loaded; the first `conda ...` installs the real hook (saves ~150ms/shell) ----
typeset -g DEVENV_CONDA_ROOT="${DEVENV_CONDA_ROOT:-$HOME/miniconda3}"
if [[ -x $DEVENV_CONDA_ROOT/bin/conda ]]; then
  conda() {
    unfunction conda
    eval "$("$DEVENV_CONDA_ROOT/bin/conda" shell.zsh hook)"
    conda "$@"
  }
fi

# ---- direnv: per-directory .envrc ----
_has direnv && eval "$(direnv hook zsh)"

# ---- fzf: Ctrl-T files, Alt-C dirs, ** completion (Ctrl-R is atuin's) ----
if _has fzf; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  export FZF_DEFAULT_OPTS='--height=45% --layout=reverse --border=rounded --info=inline
    --bind=ctrl-/:toggle-preview --color=pointer:#f38ba8,marker:#a6e3a1,prompt:#89b4fa,hl:#f9e2af,hl+:#f9e2af'
  export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {}'"
  export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always --icons=auto {} | head -200'"
  _fzf_compgen_path() { fd --hidden --follow --exclude .git . "$1"; }
  _fzf_compgen_dir()  { fd --type d --hidden --follow --exclude .git . "$1"; }
  source <(fzf --zsh)
fi

# ---- atuin: SQLite history with context (dir, exit code, duration). After fzf so it owns Ctrl-R ----
_has atuin && eval "$(atuin init zsh --disable-up-arrow)"

# ---- completions for tools that generate their own (written once, picked up next shell) ----
_devenv_completion() {   # _devenv_completion NAME CMD...
  local out="$XDG_DATA_HOME/zsh/site-functions/_$1"; shift
  [[ -s $out ]] || { _has "$1" && "$@" >| "$out" 2>/dev/null; }
}
_devenv_completion mise   mise completion zsh
_devenv_completion uv     uv generate-shell-completion zsh
_devenv_completion uvx    uvx --generate-shell-completion zsh
_devenv_completion rustup rustup completions zsh rustup
_devenv_completion cargo  rustup completions zsh cargo
_devenv_completion just   just --completions zsh
_devenv_completion ruff   ruff generate-shell-completion zsh
unfunction _devenv_completion
