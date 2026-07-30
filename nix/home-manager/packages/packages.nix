{ pkgs, ... }:

{
  imports = [
    ./dotfiles-linker.nix
    ./k8s.nix
  ];

  home.packages = with pkgs; [
    git
    git-lfs
    gh
    curl
    wget
    wsl2-ssh-agent
    nh
    eclint
    jq
    neovim
    docker-client
    act
    starship
    eza
    zoxide
    shfmt
    fastfetch-unwrapped
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

  # シンボリックリンクを貼っておく
  home.file.".ssh/wsl2-ssh-agent".source = "${pkgs.wsl2-ssh-agent}/bin/wsl2-ssh-agent";
}
