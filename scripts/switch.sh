#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/_functions"

function usage() {
  cat <<'EOF'
Usage: ./setup switch [--debug[=true|false]] [--dry-run[=true|false]] [--update[=true|false]]
EOF
}

debug=false
dry_run=false
update=false

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
    --update)
      update=true
      if [[ "${2:-}" == "true" || "${2:-}" == "false" ]]; then
        update=$2
        shift
      fi
      shift
      ;;
    --update=*)
      update="${1#*=}"
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
[[ "${update}" == "true" || "${update}" == "false" ]] ||
  fail "--update には true または false を指定してください"
[[ "${dry_run}" != "true" || "${update}" != "true" ]] ||
  fail "--dry-run と --update は同時に指定できません"

# shellcheck disable=SC2034 # _functions の log_debug が参照する
LOG_DEBUG="${debug}"
log_debug "--debug=${debug}"
log_debug "--dry-run=${dry_run}"
log_debug "--update=${update}"

if [[ "${debug}" == "true" ]]; then
  set -x
fi

[[ "${EUID}" -ne 0 ]] ||
  fail "root では実行しないでください。先に通常ユーザーで ./setup prepare を実行してください"

command -v nix &>/dev/null ||
  fail "Lix が見つかりません。先に ./setup prepare を実行してください"

nix_version_output="$(nix --version)"
nix_version="${nix_version_output%%$'\n'*}"
[[ "${nix_version_output}" == *Lix* ]] ||
  fail "Lix 以外の Nix が使用されています: ${nix_version}"

REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOTFILES_DIR="${REPO_DIR}/dotfiles"
NIX_DIR="${REPO_DIR}/nix"
user="$(id -un)"
flake_attr="${NIX_DIR}#homeConfigurations.${user}.activationPackage"

# 変数の表示
log_debug "SCRIPT_DIR: ${SCRIPT_DIR}"
log_debug "DOTFILES_DIR: ${DOTFILES_DIR}"
log_debug "NIX_DIR: ${NIX_DIR}"
log_debug "USER: ${user}"
log_debug "LIX: ${nix_version}"

if [[ "${update}" == "true" ]]; then
  echo
  log_step "flake.lock の更新"
  nix flake update --flake "${NIX_DIR}"
fi

echo
log_step "home-manager の実行"

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

echo
log_step "DotfilesLinker の実行"

export DOTFILES_ROOT="${DOTFILES_DIR}"
if [[ "${dry_run}" == "true" ]] && ! command -v DotfilesLinker &>/dev/null; then
  log_warning "DotfilesLinker は home-manager 適用後に利用可能になるためスキップします"
elif [[ "${dry_run}" == "true" ]]; then
  DotfilesLinker --dry-run
else
  command -v DotfilesLinker &>/dev/null ||
    fail "DotfilesLinker をPATHに反映できませんでした"
  DotfilesLinker
fi

echo
log_step "セットアップ完了"
log_info "新しいシェルを起動するか、以下を実行してください:"
log_info "exec bash"
