#!/bin/bash

QEMU_LD_PREFIX=/usr/aarch64-linux-gnu LANG=C MAKEFLAGS=-j$(nproc --all) "$(dirname "$0")/makepkg.sh" -s -f -A --noconfirm --config "$(dirname "$0")/makepkg.conf" "$@"
