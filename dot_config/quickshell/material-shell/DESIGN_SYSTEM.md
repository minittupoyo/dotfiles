# Material Shell デザインシステム v3 — M3 Expressive

2026-10-07。独自シェルへの移行を実装する前に定義した基準。現行UIの追記を含む。
この文書を意図・仕様の正本、Theme.qmlを実装トークンの正本とする。
変更時は両方を更新する。個別画面で独自の配色や余白を追加しない。

## 方向性と既存の決定

Material 3 Expressiveの色・形状・操作グループ・物理ベースの動きを採用する。
デスクトップの密度を維持し、重要な操作だけ色・形・文字の強さを上げる。
バーは全幅、48px高、枠線なし。透明素材・ぼかし・グラデーション・強い影は使わない。
Interを主フォントとし、日本語はNoto Sans JP。OSデフォルトの部品を露出させない。
構造アイコンはMaterial Symbols Outlined（FILL 0 / wght 400 / GRAD 0 / opsz 24）、絵文字禁止。
アプリのロゴは識別のため公式desktop entryのアイコンを使用し、構造アイコンと区別する。

## トークンの構造

Theme.qml内で「基礎値 → 意味を持つ役割 → 部品」を分ける。
色の16進値・フォント名・新しい寸法はTheme.qmlに置く。
QML部品ではThemeの役割を参照する。0、1、比率、動的レイアウト算出は例外。
パディング用に無関係なトークンを使わない（角丸を余白に流用する等）。

### 色の役割（ダーク基準）

| 役割 | 色 | 用途 |
|---|---|---|
| surface | #121411 | 背景 |
| surfaceContainer | #1e211d | バー |
| surfaceContainerHigh | #282b26 | パネル・ダイアログ |
| surfaceContainerHighest | #333630 | 入力面 |
| surfaceText（MD3 onSurface） | #e2e3dc | 主テキスト |
| surfaceVariantText（onSurfaceVariant） | #c3c8bd | 補助テキスト・アイコン |
| outline | Matugenのoutline | オフ状態のスイッチ境界、操作境界 |
| outlineVariant | #43483f | 内部分割線。バー外枠には使わない |
| primary | #b4cea5 | フォーカス・主操作 |
| secondaryContainer | #3c4b37 | 選択中の項目 |
| secondaryContainerText | #d8e7cc | 選択中の文字 |
| error | #ffb4ab | エラー・破壊的操作 |
| errorText / errorContainer / errorContainerText | Matugenのon_error / error_container / on_error_container | 破壊操作の強調/通常ボタン |
| inverseSurface / inverseSurfaceText | #e2e3dc / #2f322c | プレーンツールチップ |
| scrim | 黒32% | モーダル外の背景 |

ライトモードは同じMatugenソース色からscheme-tonal-spotのlightロールを生成する。surfaceは#f8f9ff、surfaceContainerは#eceef4、主文字は#191c20、補助文字は#42474eを基準とし、全コンポーネントは同じ意味ロールを参照する。ライト/ダーク両方のパレットを保存し、モード選択時に即時切り替える。

QMLのonX命名との衝突を避けるため、onSurface等はsurfaceTextのように表す。
通常文字は背景とのコントラスト4.5:1以上、意味を持つアイコン・フォーカスは3:1以上。

### 寸法・文字・形状

- 基本余白: 4 / 8 / 12 / 16 / 24 / 32px。4pxを基本単位にする。
- バー外側の左右余白16px、ランチャーとワークスペースは32px角。
- ランチャーのアイコン16px、左右パディング6px。セパレーター左右12px。
- ワークスペース間4px、ウィンドウ名との間16px。
- パネル外側余白24px、内容余白24px、セクション間16px、行間4px。
- ランチャー標準幅560px。画面幅から左右24pxを引いた範囲に縮める。
- ランチャー標準最大高640px。画面高さから上下24pxを引いた範囲に縮める。
- 行高56px、検索欄高48px、通常ボタン高40px、アイコンボタン40px。
- 文字: MD3のDisplay / Headline / Title / Body / Label各スケールと行高をTheme.qmlで定義。デスクトップ密度ではバー/補助Label Medium 12px、本文Body Medium 14px、入力Body Large 16px、見出しTitle Large 22pxを使う。
- ウェイト: 本文Regular、ラベル/操作Medium、見出しDemiBold。
- 角丸: ツールチップ4px、リスト行8px、検索欄24px、ダイアログ32px、ボタンは高さの半分。
- アイコン: バー16px、パネル20px、アプリロゴ28px。
- 動き: 色の変化160ms。押下時の形状変化はSpringAnimation（spring 4 / damping 0.85 / epsilon 0.1）。幾何寸法や文字位置は動かさない。

