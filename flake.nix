{
  description = "Home-manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs";
    nixpkgs-23_11.url = "github:nixos/nixpkgs/nixos-23.11";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nur.url = "github:nix-community/NUR";
  };

  outputs = { nixpkgs, nixpkgs-23_11, ... }:
    let
      pkgs-23_11 = system: import nixpkgs-23_11 { inherit system; };
    in
    {
      users = import ./users;
      homeManagerModules = [
        (import ./home-manager/home.nix)
        (import ./home-manager/local.nix)
      ];
      nixosConfigurations.xps = system: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { pkgs-23_11 = pkgs-23_11 system; };
        modules = [ ./nixos/all.nix ./nixos/graphical.nix ./nixos/xps ];
      };
      packages = let
        system = "x86_64-linux";
      in {
        ${system}."if-at-edge" = (import nixpkgs { inherit system; }).callPackage (import ./pkgs/if-at-edge) {};
      };
    };
}
