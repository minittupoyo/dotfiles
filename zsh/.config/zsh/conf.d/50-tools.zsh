(( $+commands[fzf] )) && source <(fzf --zsh)
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
  source <(mise completion zsh)   # compinit (20) の後なので compdef が使える
fi
