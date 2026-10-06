# Material Shell

Hyprland向けQuickshellステータスバー。全モニターの上端に表示します。
絵文字は使用せず、Google Material Symbols OutlinedのSVGを同梱しています（Apache-2.0、material-symbols/LICENSE）。
アイコンはFILL 0・weight 400・grade 0・optical size 24に統一し、バーでは16px、パネルでは20pxで表示します。
既存の起動名 `material-shell` は維持しています。

表示: ワークスペース1〜5、アクティブウィンドウ名、`yyyy/MM/dd HH:mm`形式の日時、CPU・メモリ使用率、ネットワーク、音量。バッテリー搭載時は残量も表示します。

操作:
- 左端・Super+Space: 独自ランチャー（検索・上下キー・Enter・Esc）
- ワークスペース: クリックで切り替え
- 音量: クリックでコントロールパネルの音声タブ、スクロールで5%ずつ変更
- 曲名、ネットワーク、通知、クリップボード、撮影、設定: コントロールパネルの該当タブ
- 電源: 独自セッションメニュー。壁紙アイコンは壁紙セレクターを直接開きます

起動: `~/.config/quickshell/material-shell/start.sh`
自動起動は `~/.config/hypr/hyprland.lua` に追加済みです。
Noctaliaの自動起動は撤去済み。通知・トレイ・クリップボード・アイドル監視も独自シェルが担当します。

停止: `quickshell kill -c material-shell`。バーの停止は独立ロック画面を解除しません。
旧構成への復帰は、まず独自バーを停止し、`hyprland.lua.before-independent-shell`と
`start.sh.before-independent-shell`を各元ファイルに戻してHyprlandを再読み込みし、Noctaliaを起動してください。
旧状態とNoctaliaパッケージは保存しています。壁紙もNoctaliaへ戻す場合は
`~/.local/state/noctalia/settings.toml.before-awww`を復元し、awww-daemonを停止してください。

必要環境: Quickshell 0.3.1、Hyprland、Python 3、NetworkManager（nmcli）、PipeWire、
awww、Matugen、grim、slurp、wl-clipboard、cliphist、swayidle、oxipng。
Wi-Fi接続にはNetworkManager (nmcli)、Bluetoothにはbluetoothctlが必要です。接続タブからWi-Fiネットワークの検索・接続・切断、Bluetooth機器の検索・ペア設定・接続・登録解除を操作できます。未導入またはアダプターがない場合は該当操作を無効にします。
外部コマンドはユーザー領域 `~/.local/bin`へ導入済みです。

色・高さ・文字サイズはTheme.qmlで管理します。
フォントはInterを優先し、日本語はNoto Sans JPにフォールバックします（Theme.qml、fonts.conf）。
start.shでバー専用のFONTCONFIG_FILEを指定し、他アプリのフォント設定には影響しません。
Material 3 Expressiveをデスクトップ向けに適用しています。壁紙由来のライト/ダーク配色を生成し、意味を持つ色ロールを共用します。
バーは全幅のフラットな面、選択中のワークスペースはPrimary / On Primaryで表示します。
ツールチップはMaterial 3のPlain Tooltipに合わせ、Inverse Surface・4px角丸・影なしにしています。
色・形状・文字サイズの共通トークンはTheme.qmlで変更できます。
CPU・メモリは2秒、ネットワークは約10秒ごとに取得します。

参照:
- https://quickshell.org/docs/v0.2.1/types/Quickshell/PanelWindow/
- https://quickshell.org/docs/v0.2.1/types/Quickshell.Hyprland/Hyprland/
- https://developers.google.com/fonts/docs/material_symbols
- https://github.com/google/material-design-icons

デザイン参照: https://m3.material.io/styles/color/the-color-system 、https://m3.material.io/components/tooltips/specs

## デザインと移行

実装前の基準はDESIGN_SYSTEM.md、実装トークンはTheme.qmlです。
編集時はAGENTS.mdの指示に沿い、共通部品を再利用してください。
移行の進捗と残るNoctalia依存はMIGRATION.mdに記録しています。

ランチャーIPC:

```sh
quickshell ipc -c material-shell call launcher toggle
quickshell ipc -c material-shell call launcher close
```

検証:

```sh
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input ~/.config/quickshell/material-shell/tests -import /usr/lib/qt6/qml
python3 ~/.config/quickshell/material-shell/tests/live_launcher.py
```

