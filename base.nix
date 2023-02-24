{ pkgs, config, lib, ... }:
{
  boot = {
#    loader.generic-extlinux-compatible.enable = false;
#    loader.efi.canTouchEfiVariables = true;
#    loader.systemd-boot.enable = true;
    # Use mainline kernel, vendor kernel has some issues compiling due to
    # missing modules that shouldn't even be in the closure.
    # https://github.com/NixOS/nixpkgs/issues/111683
#    kernelPackages = pkgs.linuxPackages_latest;
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    # Disable ZFS by not including it in the list(s). Just adds a lot of
    # unnecessary compile time for this simple example project.
    kernelParams = [
       # "8250.nr_uarts=1"
       # "console=ttyAMA0,115200"
        "console=tty1"
        # A lot GUI programs need this, nearly all wayland applications
        "cma=128M"
#        "rootwait"
        "modules-load=dwc2,g_ether"
    ];
    loader.raspberryPi = {
#      enable = true;
#      version = 4;
      firmwareConfig = ''
        hdmi_group=2
        hdmi_mode=82
        gpu_mem=256
        dtparam=spi=on
        dtparam=sound=on
        dtparam=i2c_arm=on
        dtparam=i2s=on
        dtoverlay=spi-bcm2835
        dtoverlay=dwc2
        '';
    };
#    loader.grub.enable = false;
    tmpOnTmpfs = true;
    initrd.availableKernelModules = [ "usbhid" "usb_storage" "g_ether" ];
    kernelModules = lib.mkForce [ "bridge" "macvlan" "tap" "tun" "loop" "atkbd" "ctr" "libcomposite" ];
    supportedFilesystems = lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" "ext4" ];
  };
  # "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix" usually
  # contains this, it's the one thing from the installer image that we
  # actually need.
  fileSystems."/" =
    { device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
}
