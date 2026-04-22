{ pkgs, ... }:

let
  eza-themes = pkgs.fetchFromGitHub {
    owner = "eza-community";
    repo = "eza-themes";
    rev = "HEAD";
    hash = "sha256-toqj3bv2kCC2FHbGfeFpS3g9DoxQeZ7cwPYVpD8cfgg=";
  };
in {

  xdg.configFile = {
    "eza/theme.yaml".source = "${eza-themes}/themes/tokyonight.yml";
  };

}
