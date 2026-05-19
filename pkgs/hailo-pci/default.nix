{ kernel, stdenv, fetchFromGitHub, lib }:

stdenv.mkDerivation {
  pname = "hailo-pci";
  version = "4.23.0";

  src = fetchFromGitHub {
    owner = "hailo-ai";
    repo = "hailort-drivers";
    rev = "ce1087bfe8132c99b41374e3128fc78612a3f492";
    hash = "sha256-3c5GZOSWJGRZrsTxww445IFnHgABm2NZOP08JinfkTg=";
  };

  buildPhase = ''
    cd linux/pcie
    make -C "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build" M="$PWD" modules
  '';

  installPhase = ''
    install -D -m644 hailo_pci.ko "$out/lib/modules/${kernel.modDirVersion}/kernel/drivers/misc/hailo_pci.ko"
  '';

  meta = {
    description = "Hailo-8 PCIe kernel driver";
    license = lib.licenses.gpl2Only;
    platforms = [ "aarch64-linux" ];
  };
}