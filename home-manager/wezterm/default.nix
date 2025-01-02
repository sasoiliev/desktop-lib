{ monospaceFont }:

{ config, lib, pkgs, ... }:

{
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local wezterm = require 'wezterm'
      local config = {}

      config.font = wezterm.font('${monospaceFont.name}')

      config.color_scheme = 'Solarized Dark (Gogh)'
      -- TODO: Remove after https://github.com/wez/wezterm/issues/4257 is
      -- released.
      local scheme = wezterm.color.get_builtin_schemes()[config.color_scheme]
      scheme.cursor_fg = scheme.background
      config.color_schemes = {
        [config.color_scheme] = scheme
      }

      config.enable_scroll_bar = true
      config.enable_tab_bar = false
      config.hide_tab_bar_if_only_one_tab = true
      -- Fix for: https://github.com/wez/wezterm/issues/5990
      config.front_end = "WebGpu"

      config.keys =
        { { key = 'c'
          , mods = 'ALT'
          , action = wezterm.action.CopyTo 'Clipboard'
          }
        , { key = 'v'
          , mods = 'ALT'
          , action = wezterm.action.PasteFrom 'Clipboard'
          }
        , { key = 'UpArrow'
          , mods = 'SHIFT'
          , action = wezterm.action.ScrollByLine(-1)
          }
        , { key = 'DownArrow'
          , mods = 'SHIFT'
          , action = wezterm.action.ScrollByLine(1)
          }
        }

      return config
    '';
  };
}
