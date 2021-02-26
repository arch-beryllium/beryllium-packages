#!/bin/bash
set -ex

root="$(dirname "$0")/rootfs"

# To speed up dependency installation and source downloading and checking, do it on the host
LANG=C MAKEFLAGS=-j$(nproc --all) "$(dirname "$0")/makepkg.sh" -s -f -A --noconfirm --verifysource --config "$(dirname "$0")/makepkg.conf"

# Simply mount the package source directory to the rootfs
cleanup() {
  umount -lc "$root"/mnt/pkg
}
trap cleanup EXIT
mkdir -p "$root"/mnt/pkg
mount -o bind . "$root"/mnt/pkg

# Now we can skip downloading and checking the sources and installing dependencies
arch-chroot "$root" /bin/bash -c "set -ex && cd /mnt/pkg && LANG=C MAKEFLAGS=-j$(nproc --all) makepkg -f -A --noconfirm --skipinteg --holdver"
