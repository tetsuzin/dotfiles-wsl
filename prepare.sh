#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function initialize_bashrc() {
  if [ -f "/etc/skel/.bashrc" ]; then
    echo "/etc/skel/.bashrc -> ${DOTFILES_DIR}/HOME/bash/.bashrc_base"
    cat "/etc/skel/.bashrc" > "${DOTFILES_DIR}/HOME/bash/.bashrc_base"
  fi
}

function update_apt() {
  sudo apt update -y
  sudo apt upgrade -y
  sudo apt autoremove -y

  # apt でインストールするパッケージ
  packages=(
    libatomic1
  )
  sudo apt-get install -y "${packages[@]}"
}

echo "========================================"
echo "initialize .bashrc"
echo "========================================"
initialize_bashrc

echo "========================================"
echo "update apt-get packages"
echo "========================================"
update_apt
