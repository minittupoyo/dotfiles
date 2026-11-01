# 対話シェル専用。conf.d/*.zsh を番号順に読み込む
for f in "$ZDOTDIR"/conf.d/*.zsh(N); do
  source "$f"
done
unset f
