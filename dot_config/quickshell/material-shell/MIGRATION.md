# Noctaliaから独自Quickshellへの移行調査

調査日: 2026-10-06。Quickshell 0.3.1、Hyprland Lua設定、DP-2 / DP-3の2画面。
以下の依存一覧は初回調査時点の記録。最新の移行状態は下記の進捗を参照。

## 最新状態: 独立シェルへ切替（2026-10-06）

設定、セッションメニュー、通知・履歴・DND、トレイと独自メニュー、クリップボード履歴、
キャプチャ、音量・明るさOSD、独立ロックとアイドル監視を実装。
Noctaliaを停止し、Hyprland自動起動とstart.shからNoctalia呼び出しを撤去しました。
通知・トレイのD-Bus名は独自Quickshellが所有。Fcitxトレイの再登録を確認。
壁紙はawww、配色はMatugen、認証はPAM、アイドル監視はswayidleです。
既存Noctalia状態とパッケージは保持し、履歴は独立保存。ランタイム依存は残っていません。

デザイン仕様を先に追加し、共通部品・トークンで統一。設定保存と外部更新、
通知の置換・期限・アクション・DND・再読込、トレイのサブメニューとアクションを検証。
設定とセッションの実機パネルを両画面で検証。セッション操作は模擬バックエンドです。
実際のgrimキャプチャ、隔離したcliphist保存・復号・削除、ロック画面プレビューを確認。
再読込時の監視プロセス終了を修正し、親プロセス終了時の子終了と重複なしを確認。

残る実操作確認: PAMでのロック解除、サスペンド復帰、再ログイン、物理モニター追加・切断、IME変換中の入力。
AGENTS.mdの指示に従い、実際のロック・電源・ログアウト操作は自動検証していません。
旧構成の具体的な復帰方法と操作一覧はREADME.mdを参照。

以下は初回調査と段階ごとの履歴です。「残る依存」は各段階の時点を示します。

## 進捗: 第1段階を実装済み（2026-10-06）

- 実装前にDESIGN_SYSTEM.mdを作成。AGENTS.mdに継続参照の規則を記述。
- Theme.qmlに余白・文字・形状・パネルの共通トークンを追加。
- components/MaterialIcon.qml、PanelFrame.qml、SearchField.qmlを追加。
- Launcher.qmlを実装: アプリ名・説明・キーワード・ID検索、NFKC正規化、上下キー・Enter、0件表示、アプリロゴのフォールバック。
- ランチャーはフォーカス中のモニターに表示。バーからはクリックしたモニターに表示。Esc・外側クリックで終了。
- appsボタンとSuper+Spaceを独自ランチャーに切り替え。Super+Rのhyprlauncherは維持。
- Terminal=trueはkittyを介して起動し、workingDirectoryも引き継ぐ。
- 検索欄のQt Quick Test: 5件成功（初期化・終了処理を含む）。
- 実機パネルのQtTest: 6件成功（初期化処理を含む）。Esc・外側クリック・検索/上下キー・0件のEnter・通常/ターミナル起動を確認。
- 一時desktop entryによる通常/ターミナル起動と作業ディレクトリを別途確認。一時エントリーは削除済み。
- DP-2/DP-3への表示先切り替えをIPCで確認。
- 日本語文字列の検索欄表示・クリアを確認。IME変換中の実機入力、物理モニター切断は未実施（コード上の対応あり）。
- 終了時にQt QQuickShortcutの破棄でクラッシュしたため、Shortcutを撤去し、PanelFrameのKeysでEscを処理。修正後の操作テストとIPCによる正常終了・再起動を確認。
- この段階のHyprland変更前バックアップ: hyprland.lua.before-launcher-migration。

残るNoctalia依存: 設定・セッションメニュー、通知、トレイ、壁紙、クリップボード、ロック/アイドル、キャプチャ、バー非表示の起動処理。
次段階: 共通ボタンを追加し、独自セッションメニューと設定画面を作る。

## 初回調査時の依存

