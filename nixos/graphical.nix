{ config, lib, pkgs, ... }:

{
  fonts.packages = with pkgs; [
    iosevka
    iosevka-comfy.comfy
    iosevka-comfy.comfy-duo
    iosevka-comfy.comfy-fixed
  ];

  environment.systemPackages = with pkgs; [
    firefox
  ];
}