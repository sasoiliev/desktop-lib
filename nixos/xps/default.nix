{ config, lib, pkgs, ... }:

{
  imports = [
    # The hardware configuration is meant to always be generated
    # by nixos-generate-config, so it isn't version controlled.
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users = lib.attrsets.mapAttrs (username: value:
    {
      inherit (value) uid;
      isNormalUser = true;
      extraGroups = [ "wheel" "video" "docker" "scanner" "lp" ];
    })
    (import ../../users);

  # disable docking station audio module
  boot.blacklistedKernelModules = [ "snd_usb_audio" ];
  boot.kernelParams = [
    "zfs.zfs_arc_max=2147483648"
    "hid_apple.swap_opt_cmd=1"
    "hid_apple.fnmode=2"
    "hid_apple.swap_fn_leftctrl=1"
    "mem_sleep_default=deep"
  ];
  boot.extraModprobeConfig = ''
    options dell-smm-hwmon ignore_dmi=1
  '';
  boot.kernelModules = [ "hid-apple" ];

  swapDevices = [ {
    device = "/dev/mapper/swap";
    encrypted = {
      enable = true;
      label = "swap";
      blkDev = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_1TB_S6Z1NJ0W507505N-part1";
      keyFile = "/mnt-root/var/lib/keys/swap.key";
    };
  } ];

  services.zfs.autoScrub = {
    enable = true;
    pools = [ "rpool" ];
  };

  services.udev.packages = [
    pkgs.android-udev-rules
  ];

  networking = {
    hostName = "xps";
    hostId = "f0c288d6";
    networkmanager = {
      enable = true;
      wifi.scanRandMacAddress = false;
    };
    wireless.enable = false;
    useDHCP = false;
  };

  # The i915 driver fails to load before display-manager.service
  # gets started. This bumps the delay between the restarts and
  # around the issue.
  systemd.services.display-manager.serviceConfig = {
    RestartSec = lib.mkOverride 0 "1s";
    StartLimitBurst = lib.mkOverride 0 10;
  };

  nixpkgs.config.permittedInsecurePackages = [
    "teams-1.5.00.23861"
  ];

  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
    experimental-features = nix-command flakes
  '';

  programs.light.enable = true;
  services.actkbd = {
    enable = true;
    bindings = [
      { keys = [ 224 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -U 10"; }
      { keys = [ 225 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -A 10"; }
    ];
  };

  system.stateVersion = "20.03";
}
