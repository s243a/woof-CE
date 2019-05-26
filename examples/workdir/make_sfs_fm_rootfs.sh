#!/bin/bash

#mkfifo fifo_pkg_list

#https://unix.stackexchange.com/questions/63923/pseudo-files-for-temporary-data
export WORK_DIR=${WORK_DIR:-"`realpath .`"}
export CURDIR="`dirname "$(realpath "$(readlink build-sfs.sh)")"`"
cmnds="$(echo "\
%depend
#%dpkgchroot
#%libpsl5
wget
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
  