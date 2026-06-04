{ pkgs, ... }:

let
  lazyvim-starter = pkgs.fetchFromGitHub {
    owner = "LazyVim";
    repo = "starter";
    rev = "HEAD";
    hash = "sha256-QrpnlDD4r1X4C8PqBhQ+S3ar5C+qDrU1Jm/lPqyMIFM=";
  };
in {
  xdg.configFile = {
    "nvim/".source = "${lazyvim-starter}/";
  };
}
