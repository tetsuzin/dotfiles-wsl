{ pkgs, ... }:

{
  imports = [
    ./dotfiles-linker.nix
    ./k8s.nix
    ./wsl2-ssh-agent.nix
  ];

  home.packages = with pkgs; [
    git
    git-lfs
    gh
    curl
    wget
    eclint
    jq
    neovim
    docker-client
    act
    starship
    eza
    zoxide
    shfmt
    fastfetch.minimal
    lazygit
    yazi
    fzf
    bat
    ghq
    btop

    # AWS
    awscli2
    aws-vault
  ];
}
