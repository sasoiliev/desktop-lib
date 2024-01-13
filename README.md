Home Manager Configuration
==========================

This repository contains my [NixOS][1] desktop configuration.

The `nixos/` directory contains a NixOS configuration, while the
`home-manager/` directory contains a [Home Manager][2] configuration.

The code in this project is heavily based on the `mamul.org:mamul.org.git`
Git repository, specifically the `machines/xps-7390` and `profiles`
directories. Refer to this project's history for context how the code
had developed historically.

Requirements
------------

To use it you need a [Nix][3] installation with [flakes][4] enabled.

Usage
-----

Create a flake that uses the flake in this repository as an input:

```nix
{
  inputs = {
    desktop-lib = "git+ssh://mamul.org/var/lib/state/git/desktop-lib.git";
  };
}
```

It is recommended to override this repository's inputs so that the inputs'
version are controlled from the point of usage:

```nix
{
  inputs = {
    desktop-lib.url = "git+ssh://mamul.org/var/lib/state/git/desktop-lib.git";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    nur.url = "github:nix-community/NUR";

    desktop-lib.inputs.nixpkgs.follows = "nixpkgs";
    desktop-lib.inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
    desktop-lib.inputs.home-manager.follows = "home-manager";
    desktop-lib.inputs.nur.follows = "nur";
  };
}
```

### Managing NixOS Configuration

Re-export any NixOS configuration that you want to manage from your flake:

```nix
{
  inputs = {
    # ...
  };
  
  outputs = { self, desktop-lib, ... }:
    let
      system = "x86_64-linux";
    in
    {
      # ...
      nixosConfiguration.xps = desktop-lib.nixosConfigurations.xps system;
    }; 
}
```

Build the configuration:

        nixos-rebuild build --flake .#xps

Switch to the new configuration:

        nixos-rebuild switch --flake .#xps

### Managing Home Manager Configuration

Add a Home Manager configuration output to the flake:

```nix
{
  inputs = {
    # ...
  };
  
  outputs = { self, desktop-lib, nixpkgs, nixpkgs-unstable, home-manager, nur, ... }:
    let
      system = "x86_64-linux";
      username = "ailiev";

      # Source: https://github.com/jonringer/nixpkgs-config/blob/master/flake.nix
      pkgsForSystem = system: _nixpkgs: import _nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      pkgs = pkgsForSystem system nixpkgs;
      nurpkgs = import nur { nurpkgs = pkgs; inherit pkgs; };
      pkgs-unstable = pkgsForSystem system nixpkgs-unstable;
    in
    {
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ (
          { config, lib, pkgs, pkgs-unstable, nur, ... }:
          {
            # <-- Any specific configurations that you need would go here.
          }
        ) ] ++ desktop-lib.homeManagerModules;
        extraSpecialArgs = { inherit pkgs-unstable nurpkgs username; };
      };
    }; 
}
```

Make sure to set the `system` and `username` variables.

Build the Home Manager configuration:

        nix run home-manager/release-23.11 -- build --flake .

and switch to the new Home Manager generation:

        nix run home-manager/release-23.11 -- switch --flake .

After you have activated the Home Manager generation for the first time
you can invoke it through its command, i.e.:

        home-manager switch --flake .

For more details you can refer to the Home Manager [standalone flake
installation documentation][5].

Customization
-------------

You can edit the various fields passed to Home Manager through the
`extraSpecialArgs` record. For instance, you can add packages by
listing them in the result of the `extraPackages` function.

[1]: https://nixos.org
[2]: https://nix-community.github.io/home-manager
[3]: https://nixos.org/manual/nix/stable
[4]: https://nixos.wiki/wiki/Flakes
[5]: https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-standalone
