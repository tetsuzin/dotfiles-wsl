{ pkgs, ... }:

{
  home.packages = with pkgs; [
    git
    git-lfs
    gh
    curl
    wget
    eclint
    jq
    docker-client
    act
    starship

    # AWS
    awscli
    aws-vault
  ];
}
