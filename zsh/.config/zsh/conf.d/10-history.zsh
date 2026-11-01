HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
[[ -d ${HISTFILE:h} ]] || mkdir -p "${HISTFILE:h}"
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_all_dups hist_ignore_space hist_reduce_blanks
setopt extended_history
