# Documentation

## Overview

This project builds a NixOS SD card image for the **Orange Pi 5 Plus** (RK3588) single-board computer,
used by Abingdon School in the **Student Robotics 2027** competition.

Originally forked from [ryan4yin/nixos-rk3588](https://github.com/ryan4yin/nixos-rk3588), which
supported multiple boards (Orange Pi 5/5B/5 Plus/5 Pro, Rock 5A). This fork strips everything
except the Orange Pi 5 Plus cross-compile configuration.

---

## Build

```bash
# Cross-compile from x86_64
nix build .#sdImage-opi5plus-cross

# Flash to SD card
zstdcat result/sd-image/orangepi5plus-sd-image-*.img.zst | sudo dd status=progress bs=8M of=/dev/sdX
```

---

## Boot Process (U-Boot)

1. BootROM loads from SPI NOR flash
2. U-Boot reads `/boot/extlinux/extlinux.conf` from the root partition
3. U-Boot loads kernel (Image), initrd, and device tree
4. Kernel boots with NixOS init

### Pre-flash U-Boot to SPI NOR (one-time)

The Orange Pi 5 Plus boots U-Boot from SPI NOR flash (onboard chip). This must be
flashed once before the NixOS SD card will boot.

```bash
# 1. Download an Armbian image for Orange Pi 5 Plus
#    From: https://www.armbian.com/orange-pi-5-plus/
#    Or directly from armbian's mirrors (example URL — check for latest):
#    https://redirect.armbian.com/orangepi5-plus/Bookworm/current

# 2. Flash Armbian to a temporary SD card
xzcat Armbian_*.img.xz | sudo dd status=progress bs=8M of=/dev/sdX

# 3. Boot the Orange Pi 5 Plus from that SD card and log in (root / 1234)
#    You'll be prompted to set a new root password and create a user.

# 4. Install U-Boot to SPI NOR flash
sudo armbian-install
#    → Select "Boot from SPI" (or similar option)
#    → Confirm when prompted — this writes U-Boot to the SPI NOR chip

# 5. Power off, remove the Armbian SD card
sudo poweroff

# 6. Insert the NixOS SD card and power on — it will boot from SPI NOR U-Boot
```

After this, the SPI NOR flash retains U-Boot permanently. You only need to do this
once per board — subsequent NixOS image updates only require re-flashing the SD card.

---

## Debug with UART

When the system fails to boot, check boot logs through the serial port.

**Orange Pi 5 Plus serial pins:**

![Orange Pi 5 Plus serial pins](/_img/orangepi5plus-serialport.webp)

Connect a USB-to-TTL cable, then:

```bash
minicom -D /dev/ttyUSB0 -b 1500000 -C uartlog
```

Kernel params used: `console=ttyS2,1500000 console=tty1`

---

## Flash NixOS to SSD/eMMC

1. Boot from SD card first
2. Upload the image: `scp result/sd-image/orangepi5plus-sd-image-*.img.zst nixos@<ip>:~/`
3. Identify target disk: `lsblk`
4. Flash: `zstdcat orangepi5plus-sd-image-*.img.zst | sudo dd bs=4M status=progress of=/dev/nvme0n1`
5. Remove SD card and reboot

---

## Hardware

| Property | Value |
|----------|-------|
| SoC | RK3588 |
| Kernel | Armbian linux-rockchip 6.1.115 (rk-6.1-rkr5.1) |
| Boot | U-Boot from SPI NOR flash |
| DTB | `rockchip/rk3588-orangepi-5-plus.dtb` |
| GPU | Mali G610 (firmware from kernel source) |
| WiFi | Pre-configured for `AS_Computer_Science` |

---

## Removed Configurations

This fork removed support for the following boards and build modes:

| Board | SoC | Reason |
|-------|-----|--------|
| Orange Pi 5 | RK3588S | Not in use for SR2027 |
| Orange Pi 5B | RK3588S | Not in use for SR2027 |
| Orange Pi 5 Pro | RK3588S | Not in use for SR2027 |
| Rock 5 Model A | RK3588S | Not in use for SR2027 |

Removed build modes: native aarch64 builds, UEFI/edk2 boot path.