| 対象 | 確認した状態 | 移行作業 |
|---|---|---|
| アプリランチャー | shell.qmlのappsボタンとSuper+SpaceがNoctaliaを呼ぶ | DesktopEntriesで一覧・検索・起動を実装し、バーとIPCを接続 |
| セッションメニュー | shell.qmlの電源ボタンとSuper+MがNoctaliaを呼ぶ | ロック・サスペンド・ログアウト・再起動・電源オフを実装 |
| 設定 | shell.qmlのsettingsボタンがNoctaliaの設定画面を開く | 独自シェル用の設定と保存・読み込みを実装 |
| 起動 | hyprland.luaがNoctaliaと独自バーを起動 | 移行完了後にNoctaliaの起動行を削除 |
| バー非表示 | start.shがNoctaliaのbar-hideを呼ぶ | 移行完了後に待機ループを削除 |
| 通知 | org.freedesktop.Notificationsの所有者はNoctalia PID 3347 | NotificationServer、トースト、履歴、DND、アクション、閉じる処理 |
| トレイ | org.kde.StatusNotifierWatcherの所有者はNoctalia PID 3347 | SystemTray、項目表示、メニュー、クリック処理 |
| 壁紙 | Noctaliaの壁紙レイヤーが2画面に存在 | 背景レイヤーのPanelWindow、画像読み込み、画面ごとの設定 |
| クリップボード履歴 | ログにテキスト・画像履歴の記録あり、状態ディレクトリも存在 | 取得・保存・選択・再コピー、必要なら既存履歴の移行 |
| ロック・アイドル | Noctaliaがlogindロック監視・アイドル監視を登録 | 実際のロック・自動消灯・スリープ設定を確認し、代替を用意 |
| スクリーンショット | 今回の表示確認でNoctaliaのキャプチャを使用 | キャプチャ・範囲選択・保存・コピーを別途用意 |
| 音量等のOSD | Noctaliaには機能があるが、自動表示の利用状態は未確認 | 音量・明るさ変更時にOSDが必要か確認して実装 |

バー表示、ワークスペース、時計、CPU・メモリ、ネットワーク状態取得、音量調整、フォント、ツールチップは既に独自実装。
NetworkManager、PipeWire、logind等の基盤サービスは継続利用する。
polkit-gnome認証エージェントは独立起動しているため、Noctalia置換の対象には含めない。
Super+Rはhyprlauncherで、Noctalia依存ではない。ランチャー統一時に変更候補。

## 推奨する移行順序

1. 共通のMD3ダイアログ・ボタン・入力欄・リストと、パネル管理を作る。
   Theme.qml、Inter / Noto Sans JP、Material Symbolsを共用する。
   フォーカスした画面への表示、Esc・外側クリックで閉じる、キーボード操作を揃える。
   IpcHandlerを追加してlauncher/session/settingsを外部から開けるようにする。
2. ランチャーを実装する。
   DesktopEntries.applicationsから検索し、DesktopEntry.execute()で起動する。
   Enter・上下キー・日本語入力・起動後の終了を検証する。
   使用頻度順・履歴は必要なら自前で保存する。
   appsボタンとSuper+Spaceを置換し、必要ならSuper+Rも統一する。
3. セッションメニューと設定を実装する。
   セッション操作はlogind/systemctl・現在のHyprland Lua APIに接続する。
   ロックは代替ロッカー完成までNoctaliaに委譲してよい。
   設定はバー・テーマ・表示項目・壁紙等の必要な項目に限定し、JSON等で永続化する。
   電源・設定ボタンとSuper+Mを置換する。
4. 壁紙、クリップボード、スクリーンショット、必要なOSDを移行する。
   現在の壁紙は/usr/share/noctalia/assets/noctalia-wallpaper.png。
   Noctaliaパッケージも削除するなら、利用条件を確認して独立した保存先に置くか別の壁紙を選ぶ。
   スクリーンショット・クリップボードの外部バックエンドは未導入だったため、採用方式を決めて準備する。
5. 通知・トレイを切り替える。
   UIは先に仮データで作り、NoctaliaがD-Bus名を所有している間は新サービスを有効にしない。
   通知サービスの引き継ぎ、トレイ再登録、アプリ再起動が必要かを実機で確認する。
   Noctalia停止の試験は壁紙・通知・クリップボード等の代替が用意できてから行う。