## 共通部品

### バー

常時表示は背景1面。外枠・下端線なし。操作可能な部分だけ状態レイヤーを持つ。
位置やサイズをホバーで変えない。ツールチップは500ms後に表示し、離れたら閉じる。

### ボタンと選択行

通常のtonal buttonはsecondaryContainer/onSecondaryContainer、強調操作はprimary/onPrimary。破壊操作はerrorContainer/onErrorContainer、最終確認はerror/onErrorを使う。状態レイヤーは各面の対になる前景色を使い、hoverは8%、pressedは10%。
キーボードフォーカスはprimaryの1px境界で示す。マウス押下時は対象からフォーカスを外し、クリック後に境界を残さない。disabledは操作不可、前景38%、状態レイヤーなし。
主操作・補助操作・破壊的操作を文字と色で区別し、アイコンだけで判断させない。

スイッチはオフ時にsurfaceContainerHighestのトラックとoutline境界、on時にprimary/onPrimaryを使う。選択時のcheckはthumb内に置く。無効時は入力・キーボード操作・hover状態をすべて止める。

### タブ

コントロールパネルのタブは左側の縦型ナビゲーションレールに置き、アイコンと短い可視ラベルをセットで表示する。選択中はsecondaryContainerのfull pill indicatorとonSecondaryContainerを使う。画面高が足りない場合はレールを縦スクロールし、本文は独立してスクロールできる。Accessible.nameにも表示ラベルを設定する。

### 検索欄

filled surfaceContainerHighest、24px角丸、16px文字、20px検索アイコン。
フォーカス中は下端2pxのprimary。placeholderは「アプリを検索」。
検索クリアは40px角のアイコンボタン。検索中も入力欄にフォーカスを残す。IME変換中のEnter・矢印は検索や起動に使わない。

### 専用パネル

ランチャー、セッション、壁紙セレクターなどは共通PanelFrameを使い、フォーカスした画面に1枚だけ表示する。通常の状態操作はバーに接続したコントロールパネルへ集約する。
面はsurfaceContainerHigh、32px角丸、内容24px。外枠と追加の影なし。
画面全体のscrimで外側クリックを検出。Escまたは外側クリックで閉じる。
Escはパネル内容のKeysで処理する（この環境ではQML Shortcutの終了処理にクラッシュが発生したため使用しない）。
閉じた後はアプリへの入力を妨げない。バーのレイアウト領域を増やさない。
モニターが消えた場合も残存画面で閉じる/再表示できること。

### ランチャー

見出し「アプリケーション」、検索欄、検索結果一覧、操作案内の順。
各行はアプリロゴ、アプリ名、補助説明。長い名前は省略し、横スクロールしない。
選択行はsecondaryContainer。マウスと上下キーで選択、Enterで起動、Escで閉じる。
0件は「一致するアプリがありません」と表示し、起動操作は無効。
起動にはdesktop entryの解析済みcommand/workingDirectoryを使う。
Terminal=trueはkittyを介して実行する。生のExec文字列をシェルで評価しない。
検索はアプリ名・説明・キーワード・IDを対象とする。

### セッション・設定（後続段階）

同じPanelFrame・入力欄・ボタン・リストを使う。
電源オフ・再起動・ログアウトには選択と最終実行を分けた確認画面を置く。
設定は保存状態とエラーを表示し、再起動後の復元を保証する。

## 実装時の確認

1. この文書とTheme.qmlを先に読む。
2. 共通部品を再利用し、独自の色・寸法を画面内に直接記述しない。
3. QMLロードエラーがないこと、2画面、キーボード、Esc、外側クリックを確認する。
4. 日本語検索・IME中のEnter・0件・長い文字列を確認する。
5. 見た目が変わる場合は画面キャプチャを確認する。
6. 移行済み機能とNoctaliaに残る機能をMIGRATION.mdへ記録する。

