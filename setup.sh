#!/bin/bash
if [ "$(id -u)" -ne "0" ]; then
  echo "This script requires root."
  exit 1
fi

if [ ! -d "rootfs" ]; then
  mkdir -p rootfs
  pacstrap -C pacman.conf -M rootfs base base-devel
else
  pacman -Syu --root rootfs --noconfirm --overwrite=* --needed --arch aarch64 --config pacman.conf
fi

# Always override the pacman.conf
cp pacman.conf rootfs/etc/pacman.conf
# So we can run as root user
sed -i "s/EUID == 0/EUID == -1/g" rootfs/usr/bin/makepkg

# Dirty patch the local makepkg for our purposes
cp rootfs/usr/bin/makepkg makepkg.sh
# So pacman uses the correct rootfs, arch and config file
sed -i "s|run_pacman |run_pacman --root \"$(pwd)\/rootfs\" --arch aarch64 --config \"$(pwd)\/pacman.conf\" |g" makepkg.sh

mkdir -p pkgs
