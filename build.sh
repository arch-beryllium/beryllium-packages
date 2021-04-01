#!/bin/bash
function get_package_dir() {
  echo "./pkgs/$(basename "$1" | sed "s/\.git//")"
}
function check_already_built() {
  cd "$(get_package_dir "$1")" || exit 1
  readarray -t lines <<<$"$(../../makepkg.sh -f -A --config ../../makepkg.conf --packagelist)"
  for line in "${lines[@]}"; do
    file="$(basename "$line")"
    if [ ! -f "../../repo/$file" ]; then
      cd ../..
      echo "0"
      return 0
    fi
  done
  cd ../..
  echo "1"
}
function update_package_repo() {
  dir="$(get_package_dir "$1")"
  if [ ! -d "$dir" ]; then
    git clone --depth=1 "$1" "$dir"
  else
    (
      cd "$dir" || exit 1
      git fetch --all
      git reset --hard origin/"$(git branch --show-current)"
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
  ../../cross_compile_package.sh "$2"
  cd ../..
}
function cross_compile_package() {
  _cross_compile_package "$1" --nobuild
  if [ "$(check_already_built "$1")" == "0" ]; then
    _cross_compile_package "$1"
    add_package_to_repo "$1"
  fi
}
function cross_compile_and_install_package() {
  _cross_compile_package "$1" --nobuild
  if [ "$(check_already_built "$1")" == "0" ]; then
    _cross_compile_package "$1"
    install_package "$1"
    add_package_to_repo "$1"
  fi
}

function _host_compile_package() {
  update_package_repo "$1"
  cd "$(get_package_dir "$1")" || exit 1
  ../../host_compile_package.sh "$2"
  cd ../..
}
function host_compile_package() {
  _host_compile_package "$1" --nobuild
  if [ "$(check_already_built "$1")" == "0" ]; then
    _host_compile_package "$1"
    add_package_to_repo "$1"
  fi
}
function host_compile_and_install_package() {
  _host_compile_package "$1" --nobuild
  if [ "$(check_already_built "$1")" == "0" ]; then
    _host_compile_package "$1"
    install_package "$1"
    add_package_to_repo "$1"
  fi
}

if [ "$(id -u)" -ne "0" ]; then
  echo "This script requires root."
  exit 1
fi

./setup.sh

cross_compile_and_install_package "https://aur.archlinux.org/qrtr-git.git"
cross_compile_and_install_package "https://aur.archlinux.org/qmic-git.git"
cross_compile_package "https://github.com/arch-beryllium/tqftpserv-git.git"
cross_compile_package "https://aur.archlinux.org/rmtfs-git.git"
cross_compile_package "https://aur.archlinux.org/pd-mapper-git.git"
host_compile_package "https://github.com/arch-beryllium/bootsplash.git"
host_compile_package "https://github.com/arch-beryllium/tweaks.git"
cross_compile_package "https://github.com/arch-beryllium/meta.git"
cross_compile_package "https://github.com/arch-beryllium/usb-tethering.git"
cross_compile_package "https://github.com/arch-beryllium/firmware-xiaomi-beryllium.git"
cross_compile_package "https://github.com/arch-beryllium/mkbootimg-tools-git.git"
cross_compile_package "https://github.com/arch-beryllium/linux-beryllium.git"
cross_compile_package "https://github.com/arch-beryllium/alsa-ucm-beryllium.git"
host_compile_and_install_package "https://github.com/arch-beryllium/ofono-git.git"
host_compile_package "https://github.com/arch-beryllium/kwin-git.git"
host_compile_package "https://github.com/arch-beryllium/unity8-git.git"
host_compile_package "https://github.com/arch-beryllium/unity-system-compositor-git.git"
