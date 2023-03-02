
{ pkgs, config, lib, ... }:
{
#  sdImage = {
#    compressImage = false;
#    firmwareSize = 512;
#  };
  boot = {
    # Use mainline kernel, vendor kernel has some issues compiling due to
    # missing modules that shouldn't even be in the closure.
    # https://github.com/NixOS/nixpkgs/issues/111683
#    kernelPackages = pkgs.linuxPackages_latest;
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    # Disable ZFS by not including it in the list(s). Just adds a lot of
    # unnecessary compile time for this simple example project.
    kernelModules = lib.mkForce [ "bridge" "macvlan" "tap" "tun" "loop" "atkbd" "ctr" "libcomposite" "i2c-dev" ];
    supportedFilesystems = lib.mkForce [ "btrfs" "cifs" "ext4" "vfat" ];
  };
  # "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix" usually
  # contains this, it's the one thing from the installer image that we
  # actually need.
  fileSystems."/" =
    { device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  fileSystems."/boot" =
    { device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
    };
}
