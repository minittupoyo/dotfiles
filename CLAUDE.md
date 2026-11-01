# プロジェクト概要

実機 Arch Linux 上に、Hyprland + quickshell で Material Design 3 Expressive 準拠のデスクトップシェルを**自作**する。
既存の dots(Caelestia, end-4 など)は導入しない。設計の参考として読むのは可。

対象: バー / ランチャー / 壁紙セレクター(サムネイルグリッド)。
後続フェーズ: 通知、クイック設定、ロック画面。

# 環境

- OS: Arch Linux(実機)
- コンポジタ: Hyprland
- シェル: quickshell(QML)
- GPU: RTX 5070 Ti(Blackwell)。ドライバは `nvidia-open` 系
- モニター: WQHD(2560x1440)× 2枚
  - スケール: 1
- 日本語入力: fcitx5 + mozc
- AURヘルパー: paru
- dotfiles: `~/dotfiles`(stow で `~/.config` に展開)
- スナップショット: Btrfs + snapper(導入していれば)

# 触らない領域(ユーザーが手動で管理)

- NVIDIAドライバ、`/etc/mkinitcpio.conf`、カーネルパラメータ、ブートローダー
- `/etc` 配下全般、systemdのシステムユニット
- 変更が必要だと判断した場合は、理由とコマンドを提示して止まる

# 作業ルール

## 安全
- sudo が必要な操作は実行しない。コマンドを提示して止まる
- パッケージの追加は、一覧(名前・用途・repo/AUR)にまとめて確認を取ってから
- 変更前に `git status` を確認し、作業の区切りごとに commit する。大きな変更の前はスナップショットをユーザーに依頼する
- 既存の設定ファイルを上書きする前にバックアップまたは commit
- 破壊的操作(`rm -rf`、設定の一括置換など)は事前に確認

## 検証
- quickshell は `qs -p <path>` で起動し、ログのエラー・警告を必ず読む。エラーは自分で直してから報告する
- 見た目は `grim` でスクリーンショットを撮って確認する(モニターごとに撮る)
- Hyprland 設定は変更後 `hyprctl reload` を実行し、エラー出力を確認する
- QML は学習データが少ない領域。推測でAPIを書かず、実装前に公式ドキュメント(quickshell.org)と `/usr/share/quickshell` 以下の型定義・ソースを確認する

## 進め方
- フェーズ単位で、計画 → 承認 → 実装 → 検証 → commit の順で進める
- 1フェーズが終わったら、何ができて何が未確認かを簡潔に報告する

# ディレクトリ構成

```
~/dotfiles/
├── CLAUDE.md
├── hypr/.config/hypr/              # Hyprland設定(分割して source)
├── matugen/.config/matugen/        # config.toml と templates/
├── quickshell/.config/quickshell/
│   └── shell/
│       ├── shell.qml
│       ├── tokens/                 # Colors / Shapes / Typography / Motion / Elevation
│       ├── components/             # Button, IconButton, Card, StateLayer, Ripple, ...
│       ├── services/               # Wallpaper, Audio, Network, Battery, Notifications, ...
│       └── modules/
│           ├── bar/
│           ├── launcher/
│           └── wallpaper/
└── scripts/                        # 補助スクリプト(サムネイル生成など)
```

# デザイン原則(Material 3 Expressive)

- 色・形・フォント・モーションは**必ず `tokens/` 経由**で参照する
- 色の直書き禁止。すべて `Colors` シングルトン(matugen出力)から取る
- 角丸は大きめ。`Shapes` に定義したスケールのみ使う。選択・押下時の形状モーフィングを活用する
- アニメーションはスプリング系の共通定義を使う(Spatial / Effects の2種類)。個別に `Easing` や固定 duration を書かない
- フォント: Google Sans Flex(入手不可なら Roboto Flex)、アイコンは Material Symbols Rounded
- インタラクティブな要素は hover / pressed / focused のステートレイヤーを持つ
- 新しい部品を作る前に `components/` に使えるものがないか確認する。重複実装しない
- 迷ったら M3 Expressive の公式ガイドラインに従う

# 配色パイプライン

```
壁紙選択 → 壁紙適用(awww or hyprpaper) → matugen(scheme: expressive) → colors.json
  → quickshell の Colors が FileView で監視して即反映
  → 同時にテンプレートから GTK / Qt / kitty 等の設定も出力
```

- 壁紙適用ツールは導入時点の最新状況を確認して決める(swww は awww に改名済みの可能性あり)
- 配色プレビューは重いため、選択ハイライト中の確認用途に限定する

# マルチモニター方針

- バーは各モニターに1つずつ表示する(`Variants` + `Quickshell.screens`)
- ランチャー・壁紙セレクターは、**フォーカス中のモニター**に表示する
- 壁紙: (記入。全モニター共通 / モニターごとに別)
- ワークスペース: (記入。例 モニターごとに固定割り当て)
- ハードコードしたモニター名・解像度を QML に書かない。取得したモニター情報を使う

# 壁紙セレクター仕様

- 壁紙ディレクトリ: `~/Pictures/Wallpapers`(変更可)
- 一覧: `FolderListModel` で監視
- サムネイル: 縮小版を `~/.cache/` に生成して使う(元画像を直接読まない)
- `Image` は `asynchronous: true` と `sourceSize` を必ず指定する
- 表示: `GridView`。選択中カードのみ拡大と形状モーフィング
- 適用: 壁紙変更 → matugen 実行 → 配色が全体に反映されるまでを一連の操作にする

# フェーズ

1. Hyprland 最小構成(モニター2枚、キーバインド、自動起動、portal、polkit、PipeWire)
2. 配色基盤(matugen、テンプレート、`Colors` シングルトン)
3. トークンと基本コンポーネント
4. バー
5. 壁紙セレクター
6. ランチャー(`DesktopEntries` による検索、計算、クリップボード等)
7. 通知、クイック設定、ロック画面

各フェーズの終わりに commit し、必要ならユーザーにスナップショットを依頼する。

# NVIDIA / Hyprland メモ

- `env` は `LIBVA_DRIVER_NAME=nvidia`, `__GLX_VENDOR_LIBRARY_NAME=nvidia`, `NVD_BACKEND=direct`, `ELECTRON_OZONE_PLATFORM_HINT=auto` などを Hyprland 設定に置く
- 描画崩れやちらつきが出たら、まず Arch Wiki と Hyprland Wiki の NVIDIA ページの最新情報を確認する
- 設定ミスで Hyprland が起動しなくなっても TTY から復旧できるよう、設定は常に git で戻せる状態を保つ
