{ pkgs, ... }:

let
  wsl2-ssh-agent = pkgs.stdenv.mkDerivation {
    name = "wsl2-ssh-agent";
    src = pkgs.fetchurl {
      url = "https://github.com/mame/wsl2-ssh-agent/releases/download/v0.9.7/wsl2-ssh-agent";
      hash = "sha256-KBxk9geVmN4aRVKS1TPzriGDeYCj0wEgdLwUrWlTJdg=";
    };
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      cp -v $src $out/bin/wsl2-ssh-agent
      chmod +x $out/bin/wsl2-ssh-agent
    '';
  };
in
{
  home.packages = [ wsl2-ssh-agent ];
  home.file.".ssh/wsl2-ssh-agent".source = "${wsl2-ssh-agent}/bin/wsl2-ssh-agent";
}
