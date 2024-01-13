{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.home.local;

in

{
  options = {
    home.local = mkOption {
      type = with types; submodule {
        options = {
          domain = mkOption {
            description = "The domain of this user.";
            type = str;
          };

          name = mkOption {
            description = "The full name of the user.";
            type = str;
          };

          email = mkOption {
            description = "The email of the user.";
            type = str;
            default = "${config.home.username}@${config.home.local.domain}";
          };

          uid = mkOption {
            description = "The user ID.";
            type = numbers.between 1000 5000;
          };

          monospaceFont = mkOption {
            type = submodule {
              options = {
                name = mkOption {
                  description = "The font name.";
                  type = str;
                  default = "Iosevka Comfy";
                };

                defaultSize = mkOption {
                  description = "The default font size.";
                  type = int;
                  default = 10;
                };
              };
            };
          };

          browser = mkOption {
            description = "The command to start a browser";
            type = str;
            default = "firefox";
          };

          vpnScript = mkOption {
            description = "A package exposing a command to connect to a VPN.";
            type = nullOr package;
            default = null;
          };

          messengers = mkOption {
            type = listOf (submodule {
              options = {
                class = mkOption {
                  description = "The X11 windows class of the messenger window.";
                  type = str;
                };

                exe = mkOption {
                  description = "The command to start the messenger.";
                  type = str;
                };

                hotkey = mkOption {
                  description = "The Xmonad hotkey to use for this messenger.";
                  type = str;
                };
              };
            });
          };
        };
      };
    };
  };

  config = {
  };
}