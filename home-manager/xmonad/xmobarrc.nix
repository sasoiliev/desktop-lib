{ font, color }:

{ config, lib, pkgs, ... }:

with {
  inherit (builtins) attrNames filter concatStringsSep toString;
};

let
  checkRepoStatus = pkgs.writeScript "check-repo-status" (with pkgs; ''
    #!/usr/bin/env bash

    set -euo pipefail

    cd "$(${coreutils}/bin/dirname "$(${coreutils}/bin/readlink -f /etc/nixos/configuration.nix)")"

    if ${coreutils}/bin/test ! -z "$(${git}/bin/git status --porcelain=v2 --branch | ${gawk}/bin/gawk '
      BEGIN {
        dirty = 0;
      }

      match($0, /^# branch\.ab \+([0-9]+) -([0-9]+)/, a) {
        if (a[1] != "0" || a[2] != "0") {
          dirty = 1;
          exit;
        }
      }

      /^[12?]/ {
        dirty = 1;
        exit;
      }

      END {
        if (dirty == 1)
          print("dirty")
      }')" -o "$(git rev-parse --abbrev-ref HEAD)" != "master"; then
      echo '<fc=${color.urgent}></fc>'
    else
      echo 
    fi
  '');

  vpnScript = config.home.local.vpnScript;

  mamulVPNStat = pkgs.writeShellApplication {
    name = "mamul-vpn-stat";
    text = lib.optionalString (vpnScript != null) ''
      if ${vpnScript}/bin/mamul-vpn status; then
        echo up
      else
        echo down
      fi
    '';
  };
in
{
  home.file.".xmobarrc".text = ''
    Config { font = "${font.name} Bold ${toString font.defaultSize}"
       , bgColor = "${color.bg}"
       , fgColor = "${color.fg}"
       , position = Bottom
       , lowerOnStart = True
       , hideOnStart = False
       , persistent = False
       , border = NoBorder
       , allDesktops = True
       , overrideRedirect = False
       , commands = [
            Run Cpu ["-L", "3", "-H", "80"
                    , "--normal", "${color.neutral}"
                    , "--high","${color.highlight}"
                    , "-t", "<icon=.icons/cpu.xbm/> <vbar>"
                    , "-p", "2"] 10
          , Run Memory ["-H", "90", "-h", "${color.highlight}"
                       , "-t", "<icon=.icons/memory.xbm/> <usedvbar>", "-p", "2"] 10
          , Run Swap ["-H", "90", "-h", "${color.highlight}"
                     , "-t", "<usedratio>%"] 10
          --, Run DiskU [("/", "<free>"), ("/home", "<free>")] [] 20
          , Run Com "zfs" ["list", "-Ho", "available", "rpool"] "disku" 300
          , Run Com "${checkRepoStatus}" [] "repostatus" 10
          , Run Com "${mamulVPNStat}/bin/mamul-vpn-stat" ["status"] "vpnstatus" 10
          , Run Alsa "default" "Master" [ "-t", "<status><volumevbar>"
                                        , "--", "--on", "Vol "
                                        , "--off", "Mute "
                                        , "--onc", "${color.neutral}"
                                        , "--offc", "${color.neutral}"
                                        , "--alsactl", "${pkgs.alsa-utils}/bin/alsactl"
                                        ]
          , Run Kbd [("us", "<fc=${color.highlight}>US</fc>")
                    , ("bg(phonetic)", "<fc=${color.urgent}>BG</fc>")]
          , Run Com "whoami" [] "whoami" 100
          , Run Date "<fc=#1AAEDB>%H:%M</fc> %a %b %d" "localTime" 10
          , Run StdinReader
          , Run Battery ["-t", "<acstatus> <watts>W <left>%/<timeleft>"
                        , "-L", "20", "-H", "40"
                        , "-l", "${color.urgent}", "-n", "${color.highlight}"
                        , "--"
                        , "-O", ""
                        , "-o", "Bat"] 50
          --, Run Brightness ["-t", "BRI <vbar>", "--", "-D", "intel_backlight"] 10
       ]
       , sepChar = "%"
       , alignSep = "}{"
       -- a really dumb workaround for preventing xmobar text from overlapping with the system tray
       , template = "%localTime%  %kbd%  %battery%  %alsa:default:Master% } %whoami% | %StdinReader% {  %repostatus%  /:%disku%  %cpu%  %memory% %swap%                      "
       }
  '';
}
