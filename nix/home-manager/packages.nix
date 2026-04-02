{ pkgs, ... }:

{
  home.packages = with pkgs; [
    git
    git-lfs
    gh
    curl
    wget
    eclint

    # k8s
    kubectl
    kubectx
  ];
}
