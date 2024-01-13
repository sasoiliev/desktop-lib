{
  description = "Home-manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nur.url = "github:nix-community/NUR";
  };

  outputs = { nixpkgs, ... }:
    {
      users = import ./users;
      homeManagerModules = [ (import ./home-manager/home.nix) (import ./home-manager/local.nix) ];
      nixosConfigurations.xps = system: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ./nixos/all.nix ./nixos/graphical.nix ./nixos/xps ];
      };
    };
}
