# dotfiles

Arch Linux 実機用の dotfiles。Hyprland + quickshell で、Material Design 3 Expressive 準拠のデスクトップシェルを自作している。
既存の dots(Caelestia, end-4 など)は使っていない。

## 構成

| ディレクトリ | 内容 |
| --- | --- |
| `hypr/` | Hyprland 設定(Lua)。`hyprland.lua` から `binds` / `monitors` / `rules` などを分割して読み込む |
| `quickshell/` | シェル本体(QML)。バー、ランチャー、壁紙セレクターなど |
| `matugen/` | 配色生成の `config.toml` と各アプリ向けテンプレート |
| `kitty/` `starship/` `zsh/` | ターミナル、プロンプト、シェル設定 |
| `gtk/` `qt6ct/` `fontconfig/` | GTK / Qt のテーマ設定、フォント設定 |
| `scripts/` | 補助スクリプト(`~/.local/bin` に展開) |
| `CLAUDE.md` | このリポジトリでの作業ルールと設計方針 |

各ディレクトリは [GNU Stow](https://www.gnu.org/software/stow/) のパッケージで、中身が `$HOME` からの相対パスになっている。

## quickshell

`quickshell/.config/quickshell/shell/` 以下の構成。

- `tokens/` — `Colors` / `Shapes` / `Typography` / `Motion` / `Elevation`。色・形・フォント・モーションは必ずここ経由で参照する
- `components/` — `Button` / `Card` / `Switch` / `Slider` / `StateLayer` / `Ripple` など共通部品
- `services/` — `Audio` / `Network` / `Notifications` / `Wallpaper` / `Settings` などのシングルトン
- `modules/` — 画面単位の機能

| モジュール | 内容 |
| --- | --- |
| `bar` | 各モニターに 1 つずつ表示するバー |
| `launcher` | アプリ検索、計算、絵文字、クリップボード履歴 |
| `wallpaper` | サムネイルグリッドの壁紙セレクター |
| `overview` / `switcher` | ワークスペース一覧 / Alt+Tab 切り替え |
| `notifications` / `osd` | 通知 / 音量などの OSD |
| `quicksettings` / `settings` | クイック設定 / 設定画面 |
| `dashboard` / `media` / `power` | ダッシュボード / メディア操作 / 電源メニュー |
| `screenshot` / `lock` | スクリーンショット / ロック画面 |

`gallery.qml` は部品の確認用ギャラリー。

## 配色パイプライン

```
壁紙を選択 → awww で適用 → matugen (scheme-expressive)
  → colors.json を出力 → quickshell の Colors が FileView で監視して即反映
  → 同時に Hyprland / kitty / GTK / Qt の配色ファイルも出力
```

`scripts/.local/bin/apply-wallpaper.sh` が一連の処理を実行する。
matugen の出力先は `matugen/.config/matugen/config.toml` に書いてある。

## セットアップ

前提パッケージ(抜粋): `hyprland` `quickshell` `matugen` `awww` `stow` `kitty` `fcitx5-mozc` `grim` `cliphist` `wl-clipboard` `playerctl` `polkit-gnome`

```sh
git clone https://github.com/minittupoyo/dotfiles ~/dotfiles
cd ~/dotfiles
stow hypr quickshell matugen kitty starship zsh gtk qt6ct fontconfig scripts
```

配色ファイルは壁紙を適用したときに生成される。初回は一度実行しておく。

```sh
apply-wallpaper.sh ~/Pictures/Wallpapers/<好きな画像> [dark|light]
```

## キーバインド

メイン修飾キーは `SUPER`。

| キー | 動作 |
| --- | --- |
| `Super + Return` | ターミナル |
| `Super + Space` | ランチャー |
| `Super + .` | 絵文字ピッカー |
| `Super + Shift + V` | クリップボード履歴 |
| `Super + W` | 壁紙セレクター |
| `Super + Tab` | オーバービュー |
| `Alt + Tab` | ウィンドウ切り替え |
| `Super + N` | クイック設定 |
| `Super + ,` | 設定 |
| `Super + M` | 電源メニュー |
| `Super + L` | ロック |
| `Print` | スクリーンショット |
| `Super + Q` | ウィンドウを閉じる |

全体は `hypr/.config/hypr/binds.lua` を参照。

## 環境

- GPU: NVIDIA (RTX 5070 Ti)
- モニター: 2560x1440 × 2(ワークスペースはモニターごとに固定割り当て)
- 日本語入力: fcitx5 + mozc
