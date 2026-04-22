{ config, pkgs, ... }:

let
  kube-ps1 = pkgs.stdenvNoCC.mkDerivation {
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

  # K8s関連パッケージ
  k8sPackages = with pkgs; [
    kubectl
    kubectx
    kube-ps1
    krew
  ];

  # krewプラグイン
  krewPlugins = [
    "krew"
    "explore"
    "fuzzy"
    "iexec"
    "images"
    "lineage"
    "ktop"
    "neat"
    "rolesum"
  ];
in
{
  home.packages = k8sPackages;

  home.activation = {
    installKrewPlugins = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      KREW_BIN="${pkgs.krew}/bin/krew"
      if [ -f "$KREW_BIN" ]; then
        for plugin in ${toString krewPlugins}; do
          if ! "$KREW_BIN" list 2>/dev/null | grep -q "^$plugin$"; then
            $DRY_RUN_CMD "$KREW_BIN" install "$plugin"
          fi
        done
      fi
    '';
  };
}