参照: https://m3.material.io/styles/color/the-color-system 、https://m3.material.io/components/tooltips/specs

## 壁紙からの動的配色

Matugenのscheme-tonal-spot、light/dark、標準コントラスト0を生成して使用する。
壁紙の最多のソース色（index 0）を自動選択し、過度な彩度を避ける。
上記の固定色は初回・パレット未作成時のフォールバック。生成したMD3の
on_surface / on_surface_variant / on_secondary_container / inverse_on_surfaceを
surfaceText / surfaceVariantText / secondaryContainerText / inverseSurfaceTextへ対応させる。
バー・パネル・検索・状態レイヤー・構造アイコン・ツールチップを一括更新する。
アプリ公式ロゴ、scrimの黒32%、寸法・形状・書体は変えない。
ライト/ダーク双方をXDG_STATE_HOME/material-shell/palette.jsonへ保存する。全必須色の検証後にアトミック保存し、
不正なJSON・画像・生成失敗では直前の配色を保持する。全画面共通のパレットとし、
awwwの先頭出力の壁紙を5秒間隔で確認する。画像が変わった時だけ再生成する。
壁紙描画はawwwを使用し、色生成・保存・QMLへの適用は独自実装が担う。

## 壁紙セレクター

共通PanelFrameを使用し、幅880px・最大高680px。左に検索とサムネイル付き一覧、
右に16:9の画像プレビューとファイル名・適用ボタンを置く。一覧幅は内容幅の42%、
行高72px、サムネイル80×48px。狭い画面ではプレビューを隠し一覧を優先する（内容幅600px未満）。
選択だけでは壁紙を変更しない。Enterまたは「壁紙と配色を適用」で確定する。
↑↓で選択、Esc/外側クリックで閉じる。適用中は再実行を無効化し、成功・失敗を表示する。
検索対象は名前とパス、IME変換中のEnterは適用しない。
フォルダーのパス入力と「読み込む」で一覧を切り替え、成功時のみ検索先を保存する。
初期検索先は~/Pictures/Wallpapers、~/Wallpapers、/usr/share/backgroundsと現在の壁紙。
PNG/JPEG/WebP/BMPを再帰走査し、シンボリックリンクのディレクトリは辿らない。
適用は既存palette.pyを使い、全画面共通の壁紙とMD3配色を更新する。

## 壁紙描画バックエンド

awww-daemonをbackground layerで使用する。静止画はcrop、transition-type randomとし、
壁紙の切り替えごとにawwwのランダムなトランジションを使用する（ユーザー指定）。
シェルUIの動きとは独立して扱い、時間・FPSはawwwの既定値を使用する。壁紙セレクターでは全出力に同じ画像を適用する。
XDG_STATE_HOME/material-shell/wallpaper.jsonへアトミック保存し、起動時に復元する。
5秒監視でデーモン停止・未設定の追加出力を検出し、保存画像を復元する。
Noctaliaのwallpaper.enabledはfalseにし、描画の競合を防ぐ。

## 残りのシェル機能

