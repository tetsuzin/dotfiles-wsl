#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'
GREEN=$'\033[0;32m'
NC=$'\033[0m'

function log_info() {
  printf '%s[INFO ]%s %s\n' "${GREEN}" "${NC}" "$*"
}

function log_warning() {
  printf '%s[WARN ]%s %s\n' "${YELLOW}" "${NC}" "$*" >&2
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
    os_dir="${SCRIPT_DIR}/os/${os_name}"
    os_repo="https://github.com/tetsuzin/dotfiles-${os_name}.git"
    if [[ ! -e "${os_dir}/.git" ]]; then
      log_info "${os_repo} を clone します"
      git clone "${os_repo}" "${os_dir}"
    elif ! git -C "${os_dir}" pull --ff-only; then
      log_warning "os/${os_name} を更新できませんでした。現在の内容のまま続行します"
    fi
    exec "${os_dir}/scripts/${command}.sh" "$@"
    ;;
  -h | --help)
    usage
    ;;
  *)
    usage >&2
    fail "不明なコマンドです: ${command}"
    ;;
esac
