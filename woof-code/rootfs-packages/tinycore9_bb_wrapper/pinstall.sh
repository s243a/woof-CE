#!/bin/ash
if [ ! -z "$CHROOT_DIR" ]; then
  chroot "$CHROOT_DIR" mk_busybox_utils
elif [ -e usr/bin/mk_busybox_utils ]; then
  export CHROOT_DIR="`realpath .`"
  usr/bin/mk_busybox_utils
fi
