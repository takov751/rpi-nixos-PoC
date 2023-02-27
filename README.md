# rpi-nixos-PoC
PoC nixos image builder for rpi4
### On NixOS
If you're running NixOS and want to use this template to build the Raspberry Pi
4 Image, you'll need to emulate an arm64 machine by adding the following to your
NixOS configuration.

```
{
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
```

###to build image on nixos run in the directory:
```
nix build .#images.pi
```
Which produces a zstd image in result/sd-image and then extracting into img. Write it to sdcard 
###example:
```
unzstd -d result/sd-image/nixos-sd-image-23.05.20230222.988cc95-aarch64-linux.img.zst -o rpi4.img
dd if=rpi4.img of=/dev/mmcblk0 bs=4096 conv=fsync status=progress

```
After you've booted, you will be able to rebuild the nixosConfiguration on the
Pi. For example, by running `nixos-rebuild --flake
github:takov751/rpi-nixos-PoC`
