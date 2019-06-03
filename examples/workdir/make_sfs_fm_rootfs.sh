#!/bin/bash

#mkfifo fifo_pkg_list

#https://unix.stackexchange.com/questions/63923/pseudo-files-for-temporary-data
export WORK_DIR=${WORK_DIR:-"`realpath .`"}
export CURDIR="`dirname "$(realpath "$(readlink build-sfs.sh)")"`"
cmnds="$(echo "\
%depend
kmod               # called in /etc/rc.d/rc.sysinit aroun d line 580
iptables
#%reinstall libapparmor1    #Dependency of dbus
#%dummy libgdk-pixbuf2.0-common #dependency of libgdk-pixbuf2.0-0
#libgdk-pixbuf2.0-0
#%symlink /usr/lib/i386-linux-gnu/gdk-pixbuf-2.0/gdk-pixbuf-query-loaders /usr/bin

#Not sure if we need to symlink the .so files into LD_LIBRARY_PATH
#We'll uncomment this if we need it
#%chroot cp -sr /usr/lib/i386-linux-gnu/gdk-pixbuf-2.0/2.10.0/loaders/ 

#%reinstall libxmuu1       #Dependency of x11-utils
#xserver-xorg-input-mouse 
#xserver-xorg-input-kbd #THis is the keyboard module
%chroot mkdir -p /usr/X11R7/lib 
%chroot cp -sr /usr/lib/xorg/modules/drivers/ /usr/X11R7/lib 
%addpkg --forced tinycore9_base_gz
%addpkg --forced puppycore_noarch

#%addpkg tinycore9_base_gz_users #Can use instead of puppycore_users
%addpkg --forced puppycore_users

%addpkg --forced puppycore_i386_strech

#Can use tinycore9_base_gz_startup instead of puppycore: _sysinit _sysinit_net _Xstartup
#%addpkg tinycore9_base_gz_startup 

%addpkg --forced puppycore_sysinit
%addpkg --forced puppycore_sysinit_net
%addpkg --forced puppycore_net
%addpkg --forced puppycore_Xstartup
%addpkg --forced puppycore_locale
%addpkg --forced puppycore_utils #Required for puppy startup

%reinstall jwm
%chroot wget http://ftp.us.debian.org/debian/pool/main/g/gnome-menus2/libgnome-menu2_3.0.1-4_i386.deb
%chroot pkg -i libgnome-menu2_3.0.1-4_i386.deb #Needed for fixmenus to work
%addpkg  --forced puppycore_xdg
%addpkg  --forced jwm_config
%chroot fixmenus
%reinstall rox-filer
%addpkg  --forced puppycore_rox
%addpkg  --forced rox-filer-data
%addpkg  --forced rox_config
%addpkg  --forced pthemes

%addpkg --forced debian-setup # specific debian setup, overriding puppy-base

#Dependencies for pkg (maybe create wrappers for these instead of installing them)
%reinstall findutils #Dependency of PKG
%reinstall sed       #Dependency of PKG
%reinstall grep      #Dependency of PKG
%reinstall wget      #required for pkg
%reinstall coreutils #pkg requires "sort" from coreutils
%reinstall file
%reinstall gettext-base
%reinstall gettext
%reinstall util-linux
%reinstall libsystemd0    #Dependency for dbus, libdbus-1-3,procps (via libprocps6)
%reinstall libprocps6  #Required for procps
%reinstall procps
%reinstall mount

%addpkg --forced sync_pet_specs_fm_dpkg
%chroot sync_pet_specs_fm_dpkg.sh
%addpkg --forced puppy_ppm_configs_devaun_ascii
%addpkg --forced PKG
%chroot pkg --repo-update  #Update the packge repos
%chroot ldconfig
%makesfs iso/iso-root/puppy.sfs -comp gzip # -Xcompression-level 1
")
"
#pkglist="`echo <( echo $cmnds )`"
mkfifo pkglist4
( echo "$cmnds" > pkglist4 ) &

#cd $CURDIR
. build-sfs.sh --sourced pkglist4
read -p "Press enter to continue"

flatten_pkglist $PKGLIST > $FLATTEN
if [ -z "$DRY_RUN" ]; then
	process_pkglist $FLATTEN
else
	cat $FLATTEN
fi

#fclose(pkglist)
  