ランチャー・セッション・壁紙セレクター・トレイメニューなどの専用UIはPanelFrameとShellButtonを使用。
専用パネルは標準幅560px、最大高640px、スクロール可能な本文、40pxボタン、既存の文字・間隔・色を共用する。
コントロールパネルはスクラムなしでバー下端に接して表示する。上辺の角丸をなくし、surfaceContainerでバーと背景色を揃え、画面端から24px以上離し、外側クリックとEscで閉じる。壁紙セレクターなど大きな専用パネルも同じPanelFrameの接続・アニメーション規則を使う。Caelestia shellのoffsetScale方式を参考に、閉じたパネルを最終位置より高さ+4pxだけバーの背後へ退避し、開閉時に320msのOutCubicで下へ移動しながらフェードする。バーに接するパネルは表面だけをフェードして全画面合成を避ける。reducedMotionでは移動を即時化する。
設定のスイッチは48×28px、つまみ20px。数値は増減ボタン、列挙値は選択ボタンで操作し、
保存ボタンで検証・アトミック保存後に反映する。設定先はXDG_CONFIG_HOME/material-shell/settings.json。
表示項目、ワークスペース数、通知DND、音量OSD、自動ロック/消灯時間を提供する。ライト/ダークの選択は即時保存・反映する。バー日時はカレンダーアイコンを付けず、`yyyy/MM/dd HH:mm`形式で表示する。
自動ロック・消灯の既定は無効（現在の環境と同じ）。
セッションはロック・サスペンド・ログアウト・再起動・電源オフ。ロック以外は別の確認画面を表示し、
最初の選択で実行しない。失敗はパネル内へ表示。サスペンドは全画面ロック完了後に実行する。
クリップボードはcliphist+wl-clipboardを基盤とし、名前検索・選択・再コピー・個別削除に対応。
履歴は100件、ファイル権限はユーザーのみ。画像等はバイナリのまま再コピーする。
通知はNotificationServerで受信、PlainTextで表示し、アクションと閉じる操作を持つ。
トーストは幅360px、最大3件、右上にバー下の余白16pxから配置。通常は6秒表示、
criticalとtimeout 0は自動で消さない。期限切れの通知も履歴に残し、履歴は100件まで保存。
DND中はトーストを出さず履歴へ保存する。通知センターから履歴消去とDNDを操作できる。
OSDは幅320px、画面下余白32px、音量・ミュート・明るさ変更を表示し、1400ms後に閉じる。高さはアイコンとラベル/波形プログレスの自然高に上下各16pxを足して算出し、上下余白を一致させる。
曲変更時のメディアOSDは幅400px、56px角・8px角丸のアンチエイリアス付きアルバムアート、曲名とアーティストを表示し、4000ms後に閉じる。画像はスムーズ補間とミップマップを使う。アートワークがない場合はmusic_noteを表示する。音量・明るさOSDとは表示モードを分ける。
トレイはアプリ公式アイコン16px、32pxの操作面、独自のMD3メニューを使用する。
左クリックでアプリ操作、右クリックでメニュー、中クリックとスクロールも対応。
キャプチャは独立実行ファイル~/.local/bin/material-screenshotからgrim+slurpを起動し、現在のディスプレイ・全ディスプレイ・範囲を撮影する。Pictures/ScreenshotsにPNG保存してwl-copyで画像コピーする。範囲選択はドラッグして離すと確定し、Escまたは60秒のタイムアウトで終了する。slurpをQuickshellの子プロセスとして直接起動せず、パネルからは独立実行ファイルを起動する。撮影開始時はパネルを即時に非表示にし、保存結果とコピー失敗はOSDで知らせる。
ロックは別Quickshell設定material-lockのWlSessionLock+PAMを使用し、バー再起動と分離する。
ロック画面はsurface背景、時計・ユーザー・filledパスワード入力・解除ボタンで構成。
PAM成功時のみ解除する。外側クリック・Escでは解除しない。検証プレビューはロックもPAM認証も行わない。
swayidleがlogindのロック要求とサスペンド前のロックを扱い、secure確認まで待機する。

### 画面幅に応じた表示

1700px未満でCPU・メモリ、1500px未満でネットワーク、1400px未満でクリップボード・キャプチャのバー入口、1100px未満で壁紙入口・トレイを省略する。機能はコントロールパネルのタブまたは対応するキーバインドから利用可能。全パネルは共通のフォーカス・Esc・外側クリック規則に従う。

アイコン縮小時も操作面・行高・パディングは維持し、クリックやキーボード操作のしやすさを保つ。

### オーディオパネル

コントロールパネルの音声タブ。出力・入力を分け、現在の機器名、音量0〜100%、ミュート、既定機器の選択を表示する。機器がない場合は説明を表示し操作を無効化。音量は即時反映し、増幅は行わない。スライダーは48pxの操作領域で、下記Expressiveスライダー仕様に従う。Tabと左右キー（5%）、Home/Endで操作し、フォーカスを表示する。機器の一覧はスクロール可能。バーの音量クリックは音声タブを開き、スクロールによる音量変更は維持する。

### Now Playing

