{ config, lib, pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName = config.home.local.name;
    userEmail = config.home.local.email;
    aliases = {
      co = "checkout";
      st = "status";
    };
    extraConfig = {
      push.default = "simple";
    };
    ignores = [ "*.swp" ".envrc" "shell.nix" ];
  };
}