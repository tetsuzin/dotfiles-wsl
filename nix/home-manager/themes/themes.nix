{ ezaThemes, ... }:

{
  xdg.configFile = {
    "eza/theme.yaml".source = "${ezaThemes}/themes/tokyonight.yml";
  };
}
