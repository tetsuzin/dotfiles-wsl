#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/scripts/_functions"

function usage() {
  cat <<'EOF'
Usage: ./setup.sh <command> [args...]

Commands:
  prepare  ホストの準備 (システムパッケージと Lix のインストール)
  switch   home-manager の適用と dotfiles のリンク
EOF
}

[[ $# -ge 1 ]] || {
  usage
  exit 1
}

command="$1"
shift

case "${command}" in
  prepare | switch)
    exec "${SCRIPT_DIR}/scripts/${command}.sh" "$@"
    ;;
  -h | --help)
    usage
    ;;
  *)
    usage >&2
    fail "不明なコマンドです: ${command}"
    ;;
esac
