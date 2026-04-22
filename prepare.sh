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

function update_apt() {
  # apt でインストールするパッケージ
  packages=(
    libatomic1
  )
  sudo apt update -y
  sudo apt upgrade -y
  sudo apt-get install -y "${packages[@]}"
  sudo apt autoremove -y
}

echo "========================================"
echo "initialize .bashrc"
echo "========================================"
initialize_bashrc

echo ""
echo "========================================"
echo "update apt-get packages"
echo "========================================"
update_apt
