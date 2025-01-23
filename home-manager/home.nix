{ config, lib, pkgs, pkgs-unstable, nurpkgs, self-pkgs, ... }:

let

  userRunDir = "/run/user/${toString config.home.local.uid}";
  xidlehookSocket = "${userRunDir}/xidlehook.sock";

  color = rec {
    rootBg = "#073642";
    bg = "#002b36";
    fg = "#657b83";
    neutral = fg;
    highlight = "#c0c0c0";
    urgent = "#ff69b4";
    border = "#2aa198";
  };

  monospaceFont = {
    name = "Iosevka Comfy";
    defaultSize = 10;
  };

  theme = {
    icons = {
      package = pkgs.arc-icon-theme;
      name = "Arc";
    };
    gui = {
      package = pkgs.solarc-gtk-theme;
      name = "SolArc-Dark";
    };
  };

  terminal = "wezterm";
  browser = "firefox";

in

{
  imports = [
    (import ./xmonad { inherit color terminal; font = monospaceFont; })
    ./vim
    ./git
    (import ./wezterm { inherit monospaceFont; })
  ];

  home.homeDirectory = "/home/${config.home.username}";
  home.stateVersion = "23.11";
  nixpkgs.config.allowUnfree = true;

  programs.home-manager.enable = true;

  programs.rofi = {
    enable = true;
    terminal = terminal;
  };

  # Disable manual generation (https://github.com/nix-community/home-manager/issues/254)
  manual.manpages.enable = false;

  home.packages = with pkgs; [
    gnupg
    keepassxc
    fontconfig
    htop
    thunderbird
    xmobar
    libreoffice
    bc
    i3lock xidlehook xss-lock xkb-switch
    zathura
    moka-icon-theme
    xorg.xev xorg.xwininfo
    flameshot
    pcmanfm
    gucharmap
    inkscape
    spotify
    jq
    qrencode
    feh
    jetbrains.idea-community
    audacious
    chromium
    remmina
    arandr
    yubikey-manager yubikey-manager-qt yubikey-personalization yubioath-flutter
    gimp imagemagick inkscape
    iosevka
    iosevka-comfy.comfy
    iosevka-comfy.comfy-duo
    iosevka-comfy.comfy-fixed
    wireshark termshark
    pinentry-gtk2
  ];

  # Disable home-manager keyboard management to reset of avoid Xkb options on
  # session switch.
  home.keyboard = null;

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      add_newline = false;
      git_status = {
        format = "([\\[$all_status$ahead_behind\\]]($style) )";
      };
      nix_shell = {
        impure_msg = "impure nix-shell";
        pure_msg = "pure nix-shell";
      };
    };
  };

  services.dunst = {
    enable = true;
    iconTheme = {
      package = pkgs.arc-icon-theme;
      name = "Arc";
    };
    settings = {
      global = {
        font = with monospaceFont; "${name} ${builtins.toString defaultSize}";
        follow = "keyboard";
        width = 450;
        height = 90;
        origin = "bottom-right";
        offset = "20x40";
        separator_height = 2;
        padding = 8;
        horizontal_padding = 8;
        frame_width = 2;
        frame_color = "${color.border}";
        separator_color = "frame";
        sort = "yes";
        format = "[%a] <b>%s</b>\\n%b";
        max_icon_size = 64;
      };
      urgency_normal = {
        background = "${color.bg}";
        foreground = "#d0d0d0";
      };
      urgency_low = {
        background = "${color.bg}";
        foreground = "#a0a0a0";
      };
      urgency_critical = {
        background = "${color.bg}";
        foreground = "${color.urgent}";
      };
    };
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      vi = "vim";
      watch = "watch "; # trailing space for alias support
      nssh = "ssh -o UserKnownHostsFile=/dev/null";
      nscp = "scp -o UserKnownHostsFile=/dev/null";
      ykrotate = "gpg-connect-agent \"scd serialno\" \"learn --force\" /bye";
    };
    sessionVariables = {
      EDITOR = "vim";
      HISTCONTROL = "ignorespace";
    };
    profileExtra = ''
      export PATH=$PATH:$HOME/.bin
      # Workaround for https://lists.gnu.org/archive/html/bug-coreutils/2019-05/msg00028.html
      eval "$(TERM=xterm-256color dircolors --sh)"
    '';
  };

  home.file.".config/nixpkgs/config.nix".text = ''
    { allowUnfree = true; }
  '';

  home.file.".icons".source = ./icons;

  home.file.".lock-screen" = with pkgs; {
    text = ''
      #!${bash}/bin/bash
      cur="$(${xkb-switch}/bin/xkb-switch)"
      ${xkb-switch}/bin/xkb-switch -s us
      ${i3lock}/bin/i3lock -n -i ~/.wallpaper.png -t
      ${xkb-switch}/bin/xkb-switch -s "$cur"
    '';
    executable = true;
  };

  home.file.".bin/rofi-autorandr" = with pkgs; {
    executable = true;
    text = ''
      #!${bash}/bin/bash
      set -euo pipefail
      function switch() { ${autorandr}/bin/autorandr --change; }
      function menu_switch() {
          local layouts layout matching
          layouts="$(${autorandr}/bin/autorandr)"
          layout=$( (echo "$layouts")  | ${rofi}/bin/rofi -dmenu -p "Layout")
          matching=$( (echo "$layouts") | ${gnugrep}/bin/grep "^$layout$")
          ${autorandr}/bin/autorandr --load $matching
      }
      function main() {
          if test "''${1:-}" = "--menu"; then
              menu_switch
          else
              switch
          fi
      }
      main $@
    '';
  };

  home.file.".psqlrc".text = ''
    \pset pager off
    \set G '\\set QUIET 1\\x\\g\\x\\set QUIET 0'
  '';

  home.file.".bin/dock-undock.sh" = with pkgs; {
    executable = true;
    text = ''
      #!${bash}/bin/bash
      function notify {
        ${dunst}/bin/dunstify -h string:x-dunst-stack-tag:autorandr \
          --appname=Desktop "$@"
      }
      case "$1" in
        dock)
          action=dock
          profile=docked
          msg_pre="Docking..."
          msg_ok="Docked."
          ;;
        undock)
          action=undock
          profile=undocked
          msg_pre="Undocking..."
          msg_ok="Undocked."
          ;;
        load-profile)
          profile=$2
          action="load dock profile $profile"
          msg_pre="Loading dock profile $profile..."
          msg_ok="Dock profile $profile loaded."
          ;;
        *)
          notify "Invalid action: $1"
          exit 1
          ;;
      esac
      notify "$msg_pre"
      out="$(${autorandr}/bin/autorandr -l "$profile" 2>&1)"
      if test $? -ne 0; then
        notify "Failed to $action" "$out"
      else
        notify "$msg_ok"
      fi
    '';
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    extraConfig = ''
      # Fix for https://dev.gnupg.org/T4255 - when multiple requests
      # are done in parallel without this option some requests fail to
      # allocate memory.
      auto-expand-secmem
      pinentry-program ${pkgs.pinentry-gtk2}/bin/pinentry-gtk-2
    '';
  };

  gtk = {
    enable = true;
    iconTheme = theme.icons;
    theme = theme.gui;
  };

  xsession.enable = true;
  xsession.initExtra = with pkgs; ''
    # Workaround for https://github.com/NixOS/nixpkgs/issues/18173
    # TODO: remove when fixed
    ${xorg.setxkbmap}/bin/setxkbmap -layout us,bg -variant ,phonetic \
      -option grp:alt_shift_toggle,caps:swapescape
    ${xorg.xsetroot}/bin/xsetroot -solid "${color.rootBg}"
    export PRIMARY_DISPLAY="$(xrandr | awk '/ primary/{print $1}')"
    rm ${xidlehookSocket}
    (umask 0077 && mkdir ${userRunDir})
    ${xidlehook}/bin/xidlehook \
      --socket ${xidlehookSocket} \
      --not-when-fullscreen \
      --timer 30 \
        '${self-pkgs.if-at-edge}/bin/if-at-edge -d -t 5 S -- ${xidlehook}/bin/xidlehook-client --socket ${xidlehookSocket} reset-idle' \
        ''' \
      --timer 600 \
        'xrandr --output "$PRIMARY_DISPLAY" --brightness .3' \
        'xrandr --output "$PRIMARY_DISPLAY" --brightness 1' \
      --timer 5 \
        'xrandr --output "$PRIMARY_DISPLAY" --brightness 1; loginctl lock-session $XDG_SESSION_ID' \
        ''' \
      --timer 3600 'systemctl suspend' ''' &
    # Disable X11 screensaver setting.
    xset s off
    ${xss-lock}/bin/xss-lock -- $HOME/.lock-screen &
    ${xdotool}/bin/xdotool behave_screen_edge --delay 3 bottom-left \
      exec ${xidlehook}/bin/xidlehook-client --socket /run/user/$UID/xidlehook.sock reset-idle &
  '';

#  xresources.extraConfig = builtins.readFile (
#    pkgs.fetchFromGitHub {
#      owner = "solarized";
#      repo = "xresources";
#      rev = "025ceddbddf55f2eb4ab40b05889148aab9699fc";
#      sha256 = "0lxv37gmh38y9d3l8nbnsm1mskcv10g3i83j0kac0a2qmypv1k9f";
#    } + "/Xresources.dark"
#  );
#
  services.redshift.enable = true;
  services.redshift.latitude = "52.0";
  services.redshift.longitude = "13.0";

  services.stalonetray = {
    enable = true;
    config = rec {
      icon_size = 16;
      icon_gravity = "E";
      geometry = "9x1-0-0";
      background = color.bg;
    };
  };

  services.network-manager-applet.enable = true;

  home.file.".bin/show-qr" = {
    executable = true;
    text = with pkgs; ''
      #!${bash}/bin/bash
      ${xclip}/bin/xclip -out -selection clipboard | \
        ${qrencode}/bin/qrencode -s 10 -o - | \
        ${feh}/bin/feh -
    '';
  };

  services.sxhkd = {
    enable = true;
    keybindings = {
      "super + {r}" = "rofi -show run";
      "super + {w}" = browser;
      "super + shift + {w}" = "${browser} --private-window";
      "ctrl + alt + {l}" = "xidlehook-client --socket ${xidlehookSocket} control --action trigger --timer 2";
      "Print" = "flameshot gui";
      "super + shift + {p}" = "flameshot gui";
      "ctrl + shift + Escape" = "${terminal} -e top";
      "super + F12" = "$HOME/.bin/dock-undock.sh dock";
      "super + F11" = "$HOME/.bin/dock-undock.sh undock";
      "super + F10" = "$HOME/.bin/dock-undock.sh load-profile docked-1display";
      "super + F8" = "$HOME/.bin/show-qr";
      "XF86Eject" = "rofi -show window";
      "super + XF86Eject" = "systemctl suspend -i";
      "super + e" = "${pkgs.nautilus}/bin/nautilus";
      "ctrl + grave" = "${pkgs.dunst}/bin/dunstctl close";
      "ctrl + alt + grave" = "${pkgs.dunst}/bin/dunstctl history-pop";
      "{XF86AudioMute,XF86AudioLowerVolume,XF86AudioRaiseVolume}" =
        "${pkgs.alsa-utils}/bin/amixer {set Master toggle,sset Master 7%-,sset Master 7%+}";
      # source: https://fabianlee.org/2016/05/25/ubuntu-enabling-media-keys-for-spotify/
      "{XF86AudioPlay,XF86AudioNext,XF86AudioPrev}" =
        "${pkgs.playerctl}/bin/playerctl {play-pause,next,previous}";
    };
  };

  programs.ssh = {
    enable = true;
  };

  programs.firefox = let
    extensions = with nurpkgs.repos.rycee.firefox-addons; [
      privacy-badger
      ublock-origin
      vimium
      auto-tab-discard
      clearurls
      reddit-enhancement-suite
      multi-account-containers
      darkreader
    ];
  in {
    enable = true;

    profiles = {
      default  = { name = "default"; id = 0; inherit extensions; };
      netflix  = { name = "netflix"; id = 1; inherit extensions; };
      ipquants = { name = "ipquants"; id = 2; inherit extensions; };
      amazon   = { name = "amazon"; id = 3; inherit extensions; };
      google   = { name = "google"; id = 4; inherit extensions; };
      spotify  = { name = "spotify"; id = 5; inherit extensions; };
    };
  };

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
}
