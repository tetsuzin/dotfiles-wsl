{ config, lib, user, pkgs, ezaThemes, lazyvimStarter, isWsl, ... }:

let
  dotfilesDir = ../../dotfiles/HOME;
  wslHostDir = "/mnt/c/Users/${user}";
  mkLink = config.lib.file.mkOutOfStoreSymlink;
in {
  imports = [
    ./packages/packages.nix
  ];

  home.username = user;
  home.stateVersion = "26.05";
  home.homeDirectory = "/home/${user}";

  # WSL では Windows ホスト側のファイルにパスを貼る
  home.file = lib.optionalAttrs isWsl {
    ".aws/credentials".source = mkLink "${wslHostDir}/.aws/credentials";
    ".kube/config".source = mkLink "${wslHostDir}/.kube/config";
  };

  xdg.configFile = {
    "nvim/".source = "${lazyvimStarter}/";
    "eza/theme.yaml".source = "${ezaThemes}/themes/tokyonight.yml";
  };

  programs.home-manager.enable = true;

  programs.mise = {
    enable = true;
    enableBashIntegration = false;
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    initExtra = builtins.readFile "${dotfilesDir}/.bashrc_base" + ''

      # mise を有効化
      eval "$(${pkgs.mise}/bin/mise activate bash)"

      # ユーザのカスタム設定を読み込む
      source ~/.bashrc_custom
    '';

    profileExtra = ''
      # ユーザのカスタム設定を読み込む
      source ~/.bash_profile_custom
    '';
  };

}
