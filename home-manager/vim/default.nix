{ config, lib, pkgs, ... }:

{
  programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      sensible
      nerdtree
      vim-airline
      vim-airline-themes
      vim-colors-solarized
    ];
    extraConfig = import ./vimrc.nix;
  };
}
