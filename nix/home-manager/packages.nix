{ pkgs, ... }:

let
  kube-ps1 = pkgs.stdenv.mkDerivation {
    name = "kube-ps1";
    src = pkgs.fetchgit {
      url = "https://github.com/jonmosco/kube-ps1";
      rev = "HEAD";
      hash = "sha256-A71FJ5o4lVa6HuSZaFIjVtjXTXN/tnS7gLkWk+A+T70=";
    };
    installPhase = ''
      mkdir -p $out/share/kube-ps1
      cp kube-ps1.sh $out/share/kube-ps1/
    '';
  };
in
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
    kube-ps1
  ];
}
