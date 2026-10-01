# 90-prompt.zsh — prompt and smart cd. Keep last: both wrap hooks other tools set up.

(( $+commands[starship] )) && eval "$(starship init zsh)"

# zoxide learns the directories you use; `cd foo` jumps to the best match for "foo",
# `cdi` picks interactively. With DEVENV_ALIASES=none you get `z`/`zi` instead.
if (( $+commands[zoxide] )); then
  if [[ $DEVENV_ALIASES == (safe|all) ]]; then
    eval "$(zoxide init zsh --cmd cd)"
  else
    eval "$(zoxide init zsh)"
  fi
fi
