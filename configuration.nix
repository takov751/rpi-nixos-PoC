{ pkgs, config, lib, ... }:
{
  system.stateVersion = "22.11";
#https://github.com/NixOS/nixpkgs/issues/126755 workaround missing kernel module
#We will allow it
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
  nixpkgs.overlays = [
  (final: super: {
    makeModulesClosure = x:
      super.makeModulesClosure (x // { allowMissing = true; });
  })
];
  nixpkgs.config = {
  allowUnfree = true;
};
  environment.systemPackages = with pkgs; [ 
    raspberrypi-eeprom
    vim
    device-tree_rpi
    libgpiod
    libraspberrypi
    git
    wget
    curl
    jq
    dtc
    screen
    bind
    (python39.withPackages (p: with p; [
    regex
    pip
    spidev
    gpiozero
    requests
    ])) 
  ];
  services.openssh.enable = true;
  networking.hostName = "nixy";
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.raspberry-pi."4" = {
    apply-overlays-dtmerge.enable = true;
    i2c0.enable = true;
  };
  hardware.deviceTree = {
    enable = true;
    filter = lib.mkForce "bcm2838-rpi-*.dtb";
    overlays = [
      {
        name = "spi";
#        dtsFile = ./spi0-0cs-overlay.dts;
#         dtboFile = ./spi0-0cs.dtbo;
         dtboFile = builtins.fetchurl {
         name = "spi0-0cs.dtbo";
         url = "https://github.com/raspberrypi/firmware/raw/stable/boot/overlays/spi0-0cs.dtbo";
         sha256 = "01340ab9d04daa52c867964f50aa0632991023f40fc581ff6452764857010619";
         };
        dtsText = ''
        /dts-v1/;
/plugin/;

/ {
	compatible = "brcm,bcm2838";

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
  # Create gpio group
  users.groups.gpio = {};
  users.groups.spi = {};
  # Change permissions gpio devices
  services.udev.extraRules = ''
    SUBSYSTEM=="bcm2711-gpiomem", KERNEL=="gpiomem", GROUP="gpio",MODE="0660"
    SUBSYSTEM=="gpio", KERNEL=="gpiochip*", ACTION=="add", RUN+="${pkgs.bash}/bin/bash -c 'chown root:gpio  /sys/class/gpio/export /sys/class/gpio/unexport ; chmod 220 /sys/class/gpio/export /sys/class/gpio/unexport'"
    SUBSYSTEM=="gpio", KERNEL=="gpio*", ACTION=="add",RUN+="${pkgs.bash}/bin/bash -c 'chown root:gpio /sys%p/active_low /sys%p/direction /sys%p/edge /sys%p/value ; chmod 660 /sys%p/active_low /sys%p/direction /sys%p/edge /sys%p/value'"
    SUBSYSTEM=="spidev", KERNEL=="spidev0.0", GROUP="spi", MODE="0660"
  '';

  users = {
    users.test = {
      password = "test";
      isNormalUser = true;
      extraGroups = [ "wheel" "gpio" "video" "spi" ];
    };
  };
  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    desktopManager.xfce.enable = true;
  };
#  security.rtkit.enable = true;
#  services.pipewire = {
#  enable = true;
#  alsa.enable = true;
#  alsa.support32Bit = true;
#  pulse.enable = true;
  # If you want to use JACK applications, uncomment this
#  jack.enable = true;
#  };
#  systemd.network.networks.usb0.matchConfig.Name = "usb0";
#  systemd.network.networks.usb0.networkConfig = {
#    Address = "10.42.0.2/24";
#    DHCPServer = "no";
#    Gateway = "10.42.0.1";
#    DNS = "10.42.0.1";
#  };
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
    interfaces."wlan0".useDHCP = true;
    interfaces."eth0".useDHCP = true;
    wireless = {
      interfaces = [ "wlan0" ];
      enable = true;
      networks = {
        "network-ssid".psk = "password";
      };
    };
  };
}