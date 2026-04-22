{ pkgs, ... }:

let
  dotfiles-linker = pkgs.stdenvNoCC.mkDerivation rec {
    name = "dotfiles-linker";
    version = "0.4.0";
    src = pkgs.fetchzip {
      url = "https://github.com/guitarrapc/DotfilesLinker/releases/download/${version}/DotfilesLinker_linux_amd64.tar.gz";
      hash = "sha256-BixgridkElrOYb9gMbkFsoDcPa7v3zJH0qTX/A+1JFo=";
    };
    installPhase = ''
      install -Dm755 DotfilesLinker $out/bin/DotfilesLinker
    '';
  };

in
{
  home.packages = [ dotfiles-linker ];
}