live_launcher.pyは検証用の一時desktop entryを作り、実際のパネルでEsc・外側クリック・上下キー・通常/ターミナル起動を確認して削除します。
検証中は短時間パネルが表示されます。電源・ロック操作は実行しません。

## 壁紙とMatugenパレット

Matugen 4.2.0を~/.local/bin/matugenに配置（公式リリースのSHA-256を照合）。
起動時および壁紙変更時にlight・dark両方のscheme-tonal-spot / contrast 0を生成します。
awwwの先頭出力の壁紙を5秒ごとに確認し、変更時のみ生成。2画面とも共通配色です。
壁紙の描画はawww、保存と復元は`material-wallpaper-backend`が担当します。

壁紙と配色を同時に変更（空白を含むパスは引用符で囲む）:

```sh
material-palette "/path/to/wallpaper.jpg"
```

現在の壁紙から生成する場合は引数なし。awww imgで変更した場合も自動追従します。
パレットは${XDG_STATE_HOME:-~/.local/state}/material-shell/palette.jsonに保存し、
バー・ランチャー・構造アイコン・入力欄・ツールチップへ再起動せずに反映します。
設定タブでライト/ダークを選ぶと全画面に即時反映し、選択を保存します。生成失敗や不正なJSONでは直前の配色を保持し、初回未生成時はTheme.qmlの固定色を使用。
Matugenは--dry-runで呼び出し、他アプリの設定やフックを実行しません。

```sh
quickshell ipc -c material-shell call theme status
```

公式: https://github.com/InioX/matugen/releases/tag/v4.2.0

## 独自壁紙セレクター

バーの壁紙アイコンまたはSuper + Shift + Wで開きます。
フォルダーのパスを入力して「読み込む」、名前・パスで検索し、画像をクリックしてプレビュー。
「壁紙と配色を適用」または検索欄でEnterを押すと全画面の壁紙とMatugen配色を更新します。
↑↓で選択、Escまたは外側クリックで閉じます。選択のみでは壁紙を変更しません。
初期フォルダーは~/Pictures/Wallpapers、~/Wallpapers、/usr/share/backgrounds。
現在の壁紙は検索フォルダー外でも一覧に含めます。PNG/JPEG/WebP/BMPが対象です。
成功したフォルダー指定を~/.config/material-shell/wallpapers.jsonへ保存し、次回復元します
（XDG_CONFIG_HOMEに対応）。一覧は開く時・再読み込み時に更新します。
壁紙はawwwで描画し、セレクター・保存・復元・配色は独自実装です。

```sh
quickshell ipc -c material-shell call wallpaper toggle
quickshell ipc -c material-shell call wallpaper status
python3 ~/.config/quickshell/material-shell/tests/test_wallpapers.py
python3 ~/.config/quickshell/material-shell/tests/live_wallpaper.py
```

live_wallpaper.pyは一時ライブラリと模擬適用処理を使い、実際の壁紙を変更せず操作とエラー表示を検証します。
画像は非同期・サイズ上限付きで読み込みます: https://doc.qt.io/qt-6/qml-qtquick-image.html

## awww描画バックエンド

awww 0.12.1（Arch extra配布版、パッケージSHA-256照合済み）のawwwとawww-daemonを
~/.local/binへ導入しています。公式: https://codeberg.org/LGFae/awww
起動時にstart.shがデーモンを起動し、~/.local/state/material-shell/wallpaper.jsonから復元します。
未保存の場合はpalette.jsonの既存壁紙を移行します。XDG_STATE_HOMEにも対応します。
デーモン停止とモニター追加で未設定の出力を5秒ごとに検出して復元。
全画面にcropで描画し、transition-type randomを指定しています。
Noctaliaのwallpaper.enabledをfalseへ変更し、描画競合を防いでいます。
変更前の設定: ~/.local/state/noctalia/settings.toml.before-awww。
デーモンのログ: ~/.local/state/material-shell/awww.log。

```sh
~/.local/bin/awww query
python3 ~/.config/quickshell/material-shell/tests/test_wallpaper_backend.py
```

## 独立シェルの操作と保存

| キー | 操作 |
|---|---|
| Super+Space | アプリランチャー |
| Super+Shift+W | 壁紙セレクター |
| Super+M | セッションメニュー |
| Super+Comma | シェル設定 |
| Super+N | 通知センター |
| Super+Shift+C | クリップボード履歴 |
| Super+L | 独立ロック画面 |
| Print / Shift+Print | 全ディスプレイ / 範囲キャプチャ |

