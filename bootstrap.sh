#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/scripts/_functions"

version="v0.0.1"

# nix/flake.nix が x86_64-linux 固定のため、他アーキテクチャには対応しない
[[ "$(uname -m)" == "x86_64" ]] ||
  fail "未対応のアーキテクチャです: $(uname -m)"

rid="linux-x64"
sha256="b1e58ef04815ab50c3ede551cae8549dbc65bd5f151c4470327b96915c3b88b2"

archive="ScriptCommandRunner-${version}-${rid}.tar.gz"
url="https://github.com/tetsuzin/ScriptCommandRunner/releases/download/${version}/${archive}"

work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

command -v curl &>/dev/null ||
  fail "curl が必要です。sudo apt-get install -y curl ca-certificates を実行してください"

log_step "ScriptCommandRunner ${version} (${rid}) のダウンロード"
curl -fsSL "${url}" -o "${work_dir}/${archive}"

log_step "チェックサムの検証"
echo "${sha256}  ${work_dir}/${archive}" | sha256sum -c - >/dev/null ||
  fail "チェックサムが一致しません: ${archive}"

log_step "setup の配置"
tar -xzf "${work_dir}/${archive}" -C "${work_dir}" ScriptCommandRunner
install -m 755 "${work_dir}/ScriptCommandRunner" "${SCRIPT_DIR}/setup"

log_step "完了しました"
log_info "続けて ./setup prepare を実行してください"
