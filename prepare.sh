#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${SCRIPT_DIR}/dotfiles"

function initialize_bashrc() {
  if [ -f "/etc/skel/.bashrc" ]; then
    echo "/etc/skel/.bashrc -> ${DOTFILES_DIR}/HOME/.bashrc_base"
    cat "/etc/skel/.bashrc" > "${DOTFILES_DIR}/HOME/.bashrc_base"
  fi
}

function install_apt_packages() {
  # apt でインストールするパッケージ
  local -a packages=(
    libatomic1
    openssh-server
  )

  # Ubuntu バージョンに応じた libicu パッケージを追加
  local ubuntu_version
  ubuntu_version=$(lsb_release -rs)
  if [[ "${ubuntu_version}" == 26.* ]]; then
    packages+=(libicu78)
  elif [[ "${ubuntu_version}" == 24.* ]]; then
    packages+=(libicu74)
  fi

  sudo apt-get update
  sudo apt-get install -y "${packages[@]}"
}

echo "========================================"
echo "initialize .bashrc"
echo "========================================"
initialize_bashrc

echo ""
echo "========================================"
echo "install apt packages"
echo "========================================"
install_apt_packages
