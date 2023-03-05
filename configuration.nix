{ pkgs, config, lib, ... }:
{
  system.stateVersion = "unstable";
#optimize nix store size on device
  nix = {
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    # Free up to 1GiB whenever there is less than 100MiB left.
    extraOptions = ''
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (1024 * 1024 * 1024)}
      experimental-features = nix-command flakes
    '';
  };
#https://github.com/NixOS/nixpkgs/issues/126755 workaround missing kernel module
#We will allow it
  nixpkgs.overlays = [
  (final: super: {
    makeModulesClosure = x:
      super.makeModulesClosure (x // { allowMissing = true; });
  })
  (final: super: {
      ubootRaspberryPi4_64bit = super.ubootRaspberryPi4_64bit.override rec {
        version = "2023.01";
        src = super.fetchurl {
          url = "ftp://ftp.denx.de/pub/u-boot/u-boot-${version}.tar.bz2"; 
          hash = "sha256-aUI7rTgPiaCRZjbonm3L0uRRLVhDCNki0QOdHkMxlQ8=";
        };
      };
   })
];
# Allow nonfree packages
  nixpkgs.config = {
  allowUnfree = true;
};
  environment.systemPackages = with pkgs; [ 
    vim
    git
    pulseaudio
    wget
    curl
    jq
    dtc
    screen
    libraspberrypi
    bind
#python3
    (python310.withPackages (p: with p; [
    regex
    pip
    spidev
    requests
    ])) 
  ];
  services.openssh.enable = true;
  networking.hostName = "nixy";
  # Enable hardware features
  sound.enable = true;
 # hardware.pulseaudio.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };
  hardware.raspberry-pi."4" = {
    apply-overlays-dtmerge.enable = true;
    i2c1.enable = true;
    dwc2.enable = true;
    audio.enable = true;
    fkms-3d.enable = true;
  };
  hardware.deviceTree = {
    enable = true;
# Filter for specific hardware device tree
    filter = lib.mkForce "bcm2711-rpi-*.dtb";
# add overlay where dtsText had to be defined to workaround compatiblity issue as originally 'bcm2711' was 'bcm2833'
# dtbo file not needed to be defined here as kernel package has the overlay directory where all the official dtbo placed
# left the commented lines as a possible way to add dtbo file, but needs more testing 
    overlays = [
      {
        name = "spi0-0cs-overlay";
#        dtsFile = ./spi0-0cs-overlay.dts;
#         dtboFile = ./spi0-0cs.dtbo;
#         dtboFile = builtins.fetchurl {
#         name = "spi0-0cs.dtbo";
#         url = "https://github.com/raspberrypi/firmware/raw/stable/boot/overlays/spi0-0cs.dtbo";
#         sha256 = "01340ab9d04daa52c867964f50aa0632991023f40fc581ff6452764857010619";
#         };
        dtsText = ''
        /dts-v1/;
        /plugin/;

        / {
	compatible = "brcm,bcm2711";

	fragment@0 {
		target = <&spi0_cs_pins>;
		frag0: __overlay__ {
			brcm,pins;
		};
	};

	fragment@1 {
		target = <&spi0>;
		__overlay__ {
			cs-gpios;
			status = "okay";
		};
	};

	fragment@2 {
		target = <&spidev1>;
		__overlay__ {
			status = "disabled";
		};
	};

	fragment@3 {
		target = <&spi0_pins>;
		__dormant__ {
			brcm,pins = <10 11>;
		};
	};

	__overrides__ {
		no_miso = <0>,"=3";
	};
};

        '';
      }
    ];
  };
  # Create gpio and spi group to allow user to interact with those
  users.groups.gpio = {};
  users.groups.spi = {};
  users.groups.i2c = {};
  # Change permissions gpio,spi devices
  services.udev.extraRules = ''
    SUBSYSTEM=="bcm2711-gpiomem", KERNEL=="gpiomem", GROUP="gpio",MODE="0660"
    SUBSYSTEM=="gpio", KERNEL=="gpiochip*", ACTION=="add", RUN+="${pkgs.bash}/bin/bash -c 'chown root:gpio  /sys/class/gpio/export /sys/class/gpio/unexport ; chmod 220 /sys/class/gpio/export /sys/class/gpio/unexport'"
    SUBSYSTEM=="gpio", KERNEL=="gpio*", ACTION=="add",RUN+="${pkgs.bash}/bin/bash -c 'chown root:gpio /sys%p/active_low /sys%p/direction /sys%p/edge /sys%p/value ; chmod 660 /sys%p/active_low /sys%p/direction /sys%p/edge /sys%p/value'"
    SUBSYSTEM=="spidev", KERNEL=="spidev0.0", GROUP="spi", MODE="0660"
    SUBSYSTEM=="i2c-dev", GROUP="i2c",  MODE="0666"
  '';

  users = {
    users.test = {
      password = "test";
      isNormalUser = true;
      extraGroups = [ "audio" "wheel" "gpio" "i2c" "video" "spi" "networkmanager" ];
    };
  };
  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    desktopManager.xfce.enable = true;
  };
  networking = {
#    interfaces."usb0".ipv4 = {
#        addresses = [
#      {
#      address = "10.42.0.2";
#      prefixLength = 24;
#      }
#      ];
#      routes = [  {
#    options.scope = "global";
#    options.metric = "1002";
#    address = "10.42.0.0";
#    prefixLength = 24;
#    via = "10.42.0.1";
#  }];
#     };
#    interfaces."wlan0".useDHCP = true;
    interfaces."eth0".useDHCP = true;
    networkmanager.enable = true;
  };
}
