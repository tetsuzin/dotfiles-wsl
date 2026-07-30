#!/usr/bin/env bash
set -euo pipefail

function log() {
  echo "[install] $*"
}

function fail() {
  log "ERROR: $*" >&2
  exit 1
}

function usage() {
  cat <<'EOF'
Usage: install.sh [--debug[=true|false]] [--dry-run[=true|false]]
EOF
}

debug=false
dry_run=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --debug)
      debug=true
      if [[ "${2:-}" == "true" || "${2:-}" == "false" ]]; then
        debug=$2
        shift
      fi
      shift
      ;;
    --debug=*)
      debug="${1#*=}"
      shift
      ;;
    --dry-run)
      dry_run=true
      if [[ "${2:-}" == "true" || "${2:-}" == "false" ]]; then
        dry_run=$2
        shift
      fi
      shift
      ;;
    --dry-run=*)
      dry_run="${1#*=}"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "不明な引数です: $1"
      ;;
  esac
done

[[ "${debug}" == "true" || "${debug}" == "false" ]] ||
  fail "--debug には true または false を指定してください"
[[ "${dry_run}" == "true" || "${dry_run}" == "false" ]] ||
  fail "--dry-run には true または false を指定してください"

log "--debug=${debug}"
log "--dry-run=${dry_run}"

if [[ "${debug}" == "true" ]]; then
  set -x
fi

[[ "${EUID}" -ne 0 ]] ||
  fail "root では実行しないでください。先に通常ユーザーで prepare.sh を実行してください"

command -v nix &>/dev/null ||
  fail "Lix が見つかりません。先に prepare.sh を実行してください"

nix_version_output="$(nix --version)"
nix_version="${nix_version_output%%$'\n'*}"
[[ "${nix_version_output}" == *Lix* ]] ||
  fail "Lix 以外の Nix が使用されています: ${nix_version}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${SCRIPT_DIR}/dotfiles"
NIX_DIR="${SCRIPT_DIR}/nix"
user="$(id -un)"
flake_attr="${NIX_DIR}#homeConfigurations.${user}.activationPackage"

# 変数の表示
log "SCRIPT_DIR: ${SCRIPT_DIR}"
log "DOTFILES_DIR: ${DOTFILES_DIR}"
log "NIX_DIR: ${NIX_DIR}"
log "USER: ${user}"
log "LIX: ${nix_version}"

log ""
log "==> home-manager の実行"

if [[ "${dry_run}" == "true" ]]; then
  nix build --no-update-lock-file --dry-run "${flake_attr}"
else
  activation_package="$(
    nix build \
      --no-update-lock-file \
      --no-link \
      --print-out-paths \
      "${flake_attr}"
  )"
  HOME_MANAGER_BACKUP_EXT=backup "${activation_package}/activate"
fi

# home-manager によってインストールされたパッケージをパスに反映する
if [[ "${dry_run}" != "true" &&
  -e "${HOME}/.nix-profile/etc/profile.d/hm-session-vars.sh" ]]; then
  # shellcheck disable=SC1091
  source "${HOME}/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi

log ""
log "==> DotfilesLinker の実行"

export DOTFILES_ROOT="${DOTFILES_DIR}"
if [[ "${dry_run}" == "true" ]] && ! command -v DotfilesLinker &>/dev/null; then
  log "    DotfilesLinker は home-manager 適用後に利用可能になるためスキップします"
elif [[ "${dry_run}" == "true" ]]; then
  DotfilesLinker --dry-run
else
  command -v DotfilesLinker &>/dev/null ||
    fail "DotfilesLinker をPATHに反映できませんでした"
  DotfilesLinker
fi

log ""
log "==> セットアップ完了"
log "    新しいシェルを起動するか、以下を実行してください:"
log "    exec bash"
