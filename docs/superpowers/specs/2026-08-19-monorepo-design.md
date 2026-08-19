# dotfiles monorepo 統合 設計書

日付: 2026-08-19
ステータス: 承認済み(チャットにて)

## 目的

dotfiles-linux / dotfiles-mac に分かれているリポジトリを dotfiles に統合し、
パッケージの追加・バージョンの統一を 1 箇所で管理できるようにする。

現状の問題:

- flake.lock が OS ごとに分かれており、同じパッケージでも実バージョンがずれる
- 共通パッケージ (k8s.nix は完全同一) を 2 リポジトリに重複して管理している
- 共通設定 (starship.toml, mise/config.toml) が微妙に乖離している

## 方針

- 統合先は既存の `dotfiles` リポジトリ (名前変更なし)
- dotfiles-linux / dotfiles-mac は**スナップショットで取り込む** (履歴は移さない)。
  旧リポジトリは GitHub 上でアーカイブし、履歴の参照先として残す
- flake は 1 つに統合し、flake.lock を単一化する

## ディレクトリ構成

```
dotfiles/
├── setup.sh                  # clone/pull ロジックを削除。OS 判定して委譲するだけ
├── scripts/
│   ├── _functions
│   ├── switch.sh             # 共通ドライバ (OS_DIR 前提を削除)
│   ├── prepare-linux.sh
│   ├── prepare-mac.sh
│   ├── switch_hooks-linux.sh
│   └── switch_hooks-mac.sh
├── nix/
│   ├── flake.nix             # 統合 flake (下記)
│   ├── flake.lock            # 1 つに統一
│   ├── home-manager/
│   │   ├── common.nix        # 共通設定 (mise 有効化など)
│   │   ├── linux.nix         # WSL リンク・bash 設定・linux 固有部
│   │   ├── darwin.nix        # themes・mac 固有部
│   │   └── packages/
│   │       ├── packages.nix  # 共通リスト + OS/WSL 分岐
│   │       ├── k8s.nix       # 完全同一だったものを 1 本化
│   │       └── dotfiles-linker.nix  # platform 分岐で 1 本化
│   └── nix-darwin/           # dotfiles-mac から移動 (_main.nix, homebrew.nix, system.nix)
└── dotfiles/
    ├── common/
    │   ├── dotfiles_ignore
    │   └── HOME/             # starship.toml, mise, .claude, .codex など両 OS 共通
    ├── linux/
    │   └── HOME/             # .bashrc_base, .bashrc_custom, .bash_profile_custom
    └── mac/
        └── HOME/             # .zshrc_custom, .zprofile_custom, ghostty
```

## flake.nix

- inputs: 両リポジトリの和集合
  (nixpkgs, home-manager, nix-darwin, nix-homebrew, ezaThemes, lazyvimStarter)
- outputs:
  - `homeConfigurations.tetsuzin` / `homeConfigurations.tetsuzin-wsl` (x86_64-linux)
  - `darwinConfigurations.shion` (aarch64-darwin)
- switch_hooks の attr 解決ロジック (WSL 判定 / `scutil` によるホスト名) は現状のまま
- linux は Lix チェック、mac は素の Nix という差もフックに残す

## dotfiles/ (DotfilesLinker 対象)

- common / OS 別の 3 ディレクトリ構成。使わないシェルの rc ファイルが
  他 OS の `$HOME` にリンクされないようにするための分離
- switch.sh は DotfilesLinker を 2 回実行する:
  1. `DOTFILES_ROOT=dotfiles/common`
  2. `DOTFILES_ROOT=dotfiles/<os>`
- `.bashrc_base` はリンク対象外 (dotfiles_ignore 済み、nix の `builtins.readFile` が読む)。
  `linux/` 配下に置き、nix 側の参照パスを合わせる

## 設定ファイルの統一

- starship.toml: 差分はスペース 2 箇所と `detect_env_vars` 1 行のみ → linux 版に統一
- mise/config.toml: ツールバージョンの和集合に統一
  (dotnet `["8", "10"]`, go, python, bat, biome, fzf など。不要なものは統合時にユーザーが取捨)
- 将来 OS ごとに内容を変えたいファイルが出た場合のみ、その時点で対応を検討する (YAGNI)

## 移行手順

1. dotfiles の作業ブランチ上に、両リポジトリの内容を上記配置でコピー
2. flake.nix を統合し、`nix flake check` と両構成の dry-run ビルドで検証
   (linux は WSL 上で実測、darwin は `nix build --dry-run` まで)
3. setup.sh / switch.sh から clone ロジックと OS_DIR を除去
4. WSL 上で `./setup.sh switch` を実行して実機検証 → merge
5. mac 実機で検証後、旧 2 リポジトリをアーカイブ

darwin 構成は linux 上でフル検証できないため、mac での初回 switch は
旧リポジトリを消す前 (ロールバック可能な状態) で行う。

## スコープ外

- git 履歴の統合 (subtree / filter-repo)
- HOME のオーバーレイ機構の一般化 (common + OS の 2 層で足りる)
- CI (update-flake-lock ワークフロー) の統合は移行完了後に別途行う