バー左側のウィンドウ名の隣に、MPRISプレイヤーがある場合のみ音楽アイコンと曲名を表示する。幅上限200px、省略表示、1700px未満ではアイコンのみ。クリックでコントロールパネルのメディアタブを開く。アートワーク160px、曲名・アーティスト・アルバム、再生/一時停止・前/次、再生位置と経過/総時間、プレイヤー選択を表示。画像の失敗・未提供時は音楽アイコン。再生中を自動優先し、手動選択はプレイヤーが存在する間維持する。非対応操作は無効化、未接続時はsecondaryContainerの80px円形面に36px音楽シンボル、幅320px以内の中央揃え見出し・説明文を表示する。画像は非同期・読込サイズ制限。位置監視はタブ表示中のみ1秒間隔。共通スライダー・フォント・アイコン・MD3トークンを使用する。

### Now Playingの表示位置（更新）

メディア操作は独立ポップオーバーからコントロールパネル内のタブへ統合。曲名チップとIPCから同じタブを開く。

## M3 Expressive実装規則

主操作はprimary/onPrimary、選択行はsecondaryContainer/onSecondaryContainer。primaryContainer/onPrimaryContainerもパレットへ追加。旧パレットでは安全な既存ロールへフォールバック。Inter・Noto Sans JP、小さいアイコン（16/20px）、48pxの枠線なしバーを維持する。
ボタンは丸い形から押下中8px角丸へモーフィング。通常ボタンはトーナル面。検索欄は24px角丸、見出し22px/DemiBold。ワークスペースは選択中primary/onPrimary、選択中12px角丸・非選択ピル。
Now Playingは前/再生/次を背景つきの連結ツールバーにまとめ、再生ボタンの操作幅を64pxにする。メディアタブはコントロールパネル内に表示する。スイッチはprimary/onPrimary、つまみ移動はスプリング。色のアニメーションはオーバーシュートしない160ms。
これはQt Quick向けのExpressive適用であり、GoogleのAndroid用物理トークンの完全移植ではない。Theme.reducedMotionをtrueにすると形状・色のアニメーションを停止する。
公式参照: https://m3.material.io/styles/motion 、https://m3.material.io/components/button-groups/overview

色の役割: https://m3.material.io/styles/color/the-color-system 、
文字スケール: https://m3.material.io/styles/typography/applying-type 、
タブ: https://m3.material.io/components/tabs/overview 、
スイッチ: https://m3.material.io/components/switch/overview

### Expressiveスライダー・プログレス（更新）

スライダーは48px操作面、16pxトラック、4×44pxの縦ハンドル、ハンドルとの隙間6px、内側角丸2px、外側角丸8px、端点4px。ハンドル押下中は幅2pxへ変化。進行部primary、残りsecondaryContainer、端点は各面の対の文字色。両端でも負の寸法を生成しない。ドラッグは遅延なく追従、左右5%・Home/Endを維持。値ラベルは各利用箇所に残す。
プログレスは共通ExpressiveProgress。トラック4px、進行部/残りの隙間4px、終端マーカー4px。波形は振幅3px・波長40pxで確定値を表示、全高10px。OSDへ適用。表示中だけ波の位相を進める。アニメーションの詳細は下記の更新仕様に従う。0/100%・無効状態を正しく表示。直線表示もwavy=falseで利用可能。
参照: https://github.com/material-components/material-components-android/blob/master/docs/components/Slider.md 、https://github.com/material-components/material-components-android/blob/master/docs/components/ProgressIndicator.md

Now Playingの再生位置はExpressiveProgressの波形表示を使用。プレイヤーがシークと位置設定に対応する場合、クリック・ドラッグと左右/Home/Endキーで操作できる。非対応時は表示専用。経過/総時間と再生・前/次の操作は維持。音量はVolumeSliderを継続使用。

波形のアクティブインジケーターは公式Android標準トークンに合わせ線幅4px・振幅3px・確定進捗の波長40pxへ修正。両端はround cap、位相はバー全体の座標に固定し、進行部分が伸びても波の位置はずれない。微小な進捗は線幅を縮小して丸い点を表示する。
根拠: https://github.com/material-components/material-components-android/blob/master/lib/java/com/google/android/material/progressindicator/res/values/tokens.xml

### 波形のアニメーション

