{
  lib,
  pkgs,
  config,
  ...
}: let
  username = "nixos";
  # To generate a hashed password run `mkpasswd -m scrypt`.
  # this is the hash of the password "nixos"
  hashedPassword = "$7$CU..../....WCqr/uo1KkH2ebQWDdy0O/$sKYbnmHtFscTZjDNb7Pi8YsQRRDeioWnEHLe7JIi/m5";
in {
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
  };

  environment.systemPackages = with pkgs; [
    git
    curl

    neofetch
    lm_sensors
    btop

    mtdutils
    i2c-tools
    minicom

    # Dev tools
    neovim
    uv
    python3
    go
    llvm
    clang
    gcc
  ];

  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      X11Forwarding = lib.mkDefault true;
      PasswordAuthentication = lib.mkDefault true;
    };
    openFirewall = lib.mkDefault true;
  };

  networking.networkmanager.enable = lib.mkDefault true;

  # WiFi connection - password managed via sops-nix
  networking.networkmanager.ensureProfiles.profiles = {
    "AS_Computer_Science" = {
      connection = {
        id = "AS_Computer_Science";
        type = "wifi";
        autoconnect = true;
      };
      wifi = {
        mode = "infrastructure";
        ssid = "AS_Computer_Science";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        # psk set via sops activation script at /run/secrets/wifi_psk
      };
      ipv4.method = "auto";
      ipv6.method = "auto";
    };
  };

  # ---------------------------------------------------------------
  # sops-nix: encrypted secrets
  # ---------------------------------------------------------------
  sops = {
    age.keyFile = "/var/lib/sops-nix/keys.txt";

    secrets = {
      wifi_psk = {
        sopsFile = ../secrets.yaml;
        neededForUsers = true;
      };
    };
  };

  system.activationScripts.wifi-psk = {
    deps = [ "sops" ];
    text = ''
      PASSWORD=$(cat /run/secrets/wifi_psk)
      mkdir -p /etc/NetworkManager/system-connections
      cat > /etc/NetworkManager/system-connections/AS_Computer_Science.nmconnection << 'PROFEOF'
      [connection]
      id=AS_Computer_Science
      type=wifi
      autoconnect=true
      permissions=

      [wifi]
      mode=infrastructure
      ssid=AS_Computer_Science

      [wifi-security]
      key-mgmt=wpa-psk
      PROFEOF
      echo "psk=$PASSWORD" >> /etc/NetworkManager/system-connections/AS_Computer_Science.nmconnection
      cat >> /etc/NetworkManager/system-connections/AS_Computer_Science.nmconnection << 'PROFEOF'

      [ipv4]
      method=auto

      [ipv6]
      method=auto
      PROFEOF
      chmod 600 /etc/NetworkManager/system-connections/AS_Computer_Science.nmconnection
    '';
  };

  # ---------------------------------------------------------------
  # Hailo-8 PCIe accelerator driver
  # ---------------------------------------------------------------
  boot.extraModulePackages = [
    (config.boot.kernelPackages.callPackage ../pkgs/hailo-pci {})
  ];
  boot.kernelModules = [ "hailo_pci" ];

  # =========================================================================
  #      Users & Groups NixOS Configuration
  # =========================================================================

  users.users."${username}" = {
    inherit hashedPassword;
    isNormalUser = true;
    home = "/home/${username}";
    extraGroups = ["users" "wheel"];
  };

  system.stateVersion = "23.11";
}
