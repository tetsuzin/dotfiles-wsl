{
  description = "Home Manager configuration of tetsuzin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ezaThemes = {
      url = "github:eza-community/eza-themes";
      flake = false;
    };
    lazyvimStarter = {
      url = "github:LazyVim/starter";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      ezaThemes,
      lazyvimStarter,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      user = "tetsuzin";
    in
    {
      homeConfigurations.${user} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home-manager/_main.nix ];
        extraSpecialArgs = {
          inherit user ezaThemes lazyvimStarter;
        };
      };
    };
}
