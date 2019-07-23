#!/bin/ash
if [ "`pwd`" != "/" ]; then
  chroot usr/bin/mk_busybox_utils
else
  chroot usr/bin/mk_busybox_utils
fi
