{
  inputs = {
    nixpkgs.url = "github:takov751/nixpkgs/release-22.11";
    nixos-hardware.url = "github:nixos/nixos-hardware";
  };
  outputs = { self, nixpkgs, nixos-hardware }: {
    images = {
      pi = (self.nixosConfigurations.pi.extendModules {
        modules = [ "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
## Defining sdImage parameters for builder
          ( { config, lib, pkgs, resources, ... }: {
              sdImage = {
                compressImage = false;
# /boot vfat partition by default 30M which is a bit small for live updating.
                firmwareSize = 512;
              };
         })
         ];
      }).config.system.build.sdImage;
    };
    nixosConfigurations = {
      pi = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          nixos-hardware.nixosModules.raspberry-pi-4
          ./configuration.nix
          ./base.nix
        ];
      };
    };
  };
}
