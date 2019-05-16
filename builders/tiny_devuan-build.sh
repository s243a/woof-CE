#!/bin/sh
WORK_DIR=${WORK_DIR:-"`realpath .`"} #We'll export this if needed
CURDIR="$(dirname "`realpath "$0"`")"  #We'll export this if needed

export PKGLIST=${PKGLIST:-pkglist}
export ARCH=${ARCH:-i386} # or amd64
export VERSION=${VERSION:-ascii}
export DISTRO_PREFIX=${DISTRO_PREFIX:-puppy}
export DISTRO_VERSION=${DISTRO_VERSION:-700} # informative only

export DEFAULT_REPOS=${REPO_URLS:-http://deb.devuan.org/merged/dists/|$VERSION|main:universe|Packages.xz}
#KEEP_DUPLICATES=1 # keep multiple versions of package in pkgdb
#WITH_APT_DB= # default is don't include apt-db

# dirs
export REPO_DIR=${REPO_DIR:-repo-$VERSION-$ARCH}
export CHROOT_DIR=${CHROOT_DIR:-chroot-$VERSION-$ARCH}
export DEVX_DIR=${DEVX_DIR:-devx-holder}
export NLS_DIR=${NLS_DIR:-nls-holder}
export BASE_CODE_PATH=${ROOTFS_BASE:-rootfs-skeleton}
# BASE_ARCH_PATH= # inherit - arch-specific base files, can be empty
export EXTRAPKG_PATH=${EXTRAPKG_PATH:-rootfs-packages}
export BUILD_CONFIG=${BUILD_CONFIG:-"`realpath ./build.conf`"}
#The following cd messes up ". ./repo-url" in build.conf
#cd "$(dirname "`realpath "$0"`")"

$CURDIR/deb-build.sh