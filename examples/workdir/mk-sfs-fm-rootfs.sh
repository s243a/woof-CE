#!/bin/sh
CHROOT_DIR="chroot-ascii-i386-old10"
export VERSION=${VERSION:-ascii}
export DISTRO_PREFIX=${DISTRO_PREFIX:-puppy}
export DISTRO_VERSION=${DISTRO_VERSION:-700} # informative only

make_sfs() {
	local output="$1" dir=${1%/*}
	shift
	[ "$dir" ] && [ "$dir" != "$output" ] && mkdir -p $dir
	echo $DISTRO_VERSION > $CHROOT_DIR/etc/${DISTRO_PREFIX}-version
	mksquashfs $CHROOT_DIR "$output" -noappend "$@"
	padsfs "$output"
}
make_sfs iso/iso-root/puppy-old10.sfs -comp gzip
