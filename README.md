# dotfiles

chezmoi で管理されているデスクトップ環境の設定ファイル群です。  
Material You (Material Design 3) をベースにした、一貫性のあるデザインのデスクトップ環境（Hyprland + Quickshell + Matugen）を構築します。

---

## 🌟 主な構成要素

- **Window Manager**: [Hyprland](https://hyprland.org/) (Lua 設定)
- **Shell / Lock Screen**: [Quickshell](https://quickshell.outfoxxed.me/)
  - `material-shell`: パネル、ウィジェット、コントロールセンター
  - `material-lock`: Material デザイントークンに準拠したロックスクリーン
- **Theming**: [Matugen](https://github.com/InioX/matugen)
  - 壁紙やカラーパレットから Material You カラーを自動抽出し、デスクトップおよび各アプリへ適用
- **Terminal**: [Kitty](https://sw.kovidgoyal.net/kitty/)
  - Matugen テンプレートによる動的カラーテーマ切り替えに対応
- **Backend / CLI Scripts**: Python & Shell (`~/.local/bin/executable_material-*`, `~/.local/lib/material-shell`)
  - 音声、ディスプレイ、クリップボード、スクリーンショット、テーマ・パレット管理などのヘルパー
- **Service Management**: systemd user services

---

## 📁 ディレクトリ構成

```text
.
├── .chezmoiignore              # chezmoi 適用除外リスト (README など)
├── .gitignore                  # Git 除外リスト
├── dot_config/
│   ├── hypr/                   # Hyprland 設定 (hyprland.lua)
│   ├── kitty/                  # Kitty 設定
│   ├── matugen/                # Matugen 設定およびテーマテンプレート
│   ├── quickshell/             # Quickshell 設定 (material-shell, material-lock)
│   └── systemd/user/           # systemd ユーザーサービス定義
└── dot_local/
    ├── bin/                    # material-* コマンドラインスクリプト群
    └── lib/material-shell/     # Python バックエンドモジュール
```

---

## 🚀 使い方

### インストール・適用 (chezmoi)

1. **chezmoi の初期化と適用**:
   ```bash
   chezmoi init https://github.com/minittupoyo/dotfiles.git
   chezmoi apply
   ```

2. **既存環境での更新確認と適用**:
   ```bash
   chezmoi status
   chezmoi diff
   chezmoi apply
   ```
