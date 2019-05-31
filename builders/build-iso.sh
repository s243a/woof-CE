#!/bin/bash
# James way of making iso
# Copyright (C) James Budiono 2014
# License: GNU GPL Version 3 or later.
#
# Download kernel, make initrd, output iso.

### config
set -x
ZDRV_SFS=${ZDRV_SFS:-kernel-modules.sfs}
OUTPUT_DIR=${OUTPUT_DIR:-iso}
OUTPUT_ISO=${OUTPUT_ISO:-puppy.iso}
ISO_ROOT=${ISO_ROOT:-$OUTPUT_DIR/iso-root}
DISTRO_PREFIX=${DISTRO_PREFIX:-puppy}

PUPPY_SFS=${PUPPY_SFS:-puppy.sfs}
SOURCE=${PARENT_DISTRO:-ubuntu}       # informative only
DISTRO_VERSION=${DISTRO_VERSION:-700} # informative only
TARGET_ARCH=${TARGET_ARCH:-x86}       # informative only

KERNEL_URL=${KERNEL_URL:-http://distro.ibiblio.org/puppylinux/huge_kernels}
KERNEL_TARBALL=${KERNEL_TARBALL:-huge-3.4.93-slacko32FD4G.tar.bz2}

WOOFCE=${WOOFCE:-..}
ISOLINUX_BIN=${ISOLINUX_BIN:-$WOOFCE/woof-arch/x86/build/boot/isolinux.bin}
ISOLINUX_CFG=${ISOLINUX_FILES:-$WOOFCE/woof-code/boot/boot-dialog}
INITRD_ARCH=${INITRD_ARCH:-$WOOFCE/woof-arch/x86/target/boot/initrd-tree0}
INITRD_CODE=${INITRD_CODE:-$WOOFCE/woof-code/boot/initrd-tree0}

###
BUILD_CONFIG=${BUILD_CONFIG:-./build.conf}
[ -e $BUILD_CONFIG ] && . $BUILD_CONFIG


### helpers
install_boot_files() {
	cp $ISOLINUX_BIN $ISO_ROOT
	for p in boot.msg help.msg help2.msg isolinux.cfg logo1.16; do
		! [ -e $ISO_ROOT/$p ] && cp $ISOLINUX_CFG/$p $ISO_ROOT
	done
	grep -q logo.16 $ISO_ROOT/boot.msg && sed -i -e 's/logo.16/logo1.16/' $ISO_ROOT/boot.msg
	! grep -q pfix=nox $ISO_ROOT/isolinux.cfg && sed -i -e 's|pmedia=cd|& pfix=nox|' $ISO_ROOT/isolinux.cfg
	grep -q BOOTLABEL $ISO_ROOT/isolinux.cfg && sed -i -e "s|BOOTLABEL|$DISTRO_PREFIX|" $ISO_ROOT/isolinux.cfg
}

install_kernel() {
	# check that kernel is already installed
	for p in vmlinuz kernel-modules.sfs; do
		if ! [ -e $ISO_ROOT/$p ]; then
			install_extract_kernel && return # attempt to use existing
			echo Downloading kernel $KERNEL_TARBALL ...
			if [ $KERNEL_URL ]; then
				wget -c $KERNEL_URL/$KERNEL_TARBALL
				wget -c $KERNEL_URL/${KERNEL_TARBALL}.md5.txt
				install_extract_kernel && return # attempt to use existing
			else
				echo "Missing kernel. You can build one with kernel-kit. Fatdog-style kernel is required." &&
				exit
			fi
		fi
	done
}
#s243a:TODO add install_firmware
install_extract_kernel() {
	if md5sum -c ${KERNEL_TARBALL}.md5.txt 2>/dev/null; then
		tar -xf ${KERNEL_TARBALL} -C $ISO_ROOT
		mv $ISO_ROOT/vmlinuz-* $ISO_ROOT/vmlinuz
		mv $ISO_ROOT/kernel-modules.sfs-* $ISO_ROOT/$ZDRV_SFS
		return 0
	fi
	return 1
}
_(){
  eval "echo \"$1\""
}

echo_sfs_drvs(){
  #DISTRO_ZDRVSFS=kernel-modules.sfs
 for A_DRV in F Z Y A; do 
  a_drv=$(echo $A_DRV | tr '[:upper:]' '[:lower:]')
  if [ ! -z "$(_ "\$${A_DRV}DRV_SFS")" ]; then 
    echo DISTRO_${A_DRV}DRVSFS="$(_ "\$${A_DRV}DRV_SFS")";   
  elif [ -f $ISO_ROOT/"$a_drv"drv_sfs.sfs ]; then 
    echo DISTRO_${A_DRV}DRVSFS="$a_drv"drv_sfs.sfs; 
  elif [ -f $ISO_ROOT/"$a_drv"drv_"$SFS_SUFIX".sfs ]; then 
    echo DISTRO_${A_DRV}DRVSFS="$a_drv"drv_"$SFS_SUFIX".sfs; 
  elif [ -f $ISO_ROOT/"$a_drv"drv.sfs ]; then 
    echo DISTRO_${A_DRV}DRVSFS="$a_drv"drv.sfs    
  fi
 done
}
install_initrd() {
	local initrdtmp=/tmp/initrd.tmp.$$
	mkdir -p "$initrdtmp/pup_new/initrd"
    tar -xzf "$WOOFCE/woof-arch/woof-code_boot_initrd-tree0_DEVDIR.tar.gz" \
        -C "$initrdtmp/"
    mv "$initrdtmp"/dev "$initrdtmp/dev2"

    #cp "$WOOFCE/woof-arch/woof-code_rootfs-skeleton_DEVDIR.tar.gz" "$initrdtmp/dev1.tar.gz"
    #cp "$WOOFCE/woof-arch/woof-code_boot_initrd-tree0_DEVDIR.tar.gz" \
    #  "$initrdtmp/dev1.tar.gz"
    #cp "$WOOFCE/woof-arch/woof-code_rootfs-skeleton_DEVDIR.tar.gz" \
    #  "$initrdtmp/dev2.tar.gz"
    tar -xzf "$WOOFCE/woof-arch/woof-code_rootfs-skeleton_DEVDIR.tar.gz" \
        -C "$initrdtmp/"    
    mv "$initrdtmp"/dev "$initrdtmp/dev3"    
	mkdir -p "$initrdtmp/dev"        
	# copy over source files and cleanup
	cp -a $INITRD_ARCH/* $INITRD_CODE/* $initrdtmp
	find $initrdtmp -name '*MARKER' -delete
	[ ! -e "$initrdtmp/bin/bb-create-symlinks" ] && \
	cp -f "$WOOFCE/initrd-progs/pkg/busybox_static/bb-create-symlinks" \
	       "$initrdtmp/bin/bb-create-symlinks" 
	( cd $initrdtmp/bin; sh bb-create-symlinks; )

	# create minimal distro specs, read woof's docs to get the meaning
	> $initrdtmp/DISTRO_SPECS cat << EOF
DISTRO_NAME='$SOURCE Puppy'
DISTRO_VERSION='$DISTRO_VERSION'
DISTRO_BINARY_COMPAT='$SOURCE'
DISTRO_FILE_PREFIX='$SOURCE'
DISTRO_COMPAT_VERSION='$SOURCE'
DISTRO_XORG_AUTO='yes'
DISTRO_TARGETARCH='$TARGET_ARCH'
DISTRO_DB_SUBNAME='$SOURCE'
DISTRO_PUPPYSFS=$PUPPY_SFS
$(echo_sfs_drvs)
EOF
	( cd $initrdtmp; find . | cpio -o -H newc ) | gzip -9 > $ISO_ROOT/initrd.gz
	#rm -rf $initrdtmp
}

make_iso() {
	xorriso="$(which xorriso)"
	if [ -n "$xorriso" ]; then
		$xorriso -as mkisofs \
		-iso-level 3 \
		-full-iso9660-filenames \
		-volid "Puppy-Linux" \
		-appid "Puppy-Linux" \
		-eltorito-boot isolinux.bin \
		-eltorito-catalog boot.cat \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
		-output "$OUTPUT_DIR/$OUTPUT_ISO" \
		$ISO_ROOT/
	else
		mkisofs -o "$OUTPUT_DIR/$OUTPUT_ISO" \
		-volid "Puppy-Linux" \
		-iso-level 4 -D -R  \
		-b isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
		$ISO_ROOT/
	fi
	isohybrid -o 64 "$OUTPUT_DIR/$OUTPUT_ISO"
}

### main
mkdir -p $ISO_ROOT
! [ -e $ISO_ROOT/$PUPPY_SFS ] && echo Put $PUPPY_SFS to $ISO_ROOT. && exit 1
install_boot_files
install_kernel
install_initrd
make_iso