各パネルはEsc・外側クリックで閉じます。トレイは左クリックで起動、右クリックで独自メニュー。
機能アイコンはコントロールパネルを開き、対応するタブを選択します。バーの調整アイコンはクイックタブを開きます。
タブはアイコンとラベルを表示し、横スクロールできます。壁紙セレクター、ランチャー、セッション、トレイはそれぞれ専用UIです。

| バーの入口 | 開く場所 |
|---|---|
| 調整 | クイック |
| ネットワーク | 接続 |
| 音量 | 音声 |
| 曲名 | メディア |
| 通知 | 通知 |
| 壁紙 | 壁紙セレクター |
| 設定 | 設定 |
| クリップボード | 履歴 |
| スクリーンショット | 撮影 |

`audio`、`media`、`notifications`、`settings`、`clipboard`、`capture`のIPCターゲットは対応タブを開きます。
クイック・接続は `quickshell ipc -c material-shell call control tab quick` のように `control tab` から開けます。明るさはクイックタブにあります。旧 `display` タブ指定は互換のためクイックへ移動します。
通知は置換・期限・アクション・履歴・DNDに対応。本文はプレーンテキストです。
クリップボードはテキスト・画像を最大100件保存し、検索・再コピー・個別削除できます。
従来のNoctalia履歴はそのまま保存し、新しい履歴は独立したデータベースを使います。
Printキーとコントロールパネルの撮影タブから現在のディスプレイ・全ディスプレイ・範囲を撮影できます。範囲は独立プログラム `~/.local/bin/material-screenshot` がslurpを直接起動し、ドラッグして離すと撮影、Escでキャンセルします。撮影後はoxipngでロスレス最適化し、ファイルサイズが小さくなった場合だけ採用します。最適化後のPNGを `~/Pictures/Screenshots`へ保存してクリップボードにもコピーします。
音量・ミュート・明るさの変更でOSDを表示します（明るさはバックライト搭載時）。
コントロールパネルにクイック・接続・音声・メディア・通知・設定・クリップボード・撮影のタブをまとめています。明るさ調整と壁紙/配色の入口はクイックにあります。バーの壁紙アイコンは専用セレクターを直接開きます。ランチャー・セッション・トレイ・壁紙セレクターは専用UIを使います。
曲が変わるとアルバムアート、曲名、アーティストを含むメディアOSDを4秒間表示します。

設定: `~/.config/material-shell/settings.json`。表示項目、ワークスペース数、
DND、OSD、自動ロック・消灯時間を変更できます。初期状態は自動ロック・消灯とも無効です。
設定は保存時に検証し、不正な変更では直前の値を保持します。
状態: `~/.local/state/material-shell/notifications.json`、`clipboard.db`、`wallpaper.json`、`palette.json`。
XDG_CONFIG_HOME / XDG_STATE_HOMEに対応します。

ロックは別設定 `~/.config/quickshell/material-lock`のWlSessionLockとPAM loginを使用。
サスペンドはロック完了を確認してから実行します。バー再読込とロックを分離しています。
ログアウト・再起動・電源オフ・サスペンドには確認画面があります。
実際のロック解除・サスペンド復帰・再ログインは未検証です。自動テストでは実行していません。

追加の安全な検証:

```sh
python3 ~/.config/quickshell/material-shell/tests/test_settings_session.py
python3 ~/.config/quickshell/material-shell/tests/test_capture.py
python3 ~/.config/quickshell/material-shell/tests/test_controls.py
python3 ~/.config/quickshell/material-shell/tests/live_controls.py
python3 ~/.config/quickshell/material-shell/tests/live_media.py
python3 ~/.config/quickshell/material-shell/tests/preview_lock.py
python3 ~/.config/quickshell/material-shell/tests/live_settings.py
python3 ~/.config/quickshell/material-shell/tests/live_session.py
dbus-run-session -- env MATERIAL_NOTIFICATION_TEST_PRIVATE=1 python3 ~/.config/quickshell/material-shell/tests/live_notifications.py
```

トレイ検証 `tests/live_tray.py`もプライベートD-Busを使用します。テスト専用にPyGObjectが必要です。
セッションテストは模擬バックエンド、ロック検証は通常ウィンドウのプレビューで行います。

## コントロールパネルの音声タブ

バーの音量アイコン、またはコントロールパネルの「音声」タブで操作します。
出力とマイク入力それぞれの音量（0〜100%）・ミュート・既定デバイスを操作できます。
音量は即時反映。スライダーは左右キーで5%、Home/Endで最小/最大、Escで閉じます。
機器の追加・削除と外部からの音量変更に追従します。
接続先の選択はPipeWireのpreferredDefaultAudioSink/Sourceを使用します。
公式API: https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Pipewire/Pipewire/

