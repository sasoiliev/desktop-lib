{ config, lib, pkgs, pkgs-23_11, ... }:

{
  nixpkgs.config.allowUnfree = true;

  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    cryptsetup
    vim
    openssh
    openssl
    gitFull
    file lsof pstree psmisc
    dnsutils tcpdump inetutils curl
    unzip

    lynx
    xterm
    dmenu
    rxvt-unicode-unwrapped # needed for root TERM compatibility
    networkmanagerapplet
    pavucontrol
    system-config-printer
  ];

  programs.adb.enable = true;

  boot.zfs.requestEncryptionCredentials = true;
  boot.supportedFilesystems = [ "zfs" ];

  services.fwupd.enable = true;

  services.automatic-timezoned.enable = true;

  hardware.sane.enable = true;

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    storageDriver = "zfs";
  };

  console.useXkbConfig = true;
  services.dbus.packages = [ pkgs.dconf ];
  programs.dconf.enable = true;
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.samsung-unified-linux-driver ];

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.pulse.enable = true;
  services.pipewire.wireplumber.enable = true;

  services.autorandr.enable = true;
  services.libinput = {
    enable = true;
    touchpad.naturalScrolling = true;
    touchpad.disableWhileTyping = true;
    mouse.naturalScrolling = false;
    mouse.accelSpeed = "1.0";
  };
  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    displayManager.lightdm.greeters.gtk.enable = true;
    windowManager.xmonad.enable = true;
    xkb.layout = "us,bg";
    xkb.variant = ",phonetic";
    xkb.options = "grp:alt_shift_toggle,caps:swapescape";
  };

  services.udev.packages = [ pkgs.yubikey-personalization ];
  services.pcscd.enable = true;

  services.ofono.enable = true;
  services.blueman.enable = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings.General.Enable = "Source,Sink,Media,Socket";
  hardware.bluetooth.package = pkgs-23_11.bluez;

  # Workaround for binaries downloaded from the Internet such as
  # the protoc compiler.
  # Source: https://discourse.nixos.org/t/runtime-alternative-to-patchelf-set-interpreter/3539/4
  system.activationScripts.ldso = pkgs.lib.stringAfter [ "usrbinenv" ] ''
     mkdir -m 0755 -p /lib64
     ln -sfn ${pkgs.glibc.out}/lib64/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2.tmp
     mv -f /lib64/ld-linux-x86-64.so.2.tmp /lib64/ld-linux-x86-64.so.2 # atomically replace
  '';
}
