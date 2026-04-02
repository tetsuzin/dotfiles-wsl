{ config, pkgs, user, ... }:

let
  homeDir = ../../HOME;
  wslHostDir = "/mnt/c/Users/${user}";
in {
  imports = [ ./packages.nix ];

  home.username = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "26.05";

  home.file = {
    # nix 管理下のファイルにパスを貼る
    ".gitconfig".source = "${homeDir}/git/.gitconfig";
    ".gitconfig.local".source = "${homeDir}/git/.gitconfig.local";
    ".config/mise/config.toml".source = "${homeDir}/mise/config.toml";

    # ホスト側のファイルとディレクトリにパスを貼る
    ".ssh".source = config.lib.file.mkOutOfStoreSymlink "${wslHostDir}/.ssh";
    ".kube/config".source = config.lib.file.mkOutOfStoreSymlink "${wslHostDir}/.kube/config";
  };

  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    initExtra =
      "#.baserc_base\n" + builtins.readFile "${homeDir}/bash/.bashrc_base"
      + "\n" +
      "#.bashrc_custom\n" + builtins.readFile "${homeDir}/bash/.bashrc_custom";
  };

  programs.mise.enable = true;
}