IPC: `quickshell ipc -c material-shell call audio toggle`。音声アイコンからも同じタブを開きます。
安全な操作テスト: `python3 ~/.config/quickshell/material-shell/tests/live_audio.py`。
両画面でEsc・外側クリック・デバイス一覧・模擬スライダーのキーボード操作を確認しました。
実際の音量・ミュート・既定デバイスはテストで変更していません。

## コントロールパネルのメディアタブ

MPRIS対応プレイヤーがある場合、バー左側に曲名を表示します。クリック、コントロールパネルのメディアタブ、
`quickshell ipc -c material-shell call media toggle`から操作画面を開けます。
アートワーク・曲名・アーティスト・アルバム、前/次、再生/一時停止、シーク、プレイヤー選択に対応。
非対応操作は無効化。再生位置は波形プログレスで表示します（表示専用）。
再生中を自動優先し、手動選択したプレイヤーは終了まで維持します。
プレイヤー未接続時には空状態を表示。再生位置はパネル表示中のみ1秒間隔で更新します。
テスト: `python3 ~/.config/quickshell/material-shell/tests/live_media.py`。
両画面で各7件成功。模擬プレイヤーを使用し、実際のメディア再生は変更していません。
実機でもMPRISプレイヤーの接続と再生中状態を確認しました。実アプリの再生操作は未検証です。
公式API: https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Mpris/MprisPlayer/

メディア画面はコントロールパネル内のタブです。曲名チップとメディアIPCは同じタブを開きます。

## Material 3 Expressive

共通ボタン・スイッチ・検索欄・見出し・パネル形状とNow Playingの操作グループを更新しました。
強調ボタンはPrimary / On Primary、押下中は8px角丸へ形状変化、スイッチはスプリングで移動します。
デザイン仕様はDESIGN_SYSTEM.md v2、物理アニメーションの調整値はTheme.qmlへ集約しています。
Inter / Noto Sans JP、16pxのバーアイコン、20pxのパネルアイコン、枠線なしのバーを維持。
GoogleのAndroid用モーショントークンの完全移植ではなく、Qt Quick向けの適用です。
動きを停止する場合は起動環境に `MATERIAL_SHELL_REDUCED_MOTION=1`を設定します。
参照: https://m3.material.io/styles/motion

スライダーはExpressiveの縦ハンドル・16pxトラック・6pxギャップ・端点マーカーへ更新しました。
音量とNow Playingのシークに共通適用。OSDは4pxの波形プログレス、4pxギャップと終端マーカーを使用。
波形は表示中に流れます。Now Playingでは再生中のみ動き、一時停止・非表示時に停止します。

Now Playingの再生位置表示をスライダーから波形プログレスへ変更しました。音量スライダーは維持しています。

波形のアクティブインジケーターは線幅4px・振幅3px・波長40pxに修正しました。

進捗の長さはオーバーシュートなしのスプリング、振幅変化は500ms、波の移動は40px/秒。動きを減らす設定にも対応します。

OSDの高さはアイコンとラベル/波形プログレスの自然高から算出し、上下の内側余白を各16pxに揃えます。

音量・明るさOSDとバーのアイコンは現在値に合わせて切り替わります。音量はミュート/小/大、明るさは低/中/高、バッテリーは残量と充電状態を表示します。

セッションメニューは横並びグリッドで、32pxアイコンの下に操作名を表示します。画面幅に応じて列数を調整します。

## バックエンドCLI

OS操作・永続化・統計・監視処理は`~/.local/lib/material-shell`に置き、
`~/.local/bin/material-*`のCLIから実行します。設定、セッション、クリップボード、
キャプチャ、壁紙一覧/適用、Matugen、ロック、統計、アイドル監視を提供します。
音量/ミュートと明るさのホットキーも`material-audio` / `material-display`経由で実行します。
Quickshellは表示、パネル状態、QuickshellネイティブAPIによる通知・トレイ・MPRIS・
PipeWire・Hyprland状態の購読を担当します。

`start.sh`はユーザーsystemdサービスとして統計、壁紙パレット監視、クリップボード/アイドル監視を起動します。
状態はJSON CLI出力または`$XDG_RUNTIME_DIR/material-shell/stats.json`を介してUIへ渡します。