6. ロック・アイドル・復帰を確認し、Noctalia自動起動とstart.shのbar-hideループを撤去する。
   独自ロック画面ならWlSessionLock + PAMを使い、全画面のロック完了を確認してからサスペンドする。
   ロック中のQuickshell終了は画面をロック状態に残すため、バーの再起動と分離する設計を検討する。
   再ログイン後も依存がないことを確認して移行完了とする。

## 実装の配置案

shell.qmlを起点に、bar/、components/、panels/、services/に分割する。
components/にはMD3共通部品、panels/にはLauncher・Session・Settings・通知センターを置く。
services/にはアプリ一覧、パネル状態、通知、設定永続化、クリップボード等を置く。
ロック画面は独立したQuickshell設定または専用ロッカーに分ける候補。
既存の起動名material-shellは移行中に変えなくてもよい。

## 完了確認

- バーボタンとショートカットで同じ独自パネルが開く。
- 2画面、Esc、外側クリック、上下・Enter、日本語入力が動く。
- 通知の表示・期限切れ・置換・アクション・DNDと、トレイの操作が動く。
- 壁紙、クリップボード、設定が再ログイン後に復元される。
- ロック、解除、サスペンド復帰、モニター追加・切断を確認する。
- 稼働設定と起動スクリプトからnoctalia呼び出しを除去する（調査文書やバックアップは除外）。
- Noctaliaなしで再ログインして日常操作を確認する。

## 根拠

実機: shell.qml、start.sh、hyprland.lua、noctalia msg status、config export、D-Bus所有者、Hyprlandレイヤー、Noctaliaログ。
状態ファイル: ~/.local/state/noctalia/。通知・クリップボード・アプリ履歴は移行前に保存する。調査ではクリップボード本文は読んでいない。

公式API:
- https://quickshell.org/docs/v0.3.1/types/Quickshell/DesktopEntries/
- https://quickshell.org/docs/v0.3.1/types/Quickshell.Io/IpcHandler/
- https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Notifications/NotificationServer/
- https://quickshell.org/docs/v0.3.1/types/Quickshell.Wayland/WlSessionLock/

## 壁紙パレットの移行（2026-10-06）

- 独自実装へ移行: MatugenによるMD3色生成、検証、アトミック保存、変更検出、QMLでの動的適用。
- 全画面のバー、独自ランチャー、入力欄、ツールチップ、構造アイコンはThemeの共通色を使用。
- Noctaliaに残る: 壁紙描画・選択UI・画面ごとの壁紙保存。palette.pyのcurrent_wallpaperとwallpaper-setが接続点。
- Matugen 4.2.0の公式バイナリをユーザー領域へ導入。scheme-tonal-spot / dark / contrast 0。
- 今後: 独自壁紙選択UIと描画バックエンドに切り替えてNoctaliaのwallpaper-get/setを除去する。

配色の検証: QMLテスト10件成功、実機ランチャー6件成功。
実際の壁紙変更→5秒監視→Matugen生成→動的反映を確認し、元の壁紙へ復元。
アトミック更新の即時反映、不正JSONで直前色保持、不正画像で保存ファイル維持を確認。
再起動後のパレット復元、DP-2/DP-3のバー表示、ランチャーの画面キャプチャを確認。

## 壁紙セレクターの移行（2026-10-06）

- 独自実装へ移行: 壁紙一覧・検索・サムネイル・プレビュー・フォルダー保存・適用状態とエラー表示。
- バーのMaterial Symbols wallpaperアイコン、Super + Shift + W、wallpaper IPCから起動。
- 共通PanelFrame / SearchFieldと新しいShellButtonを使用し、ThemeのMatugen配色を共用。
- Noctaliaに残る: 壁紙描画・実際の壁紙パス保存。独自セレクター→palette.py→Noctaliaの描画という接続。
- 検証: ライブラリテスト2件、実機パネル6件成功（Esc、外側クリック、上下/0件、適用成功/失敗）。
- 設定バックアップ: ~/.config/hypr/hyprland.lua.before-wallpaper-selector。

