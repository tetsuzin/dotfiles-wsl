#!/usr/bin/env bash
set -euo pipefail

function log() {
  echo "[setup] $*"
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

function run() {
  if [[ "${dry_run}" == "true" ]]; then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
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

[[ "${EUID}" -ne 0 ]] ||
  fail "root では実行しないでください。通常ユーザーで実行してください"

user="$(id -un)"

# 受けとった引数を表示
log "--debug=${debug}"
log "--dry-run=${dry_run}"

# デバッグ出力の有効化
if [[ "${debug}" == "true" ]]; then
  set -x
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${SCRIPT_DIR}/dotfiles"
NIX_DIR="${SCRIPT_DIR}/nix"
flake_attr="${NIX_DIR}#homeConfigurations.${user}.activationPackage"

# 変数の表示
log "SCRIPT_DIR: ${SCRIPT_DIR}"
log "DOTFILES_DIR: ${DOTFILES_DIR}"
log "NIX_DIR: ${NIX_DIR}"
log "USER: ${user}"

log ""
log "==> Lix のインストール確認"
if ! command -v nix &>/dev/null; then
  log "    Lix をインストールします..."
  if [[ "${dry_run}" == "true" ]]; then
    log "    [dry-run] curl https://install.lix.systems/lix | sh -s -- install --no-confirm"
  else
    curl -sSf -L https://install.lix.systems/lix |
      sh -s -- install --no-confirm
  fi
  if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck disable=SC1091
    run source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
else
  log "    Lix はインストール済みです: $(nix --version)"
fi

log ""
log "==> home-manager の実行"

if [[ "${dry_run}" == "true" ]] && ! command -v nix &>/dev/null; then
  run nix build --no-update-lock-file --dry-run "${flake_attr}"
elif [[ "${dry_run}" == "true" ]]; then
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
if [[ -e "${HOME}/.nix-profile/etc/profile.d/hm-session-vars.sh" ]]; then
  # shellcheck disable=SC1091
  run source "${HOME}/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi

log ""
log "==> DotfilesLinker の実行"

export DOTFILES_ROOT="${DOTFILES_DIR}"
if [[ "${dry_run}" == "true" ]] && ! command -v DotfilesLinker &>/dev/null; then
  log "    [dry-run] DotfilesLinker --dry-run"
elif [[ "${dry_run}" == "true" ]]; then
  DotfilesLinker --dry-run
else
  DotfilesLinker
fi

log ""
log "==> セットアップ完了"
log "    新しいシェルを起動するか、以下を実行してください:"
log "    exec bash"
