{
  description = "NixOS configuration for Orange Pi 5 Plus (SR2027)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , sops-nix
    , ...
    }:
    let
      localSystem = "x86_64-linux";
      aarch64System = "aarch64-linux";

      pkgsCross = import nixpkgs {
        inherit localSystem;
        crossSystem = aarch64System;
      };
    in
    {
      nixosModules = {
        boards.orangepi5plus = {
          core = import ./modules/boards/orangepi5plus.nix;
          sd-image = ./modules/sd-image/orangepi5plus.nix;
        };
      };

      nixosConfigurations.orangepi5plus-cross = nixpkgs.lib.nixosSystem {
        system = localSystem;

        specialArgs.rk3588 = {
          inherit nixpkgs;
          pkgsKernel = pkgsCross;
        };

        modules = [
          sops-nix.nixosModules.sops
          ./modules/configuration.nix

          self.nixosModules.boards.orangepi5plus.core
          self.nixosModules.boards.orangepi5plus.sd-image

          {
            networking.hostName = "orangepi5plus";
            sdImage.imageBaseName = "orangepi5plus-sd-image";
            nixpkgs.crossSystem.config = "aarch64-unknown-linux-gnu";
          }
        ];
      };

      packages.${localSystem}.sdImage-opi5plus-cross =
        self.nixosConfigurations.orangepi5plus-cross.config.system.build.sdImage;
    }
    // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.fhsEnv =
        (pkgs.buildFHSEnv {
          name = "kernel-build-env";
          targetPkgs = pkgs_: (with pkgs_;
            [
              pkg-config
              ncurses
              pkgsCross.gccStdenv.cc
              gcc
            ]
            ++ pkgs.linux.nativeBuildInputs);
          runScript = pkgs.writeScript "init.sh" ''
            export CROSS_COMPILE=aarch64-unknown-linux-gnu-
            export ARCH=arm64
            export PKG_CONFIG_PATH="${pkgs.ncurses.dev}/lib/pkgconfig:"
            exec bash
          '';
        }).env;
    });
}