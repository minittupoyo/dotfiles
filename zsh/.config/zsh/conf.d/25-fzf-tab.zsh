# compinit の後、autosuggestions / syntax-highlighting より前に読む
source /usr/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh

# fzf-tab が補完メニューを描画するので zsh 標準のメニューは無効化
zstyle ':completion:*' menu no
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' fzf-flags --height=40% --layout=reverse --border

# プレビュー
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons=auto $realpath'
zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -1 --color=always --icons=auto $realpath'
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset):*' fzf-preview 'echo ${(P)word}'
