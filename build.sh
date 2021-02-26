#!/bin/bash
function get_package_dir() {
  echo "./pkgs/$(basename "$1" | sed "s/\.git//")"
}
function update_package_repo() {
  dir="$(get_package_dir "$1")"
  if [ ! -d "$dir" ]; then
    git clone --depth=1 "$1" "$dir"
  else
    (
      cd "$dir" || exit 1
      git checkout .
      git reset --hard
      git pull
    )
  fi
}
function install_package() {
  pacman -U "$(get_package_dir "$1")"/*.pkg* --root rootfs --noconfirm --overwrite=* --needed --arch aarch64 --config pacman.conf
}
function add_package_to_repo() {
  mkdir -p repo
  dir="$(get_package_dir "$1")"
  for file in "$dir"/*.pkg*; do
    if [ ! -f "repo/$(basename "$file")" ]; then
      mv "$file" repo
      repo-add -R -n -p repo/beryllium.db.tar.xz "repo/$(basename "$file")"
    else
      rm "$file"
    fi
  done
}

function _cross_compile_package() {
  update_package_repo "$1"
  cd "$(get_package_dir "$1")" || exit 1
  ../../cross_compile_package.sh
  cd ../..
}
function cross_compile_package() {
  _cross_compile_package "$1"
  add_package_to_repo "$1"
}
function cross_compile_and_install_package() {
  _cross_compile_package "$1"
  install_package "$1"
  add_package_to_repo "$1"
}

function _host_compile_package() {
  update_package_repo "$1"
  cd "$(get_package_dir "$1")" || exit 1
  ../../host_compile_package.sh
  cd ../..
}
function host_compile_package() {
  _host_compile_package "$1"
  add_package_to_repo "$1"
}
function host_compile_and_install_package() {
  _host_compile_package "$1"
  install_package "$1"
  add_package_to_repo "$1"
}

if [ "$(id -u)" -ne "0" ]; then
  echo "This script requires root."
  exit 1
fi

set -ex

if [ ! -f "makepkg.sh" ]; then
  # Dirty patching makepkg the local makepkg for our purposes
  cp "$(which makepkg)" makepkg.sh
  # So we can run as root user
  sed -i "s/EUID == 0/EUID == -1/g" makepkg.sh
  # So pacman uses the correct rootfs, arch and config file
  sed -i "s|run_pacman |run_pacman --root \"$(pwd)\/rootfs\" --arch aarch64 --config \"$(pwd)\/pacman.conf\" |g" makepkg.sh
fi

if [ ! -d "rootfs" ]; then
  mkdir -p rootfs
  pacstrap -C pacman.conf -M rootfs base base-devel
  cp pacman.conf rootfs/etc/pacman.conf
  # So we can run as root user
  sed -i "s/EUID == 0/EUID == -1/g" rootfs/usr/bin/makepkg
else
  pacman -Syu --root rootfs --noconfirm --overwrite=* --needed --arch aarch64 --config pacman.conf
fi

mkdir -p pkgs

cross_compile_and_install_package "https://aur.archlinux.org/qrtr-git.git"
cross_compile_and_install_package "https://aur.archlinux.org/qmic-git.git"
cross_compile_package "https://github.com/arch-beryllium/tqftpserv-git.git"
cross_compile_package "https://aur.archlinux.org/rmtfs-git.git"
cross_compile_package "https://aur.archlinux.org/pd-mapper-git.git"

cross_compile_package "https://github.com/arch-beryllium/firmware-xiaomi-beryllium-git.git"
cross_compile_package "https://github.com/arch-beryllium/linux-beryllium.git"
cross_compile_package "https://github.com/arch-beryllium/alsa-ucm-beryllium.git"
cross_compile_and_install_package "https://github.com/arch-beryllium/ofono-git.git"
host_compile_package "https://github.com/arch-beryllium/kwin-git.git"
host_compile_package "https://github.com/arch-beryllium/unity8-git.git"
host_compile_package "https://github.com/arch-beryllium/unity-system-compositor-git.git"
