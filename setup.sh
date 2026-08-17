#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
NC=$'\033[0m'

function log_info() {
  printf '%s[INFO ]%s %s\n' "${GREEN}" "${NC}" "$*"
}

function fail() {
  printf '%s[ERROR]%s %s\n' "${RED}" "${NC}" "$*" >&2
  exit 1
}

function usage() {
  cat <<'EOF'
Usage: ./setup.sh <command> [args...]

Commands:
  prepare  ホストの準備 (パッケージマネージャと Nix 環境のインストール)
  switch   nix 構成の適用と dotfiles のリンク

OS (linux / mac) は自動判定し、os/<os> 配下のスクリプトへ委譲します。
EOF
}

[[ $# -ge 1 ]] || {
  usage
  exit 1
}

command="$1"
shift

case "$(uname -s)" in
  Linux) os_name="linux" ;;
  Darwin) os_name="mac" ;;
  *) fail "未対応の OS です: $(uname -s)" ;;
esac

case "${command}" in
  prepare | switch)
    log_info "OS: ${os_name}"
    git -C "${SCRIPT_DIR}" submodule update --init "os/${os_name}"
    exec "${SCRIPT_DIR}/os/${os_name}/scripts/${command}.sh" "$@"
    ;;
  -h | --help)
    usage
    ;;
  *)
    usage >&2
    fail "不明なコマンドです: ${command}"
    ;;
esac
