alias grep='grep --color=auto'
if (( $+commands[eza] )); then
  alias ls='eza --icons=auto --group-directories-first'
  alias ll='eza -l --icons=auto --group-directories-first --git'
  alias la='eza -la --icons=auto --group-directories-first --git'
  alias lt='eza --tree --level=2 --icons=auto'
else
  alias ls='ls --color=auto'
fi
alias ..='cd ..'
alias ...='cd ../..'
