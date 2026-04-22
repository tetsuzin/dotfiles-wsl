{ pkgs, ... }:

let
  wsl2-ssh-agent = pkgs.stdenvNoCC.mkDerivation rec {
    name = "wsl2-ssh-agent";
    version = "0.9.7";
    src = pkgs.fetchurl {
      url = "https://github.com/mame/wsl2-ssh-agent/releases/download/v${version}/wsl2-ssh-agent";
      hash = "sha256-KBxk9geVmN4aRVKS1TPzriGDeYCj0wEgdLwUrWlTJdg=";
    };
    dontUnpack = true;
    installPhase = ''
      install -Dm755 $src $out/bin/wsl2-ssh-agent
    '';
  };
in
{
  home.packages = [ wsl2-ssh-agent ];
  home.file.".ssh/wsl2-ssh-agent".source = "${wsl2-ssh-agent}/bin/wsl2-ssh-agent";
}
