#!/usr/bin/env bash
set -euo pipefail

function log() {
  echo "[setup] $*"
}

# 引数のパース
while [[ $# -gt 0 ]]; do
  case $1 in
    --debug) _DEBUG=$2; shift 2;;
    --apt-skip) _APT_SKIP=$2; shift 2 ;;
    --user) _USER=$2; shift 2 ;;
    *) shift ;;
  esac
done

# 受けとった引数を表示
log "--apt-skip=${_APT_SKIP:="false"}"
log "--debug=${_DEBUG:="false"}"
log "--user=${_USER:="$(whoami)"}"

# デバッグ出力の有効化
if [ "${_DEBUG}" = "true" ]; then
  set -x
fi

ALL_STEP_COUNT=6
APT_SKIP="${_APT_SKIP}"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER="${_USER}"

# 変数の表示
log "APT_SKIP: ${APT_SKIP}"
log "DOTFILES_DIR: ${DOTFILES_DIR}"
log "USER: ${USER}"

log "==> [1/${ALL_STEP_COUNT}] bashrc_base の初期化"
if [ -f "/etc/skel/.bashrc" ]; then
  cat "/etc/skel/.bashrc" > "${DOTFILES_DIR}/HOME/bash/.bashrc_base"
fi

log "==> [2/${ALL_STEP_COUNT}] apt パッケージの更新"
if [ "${APT_SKIP}" = "true" ]; then
  log "    apt-get update & upgrade をスキップします。"
else
  if command -v apt-get &>/dev/null; then
    log "    apt-get update & upgrade を実行します..."
    sudo apt-get update -y
    sudo apt-get upgrade -y
  else
    log "    apt が見つかりません。スキップします。"
  fi
fi

log ""
log "==> [3/${ALL_STEP_COUNT}] Lix のインストール確認"
if ! command -v nix &>/dev/null; then
  log "    Lix をインストールします..."
  curl -sSf -L https://install.lix.systems/lix | sh -s -- install --no-confirm
  if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck disable=SC1091
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
else
  log "    Lix はインストール済みです: $(nix --version)"
fi

log ""
log "==> [4/${ALL_STEP_COUNT}] home-manager の実行"
if command -v home-manager &>/dev/null; then
  log "    nix flake update を実行します..."
  nix flake update --flake "${DOTFILES_DIR}"
  log "    home-manager switch を実行します..."
  home-manager switch --flake "${DOTFILES_DIR}#${USER}"
else
  log "    nix run home-manager switch を実行します..."
  nix run home-manager/master -- switch --flake "${DOTFILES_DIR}#${USER}" -b backup
fi

log ""
log "==> [5/${ALL_STEP_COUNT}] mise install"
MISE_BIN=""
if command -v mise &>/dev/null; then
  MISE_BIN="$(command -v mise)"
elif [ -f "$HOME/.nix-profile/bin/mise" ]; then
  MISE_BIN="$HOME/.nix-profile/bin/mise"
elif [ -f "$HOME/.local/bin/mise" ]; then
  MISE_BIN="$HOME/.local/bin/mise"
fi

if [ -n "$MISE_BIN" ]; then
  log "    mise install を実行します..."
  "$MISE_BIN" install
else
  log "    mise が見つかりません。新しいシェルを起動後に手動で 'mise install' を実行してください。"
fi

log ""
log "==> [6/${ALL_STEP_COUNT}] セットアップ完了"
log "    新しいシェルを起動するか、以下を実行してください:"
log "    exec bash"
