{ config, user, pkgs, ... }:

let
  dotfilesDir = ../../dotfiles/HOME;
  wslHostDir = "/mnt/c/Users/${user}";
  mkLink = config.lib.file.mkOutOfStoreSymlink;
in {
  imports = [
    ./packages/packages.nix
    ./themes/themes.nix
  ];

  home.username = user;
  home.stateVersion = "26.05";
  home.homeDirectory = "/home/${user}";

  home.file = {
    # ホスト側のファイルとディレクトリにパスを貼る
    ".aws/credentials".source = mkLink "${wslHostDir}/.aws/credentials";
    ".kube/config".source = mkLink "${wslHostDir}/.kube/config";
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