DP-2とDP-3で実機パネルテストを実施し各6件成功。共通QMLテスト10件成功。
実画面キャプチャで壁紙のプレビュー、選択状態、Matugen配色との統一を確認。

## awwwへの描画移行（2026-10-06）

壁紙描画をawww 0.12.1へ切替済み。Noctaliaのwallpaper.enabledをfalseにし、
DP-2/DP-3のbackground layerにはawww-daemonのみ存在することを確認。
壁紙セレクター・Matugen・ライブラリ・起動処理からwallpaper-get/set依存を除去。
wallpaper_backend.pyが保存・起動時復元・デーモン復旧・未設定出力の復元を担当。
保存先はXDG_STATE_HOME/material-shell/wallpaper.json。以前のpalette.jsonから自動移行。
過去の節にある「Noctaliaに残る壁紙描画・保存」は本段階で解消。
Noctaliaは引き続き通知、トレイ、クリップボード、ロック・セッション・設定等を担当。
検証: バックエンド3件、ライブラリ2件、実機セレクター6件成功。

実機でawww-daemonを再起動し、保存壁紙が両出力へ復元されることを確認。

壁紙切り替えアニメーションはユーザー指定によりawwwのtransition-type randomへ変更。

## オーディオ設定（2026-10-06）

PipeWireの出力・入力音量、ミュート、既定機器を操作する独自パネルを追加。バー音量クリックと設定画面から開く。スライダー・デバイス選択は独自MD3部品。両画面で各5件の安全な操作テストを実施。実際の音量や既定機器の変更は検証中に実行していない。

## Now Playing（2026-10-06）

MPRIS連携の再生情報・操作パネルとバーの曲名表示を追加。曲画像、前/次、再生/一時停止、シーク、複数プレイヤーの選択に対応。デザイン仕様とトークンを先に追加。両画面で各7件の模擬プレイヤー操作テスト成功。実MPRISプレイヤーの接続と再生中状態を確認。実アプリでの再生操作は未検証。

Now Playingをバー直下のPopupWindowへ変更（スクラムなし・内容に応じた高さ・画面端で位置調整）。HyprlandFocusGrabで外側クリック、KeysでEscを処理。両画面で各7件の操作テスト成功。実プレイヤーの表示を画面キャプチャで確認。

## Material 3 Expressive（2026-10-06）

デザイン仕様v2と共通トークンを先に更新。MatugenパレットへOn Primary / Primary Container / On Primary Containerを追加、旧パレットも受理。共通ボタン・スイッチの形状と物理モーション、入力・パネル形状、見出し、ワークスペースの選択色、Now Playing操作グループを変更。QMLテスト10件、両画面のNow Playing各7件・設定各5件、オーディオ5件成功。実画面キャプチャ確認済み。

## Expressiveスライダー・プログレス（2026-10-06）

共通VolumeSliderを縦ハンドル・分離トラック・端点へ更新。ExpressiveProgressを追加しOSDへ適用。仕様と寸法はDESIGN_SYSTEM.md / Theme.qmlに記録。QML10件、オーディオ5件、Now Playing両画面各7件成功。実画面で描画を確認。検証のOSD IPCは表示のみで音量を変更しない。

Now Playingの再生位置を表示専用のExpressiveProgressへ変更。シーク操作を撤去し、経過/総時間は維持。

波形インジケーターの寸法を公式標準トークン（線幅4・振幅3・波長40）に修正。微小進捗の丸い端点も描画する。

波形モーションを追加: 等速位相、進捗長のスプリング、振幅500ms。再生中/表示中のみ位相を進め、停止・非表示・reducedMotionで止める。両画面で各8件のテスト成功（位相の進行/停止とreducedMotionを含む）。

OSDの上下余白を修正。高さを内容の自然高と上下各16pxのパディングから計算するよう変更。

## 段階値アイコン（2026-10-06）

音量・明るさ・バッテリーの割合に応じ、Material Symbolsを段階表示する関数を追加。バーとOSDで共用し、アイコンSVGは同じ固定Google Material Symbolsリビジョンから取得。

## セッションメニューの横並び化

操作一覧をレスポンシブな横方向グリッドにし、32pxアイコンと下側ラベルの独自セルへ変更。確認画面は従来どおり。
