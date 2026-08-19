{
  description = "Nix configuration of tetsuzin (linux / wsl / mac)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
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
      nix-darwin,
      nix-homebrew,
      ezaThemes,
      lazyvimStarter,
      ...
    }:
    let
      user = "tetsuzin";
      mkHome =
        isWsl:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [ ./home-manager/linux.nix ];
          extraSpecialArgs = {
            inherit user ezaThemes lazyvimStarter isWsl;
          };
        };
    in
    {
      homeConfigurations.${user} = mkHome false;
      homeConfigurations."${user}-wsl" = mkHome true;

      darwinConfigurations."shion" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./nix-darwin/_main.nix
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
        ];
        specialArgs = { inherit user ezaThemes; };
      };
    };
}
