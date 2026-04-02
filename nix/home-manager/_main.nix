{ config, user, ... }:

let
  homeDir = ../../HOME;
  wslHostDir = "/mnt/c/Users/${user}";
  dotfilesDir = "/home/${user}/github/dotfiles/HOME";
  mkLink = config.lib.file.mkOutOfStoreSymlink;
in {
  imports = [
    ./packages.nix
    ./k8s.nix
    ./wsl2-ssh-agent.nix
  ];

  home.username = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "26.05";

  home.file = {
    # nix 管理下のファイルにパスを貼る
    ".ssh/config".source = mkLink "${dotfilesDir}/ssh/config";

    # XDG Base Directory Specification に準拠する設定ファイルの配置
    ".config/starship.toml".source = mkLink "${dotfilesDir}/.config/starship.toml";
    ".config/git/config".source = mkLink "${dotfilesDir}/.config/git/config";
    ".config/mise/config.toml".source = mkLink "${dotfilesDir}/.config/mise/config.toml";
    ".config/act/actrc".source = mkLink "${dotfilesDir}/.config/act/actrc";

    # ホスト側のファイルとディレクトリにパスを貼る
    # ".ssh/wsl2-ssh-agent".source = mkLink "${wslHostDir}/.ssh/wsl2-ssh-agent";
    ".aws/credentials".source = mkLink "${wslHostDir}/.aws/credentials";
    ".kube/config".source = mkLink "${wslHostDir}/.kube/config";
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