公式DeterminateDrawableの構成に合わせ、進捗長はオーバーシュートしないスプリング、振幅は500msの遷移、位相は等速で流す。Qt向けのスプリングはspring 4 / damping 1 / epsilon 0.0001。公式はwaveSpeedを設定可能としているため、本シェルでは40px/秒（1周期/秒）を採用する。10〜90%で振幅3px、開始/完了付近は500msで直線へ変化。メディアタブは再生中かつタブ表示中のみ位相を進め、一時停止中は位相を保持する。OSDも表示中のみ動かす。reducedMotionでは位相・長さ・振幅のアニメーションを停止する。
参照: https://github.com/material-components/material-components-android/blob/master/lib/java/com/google/android/material/progressindicator/DeterminateDrawable.java

### 割合を示すアイコン

音量はミュート/0%をvolume_off/volume_mute、1–50% volume_down、51–100% volume_upで表す。明るさは0–25% brightness_low、26–70% brightness_medium、71–100% brightness_high。バッテリーはbattery_0_bar〜battery_6_bar、充電時はbattery_charging_20/30/50/60/80/90/fullを残量段階に応じて使う。バーとOSDは同じ判定関数を使う。

### セッション操作の一覧

ロック・サスペンド・ログアウト・再起動・電源オフは横方向のグリッドに配置。アイコン32pxを上、12pxラベルを下に置き、操作セルは88×96px、間隔8px。パネル幅に応じて5列から2列へ折り返す。クリックとEnter/Spaceに対応し、Tabのフォーカスを見せる。現在の確認画面とエラー表示は維持。
一覧時のセッションパネルは高さ208pxにする。確認画面は説明文と実行/キャンセルボタンに必要な高さを使う。
セッションセルのアイコンとラベルは一つの縦スタックとしてセル中央に配置し、上下の空き寸法を等しくする。ラベル枠は16px高。

### コントロールパネル

バー直下に幅560px・最大高680pxのPanelFrameとして表示し、左側に8つのアイコン＋ラベル（クイック、接続、音声、メディア、通知、設定、履歴、撮影）を縦型ナビゲーションレールで配置、右側に選択中の内容を表示する。選択中はsecondaryContainerのfull-pill indicatorとonSecondaryContainerを使う。レールと本文はそれぞれ独立してスクロールし、本文はパネル内側の上下paddingを除いた表示高を使い切る。クイックタブのタイルは余った高さを2行に均等配分する。狭い画面では画面端から24pxを保てる幅まで自動縮小する。バー上の各機能アイコンは対応するタブを直接開き、調整アイコンはクイックタブを開く。壁紙アイコンは専用セレクターを直接開く。同じタブのアイコンを再度押すと閉じる。ControlTileは最小72px高・8px間隔・24pxアイコンを使う。Wi-Fi、Bluetooth、通知一時停止を状態タイルで切り替える。音量・バックライト明るさと壁紙/配色への入口はクイックタブにまとめる。Bluetooth非対応やバックライトのない端末では該当操作を隠す/無効化する。撮影開始時はパネルを閉じる。セッション、ランチャー、トレイ、壁紙セレクターはその機能に適した専用UIを保つ。

### ネットワーク設定

接続タブにはWi-FiとBluetoothを独立したセクションで置き、各セクションの見出しにオン/オフ・接続中のネットワーク名または機器名を示す。Wi-Fi一覧は信号強度順、接続中を先頭に並べ、SSID・セキュリティ・信号強度・接続状態を表示する。接続中ネットワークはsecondaryContainerで選択状態を表し、行高56pxのsurfaceContainerHighカード、ロック/接続アイコン、行内の操作ボタンを使う。一覧は件数と本文の利用可能高に応じて伸縮し、行が収まらない場合は一覧内でスクロールする。保護された未登録ネットワークを選ぶと入力面surfaceContainerHighest・24px角丸のパスワード欄を同じ画面に開き、パスワード表示切り替えと接続/取消を用意する。Wi-FiスキャンとBluetooth検出はユーザー操作で開始し、処理中は重複操作を止める。Bluetooth一覧は接続済み・ペア設定済みを優先し、名前、接続状態、接続/切断、ペア設定解除を表示する。一覧・空状態・セクションの間隔は8px以内に抑え、内容が少ない場合に空白で外側スクロールを生じさせない。未接続やアダプター不在はタイル面の説明付き空状態として示す。エラーと完了状態は接続画面内に表示し、15〜30秒間隔の定期スキャンは行わない。
