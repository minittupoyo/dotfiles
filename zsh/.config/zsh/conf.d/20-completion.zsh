fpath=(/usr/share/zsh/site-functions $fpath)
autoload -Uz compinit
_zcomp="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
[[ -d ${_zcomp:h} ]] || mkdir -p "${_zcomp:h}"
compinit -d "$_zcomp"
unset _zcomp

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache"
