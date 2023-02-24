# rpi-nixos-PoC
PoC nixos image builder for rpi4

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
