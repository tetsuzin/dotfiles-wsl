#!/usr/bin/env bash
set -euo pipefail

function log() {
  echo "[setup] $*"
}

# 引数のパース
while [[ $# -gt 0 ]]; do
  case $1 in
    --debug) _DEBUG=$2; shift 2;;
    --dry-run) _DRY_RUN=$2; shift 2;;
    *) shift ;;
  esac
done

USER="${SUDO_USER:-$(whoami)}"

# 受けとった引数を表示
log "--debug=${_DEBUG:="false"}"
log "--dry-run=${_DRY_RUN:="false"}"

# デバッグ出力の有効化
if [ "${_DEBUG}" = "true" ]; then
  set -x
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${SCRIPT_DIR}/dotfiles"
NIX_DIR="${SCRIPT_DIR}/nix"

dry_run_cmd=""
if [[ $_DRY_RUN == "true" ]]; then
  dry_run_cmd="echo $*"
fi

# 変数の表示
log "SCRIPT_DIR: ${SCRIPT_DIR}"
log "DOTFILES_DIR: ${DOTFILES_DIR}"
log "NIX_DIR: ${NIX_DIR}"
log "USER: ${USER}"

log ""
log "==> Lix のインストール確認"
if ! command -v nix &>/dev/null; then
  log "    Lix をインストールします..."
  $dry_run_cmd curl -sSf -L https://install.lix.systems/lix | sh -s -- install --no-confirm
  if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck disable=SC1091
    $dry_run_cmd source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
else
  log "    Lix はインストール済みです: $(nix --version)"
fi

log ""
log "==> home-manager の実行"

if command -v home-manager &>/dev/null; then

  nix flake update --flake "${NIX_DIR}"

  if [[ "${_DRY_RUN}" == "true" ]]; then
    home-manager switch --flake "${NIX_DIR}#${USER}" --dry-run
  else
    home-manager switch --flake "${NIX_DIR}#${USER}"
  fi

else
  log "    nix run home-manager switch を実行します..."
  nix run home-manager/master -- switch --flake "${NIX_DIR}#${USER}" -b backup
fi

# home-manager によってインストールされたパッケージをパスに反映する
if [ -e "${HOME}/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
  # shellcheck disable=SC1091
  source "${HOME}/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi

log ""
log "==> DotfilesLinker の実行"

export DOTFILES_ROOT="${DOTFILES_DIR}"
if [[ "${_DRY_RUN}" == "true" ]]; then
  DotfilesLinker --dry-run
else
  DotfilesLinker
fi

log ""
log "==> セットアップ完了"
log "    新しいシェルを起動するか、以下を実行してください:"
log "    exec bash"
