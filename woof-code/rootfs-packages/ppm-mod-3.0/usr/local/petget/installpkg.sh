#!/bin/sh
#(c) Copyright Barry Kauler 2009, puppylinux.com
#2009 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html).
#called from /usr/local/petget/downloadpkgs.sh and petget.
#passed param is the path and name of the downloaded package.
#/tmp/petget-proc/petget_missing_dbentries-Packages-* has database entries for the set of pkgs being downloaded.
#w456 warning: petget may write to /tmp/petget-proc/petget_missing_dbentries-Packages-alien with missing fields.
#w478, w482 fix for pkg menu categories.
#w482 detect zero-byte pet.specs, fix typo.
#100110 add support for T2 .tar.bz2 binary packages.
#100426 aufs can now write direct to save layer.
#100616 add support for .txz slackware pkgs.
# 20aug10 shinobar: excute pinstall.sh under original LANG environment
#  6sep10 shinobar: warning to install on /mnt/home # 16sep10 remove test code
# 17sep10 shinobar; fix typo was double '|' at reading DESCRIPTION
# 22sep10 shinobar clean up probable old files for precaution
# 22sep10 shinobar: bugfix was not working clean out whiteout files
#110503 change ownership of some files if non-root.
#110523 support for rpm pkgs.
#110705 fix rpm install.
#110817 rcrsn51: fix find syntax, looking for icons. 110821 improve.
#111013 shinobar: aufs direct-write to layer not working, bypass for now.
#111013 revert above. it works for me, except if file already on top -- that is another problem, needs to be addressed.
#111207 improve search for menu icon.
#111229 /usr/local/petget/removepreview.sh when uninstalling a pkg, may have copied a file from sfs-layer to top, check.
#120102 install may have overwritten a symlink-to-dir.
#120107 rerwin: need quotes around some paths in case of space chars. remove '--unlink-first' from tar (was introduced 120102, don't think necessary).
#120126 noryb009: fix typo.
#120219 was not properly internationalized (there was no TEXTDOMAIN).
#120523 may need to run gio-query-modules and/or glib-compile-schemas. (refer also rc.update and 3builddistro)
#120628 fix Categories= assignment in .desktop files. see also 2createpackages in woof.
#120818 Categories management improved. pkg db now has category[;subcategory] (see 0setup), xdg enhanced (see /etc/xdg and /usr/share/desktop-directories), and generic icons for all subcategories (see /usr/local/lib/X11/mini-icons).
#120901 .desktop files, get rid of param on end of Exec, ex: Exec=gimp-2.8 %U
#120907 post-install hacks.
#120926 apply translation for .desktop file if langpack installed.
#121015 01micko: alternative code to delete %-param off end of Exec line in .desktop file.
#121109 fixing Categories field in .desktop may fail, as DB_category field may not match that in .desktop file, so leave out that $tPATTERN match in $PUPHIERARCHY.
#121109 menu category was not reported correctly in post-install window.
#121119 change in layout of /etc/xdg/menus/hierarchy caused regex pattern bug.
#121119 if only one .desktop file, first check if a match in /usr/local/petget/categories.dat.
#121120 bugfix of 121119.
#121123 having a problem with multiarch symlinks in full-installation, getting replaced by a directory.
#121206 default icon needs .xpm extension. note puppy uses older xdg-utilities, Icon field needs image ext.
#121217 still getting reports multiarch symlinks getting overwritten.
#130112 some deb's have a post-install script (ex: some python debs).
#130112 multiarch symlinks now optional. see also 2createpackages, 3builddistro.
#130114 revert 130112 "multiarch symlinks now optional".
#130126 'categories.dat' format changed.
#130219 grep, ignore case.
#130305 rerwin: ensure tmp directory has all permissions after package expansion.
#130314 install arch linux pkgs. run arch linux pkg post-install script.
#131122 support xz compressed pets (see dir2pet, pet2tgz), changed file test
#171128 mistfire: write pet specs for deb

GTKVERLIST='1.0 2.0 3.0'

[ "$(cat /var/local/petget/nt_category 2>/dev/null)" != "true" ] && \
 [ -f /tmp/petget-proc/install_quietly ] && set -x
 #; mkdir -p /tmp/petget-proc/PPM_LOGs ; NAME=$(basename "$0"); exec 1>> /tmp/petget-proc/PPM_LOGs/"$NAME".log 2>&1

export TEXTDOMAIN=petget___installpkg.sh
export OUTPUT_CHARSET=UTF-8

APPDIR=$(dirname $0)
[ -f "$APPDIR/i18n_head" ] && source "$APPDIR/i18n_head"
LANG_USER=$LANG
export LANG=C
. /etc/rc.d/PUPSTATE  #this has PUPMODE and SAVE_LAYER.
. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION

. /etc/xdg/menus/hierarchy #w478 has PUPHIERARCHY variable.

[ "$PUPMODE" = "2" ] && [ ! -d /audit ] && mkdir -p /audit

DLPKG="$1"
DLPKG_BASE="`basename "$DLPKG"`" #ex: scite-1.77-i686-2as.tgz
DLPKG_PATH="`dirname "$DLPKG"`"  #ex: /root
DL_SAVE_FLAG=$(cat /var/local/petget/nd_category 2>/dev/null)


update_file_list(){

pkg1="$1"

pkgfound=`cat /root/.packages/user-installed-packages | grep "|$pkg1|" | cut -f 1 -d '|'`

if [ "$pkgfound" != "" ]; then

while IFS='' read -r line || [[ -n "$line" ]]; do

 if [ "$(cat /root/.packages/package-files/${DLPKG_NAME}.files | grep "$line")" == "" ]; then
 echo "$line" >> /root/.packages/package-files/${DLPKG_NAME}.files
 fi
	
done < /root/.packages/package-files/$pkgfound.files

rm -f /root/.packages/package-files/$pkgfound.files

cat /root/.packages/user-installed-packages | grep -v "|$pkg1|" > /root/.packages/user-installed-packages.new
mv -f /root/.packages/user-installed-packages.new /root/.packages/user-installed-packages

fi

}

write_deb_spec(){

if [ ! -f /DEBIAN/control ]; then
return
fi

#pkgname|nameonly|version|pkgrelease|category|size|path|fullfilename|dependencies|description|

pkgname="${DLPKG_NAME}"
nameonly=`cat /DEBIAN/control | grep "Package:" | cut -f 2 -d ':' | sed -e "s#^ ##g"`
version=`cat /DEBIAN/control | grep "Version:" | cut -f 2 -d ':' | sed -e "s#^ ##g" | cut -f 1 -d '-'`
pkgrelease=`cat /DEBIAN/control | grep "Version:" | cut -f 2 -d ':' | sed -e "s#^ ##g" | cut -f 2 -d '-'`
category=""
size="${PKGSIZEK}K"
path=""	
fullfilename=${DLPKG_BASE}
description=`cat /DEBIAN/control | grep "Description:" | cut -f 2 -d ':' | sed -e "s#^ ##g" | head -1`
dependencies=""
depends=`cat /DEBIAN/control | grep "Depends:" | cut -f 2 -d ':' | sed -e "s#^ ##g" -e "s#, # #g" -e "s#(#|#g" -e "s# |#|#g" -e "s# [0-9]##g"` 

for dep1 in $depends
do
depname=`echo $dep1 | cut -f 1 -d '|'`
 if [ "$dependencies" == "" ]; then
 dependencies="+$depname"
 else
 dependencies="$dependencies,+$depname"
 fi
done 

echo "$pkgname|$nameonly|$version|$pkgrelease|$category|$size|$path|$fullfilename|$dependencies|$description|" > /pet.specs	
	
}

write_arch_spec(){

if [ ! -f /.PKGINFO ]; then
return
fi

pkgname="${DLPKG_NAME}"
nameonly=`cat /.PKGINFO | grep "pkgname =" | cut -f 2 -d '=' | sed -e "s#^ ##g"`
version=`cat /.PKGINFO | grep "pkgver =" | cut -f 2 -d '=' | sed -e "s#^ ##g" | cut -f 1 -d '-'`
pkgrelease=`cat /.PKGINFO | grep "pkgver =" | cut -f 2 -d '=' | sed -e "s#^ ##g" | cut -f 2 -d '-'`
category=""
size="${PKGSIZEK}K"
path=""	
fullfilename=${DLPKG_BASE}
description=`cat /.PKGINFO | grep "pkgdesc" | cut -f 2 -d '=' | sed -e "s#^ ##g"`
dependencies=""

for dep1 in `cat /.PKGINFO | grep "depend =" | sed "s# = #=#g"`
do
depname=`echo $dep1 | cut -f 2 -d '=' | sed -e "s#^ ##g"`
 if [ "$dependencies" == "" ]; then
 dependencies="+$depname"
 else
 dependencies="$dependencies,+$depname"
 fi
done 

echo "$pkgname|$nameonly|$version|$pkgrelease|$category|$size|$path|$fullfilename|$dependencies|$description|" > /pet.specs	
	
}

write_slack_spec(){
	
if [ ! -f /install/slack-desc ]; then
return
fi

pkgname="${DLPKG_NAME}"
nameonly=`cat /install/slack-desc | grep ": " | head -n 1 | cut -f 1 -d ":" | sed -e "s#^ ##g"`
version="$DB_version"
pkgrelease="$DB_pkgrelease"
category=""
size="${PKGSIZEK}K"
path=""	
fullfilename=${DLPKG_BASE}
description=`cat /install/slack-desc | grep ": " | head -n 1 | cut -f 2 -d ":" | sed -e "s#^ ##g" | cut -f 2 -d '(' | sed -e "s#)##g"`

dependencies=""

if [ -f /install/slack-required ]; then

for dep1 in `cat /install/slack-required | sed -e "s#| #\n##g" | cut -f 1 -d ' '`
do
 if [ "$dependencies" == "" ]; then
 dependencies="+$dep1"
 else
 dependencies="$dependencies,+$dep1"
 fi
done 

fi

echo "$pkgname|$nameonly|$version|$pkgrelease|$category|$size|$path|$fullfilename|$dependencies|$description|" > /pet.specs	
	
}

write_rpm_spec(){
	
if [ ! -f /rpm-info ]; then
return
fi

pkgname="${DLPKG_NAME}"
nameonly=`cat /rpm-info | grep "Name" | grep ":" | cut -f 2 -d ':' | sed -e "s#^ ##g"`
version=`cat /rpm-info | grep "Version" | grep ":" | cut -f 2 -d ':' | sed -e "s#^ ##g"`
pkgrelease=`cat /rpm-info | grep "Release" | grep ":" | cut -f 2 -d ':' | sed -e "s#^ ##g"`
category=`cat /rpm-info | grep "Group" | grep ":" | cut -f 2 -d ':' | sed -e "s#^ ##g"`
size="${PKGSIZEK}K"
path=""	
fullfilename=${DLPKG_BASE}
description=`cat /rpm-info | grep "Summary" | grep ":" | cut -f 2 -d ':' | sed -e "s#^ ##g"`

dependencies=""

echo "$pkgname|$nameonly|$version|$pkgrelease|$category|$size|$path|$fullfilename|$dependencies|$description|" > /pet.specs	

rm -f /rpm-info
	
}

clean_and_die () {
  rm -f /root/.packages/package-files/${DLPKG_NAME}.files
  exit 1
}

list_file_symlinks(){
	
	cp -f /root/.packages/package-files/${DLPKG_NAME}.files /tmp/petget-proc/${DLPKG_NAME}.files.bak

	while IFS='' read -r line || [[ -n $line ]]
	do
		if [ -f $line ] && [ -L $line ]; then
		  if [ -a $line ]; then
		    basename $line >> /tmp/petget-proc/pkg-exclude-files
		    cat /tmp/petget-proc/${DLPKG_NAME}.files.bak | grep -v "$line" > /tmp/petget-proc/${DLPKG_NAME}.files.bak2 
		    mv -f /tmp/petget-proc/${DLPKG_NAME}.files.bak2 /tmp/petget-proc/${DLPKG_NAME}.files.bak
		  fi
		fi	
	done < /root/.packages/package-files/${DLPKG_NAME}.files
	
	mv -f /tmp/petget-proc/${DLPKG_NAME}.files.bak /root/.packages/package-files/${DLPKG_NAME}.files
	
}

# 6sep10 shinobar: installing files under /mnt is danger
install_path_check() {
  FILELIST="/root/.packages/package-files/${DLPKG_NAME}.files"
  [ -s "$FILELIST" ] || return 0 #120126 noryb009: typo
  grep -q '^/mnt' "$FILELIST" || return 0
  MNTDIRS=$(cat "$FILELIST" | grep '^/mnt/.*/$' | cut -d'/' -f1-3  | tail -n 1)
  LANG=$LANG_USER
  MSG1=$(gettext "This package will install files under")
  MSG2=$(gettext "It can be dangerous to install files under '/mnt' because it depends on the profile of installation.")
  MSG3=""
  if grep -q '^/mnt/home' "$FILELIST"; then
    if [ $PUPMODE -eq 5 ]; then
      MSG3=$(gettext "You are running Puppy without 'pupsave', and '/mnt/home' does not exist. In this case, you can use the RAM for this space, but strongly recommended to shutdown now to create 'pupsave' BEFORE installing these packages.")
      MSG3="$MSG3\\n$(gettext "NOTE: You can install this package for a tentative use, then do NOT make 'pupsave' with this package installed.")"
    fi
    DIRECTSAVEPATH=""
  fi
  # dialog
  export DIALOG="<window title=\"$T_title\" icon-name=\"gtk-dialog-warning\">
  <vbox>
  <text use-markup=\"true\"><label>\"$MSG1: <b>$MNTDIRS</b>\"</label></text>
  <text><input>echo -en \"$MSG2 $MSG3\"</input></text>
  <text><label>$(gettext "Click 'Cancel' not to install(recommended). Or click 'Install' if you like to proceed.")</label></text>
  <hbox>
  <button cancel></button>
  <button><input file stock=\"gtk-apply\"></input><label>$(gettext 'Install')</label><action type=\"exit\">INSTALL</action></button>
  </hbox>
  </vbox>
  </window>"
  RETPARAMS=`gtkdialog -p DIALOG` || echo "$DIALOG" >&2
  eval "$RETPARAMS"
  LANG=C
  [ "$EXIT" = "INSTALL" ]  && return 0
  rm -f "$FILELIST" 
  exit 1
}

# 22sep10 shinobar clean up probable old files for precaution
 rm -f /pet.specs /pinstall.sh /puninstall.sh /install/doinst.sh

#get the pkg name ex: scite-1.77 ...
dbPATTERN='|'"$DLPKG_BASE"'|'
DLPKG_NAME="`cat /tmp/petget-proc/petget_missing_dbentries-Packages-* | grep "$dbPATTERN" | head -n 1 | cut -f 1 -d '|'`"

	case $DLPKG_BASE in
	 *.pet)
	DLPKG_NAME=`basename $DLPKG_BASE .pet`
	;;
	 *.deb)
	DLPKG_NAME=`basename $DLPKG_BASE .deb` 
	;;
	 *.tgz)
	DLPKG_NAME=`basename $DLPKG_BASE .tgz` 
	;;
	 *.txz)
	DLPKG_NAME=`basename $DLPKG_BASE .txz`
	;;
	 *.rpm)
	DLPKG_NAME=`basename $DLPKG_BASE .rpm` 
	;;
     *.cards.tar.xz) 
	DLPKG_NAME=`basename $DLPKG_BASE .cards.tar.xz`
    ;;
     *.cards.tar.gz) 
	DLPKG_NAME=`basename $DLPKG_BASE .cards.tar.gz`
	;;
     *.pkg.tar.xz) 
	DLPKG_NAME=`basename $DLPKG_BASE .pkg.tar.xz`
    ;;
     *.pkg.tar.gz) 
	DLPKG_NAME=`basename $DLPKG_BASE .pkg.tar.gz`
	;;
	 *.tar.gz)
	DLPKG_NAME=`basename $DLPKG_BASE .tar.gz`
	;;
	 *.tar.bz2)
	DLPKG_NAME=`basename $DLPKG_BASE .tar.bz2` 
	;;
	 *.pkg.tar.gz) 
	DLPKG_NAME=`basename $DLPKG_BASE .pisi`
	;;
	 *.tazpkg) 
	DLPKG_NAME=`basename $DLPKG_BASE .tazpkg`
	;;
	 *.sb) 
	DLPKG_NAME=`basename $DLPKG_BASE .sb`
	;;
	 *.lzm) 
	DLPKG_NAME=`basename $DLPKG_BASE .lzm`
	;;
	 *.xzm) 
	DLPKG_NAME=`basename $DLPKG_BASE .xzm`
	;;
	 *.pfs) 
	DLPKG_NAME=`basename $DLPKG_BASE .pfs`
	;; 
	 *.apk)
	DLPKG_NAME=`basename $DLPKG_BASE .apk`
	;;
	 *.spack)
	DLPKG_NAME=`basename $DLPKG_BASE .spack`
	;;
	 *.ipk)
	DLPKG_NAME=`basename $DLPKG_BASE .ipk`
	;;
	 *.xbps)
	DLPKG_NAME=`basename $DLPKG_BASE .xbps`
	;;
	 *.eopkg)
	DLPKG_NAME=`basename $DLPKG_BASE .eopkg`
	;;
	 *.tcz)
	DLPKG_NAME=`basename $DLPKG_BASE .tcz`
	;;
	 *.tce)
	DLPKG_NAME=`basename $DLPKG_BASE .tce`
	;;
	 *.tcel)
	DLPKG_NAME=`basename $DLPKG_BASE .tcel`
	;;
	 *.tcem)
	DLPKG_NAME=`basename $DLPKG_BASE .tcem`
	;;
	 *.dsl)
	DLPKG_NAME=`basename $DLPKG_BASE .dsl`
	;;
	 *.slp)
	DLPKG_NAME=`basename $DLPKG_BASE .slp`
	;;
	esac

echo "Before: $DLPKG_NAME"

PKGMAIN="$DLPKG_NAME"
PKGSIZEB=`stat --format=%s "${DLPKG_PATH}"/${DLPKG_BASE}`
PKGSIZEK=`expr $PKGSIZEB \/ 1024`

case $DLPKG_BASE in
  *.deb)
   #deb ex: xsltproc_1.1.24-1ubuntu2_i386.deb  xserver-common_1.5.2-2ubuntu3_all.deb
   DB_nameonly="`echo -n "$PKGMAIN" | cut -f 1 -d '_'`"
   DB_pkgrelease="`echo -n "$PKGMAIN" | rev | cut -f 2 -d '_' | cut -f 1 -d '-' | rev`"
   prPATTERN="s%\-${DB_pkgrelease}.*%%"
   PKGNAME="`echo -n "$PKGMAIN" | sed -e "$prPATTERN"`"
   DB_version="`echo "$PKGNAME" | cut -f 2 -d '_'`"
  ;;
  *.pet)
   PKGNAME="$PKGMAIN"
   DB_version="`echo -n "$PKGNAME" | grep -o '\-[0-9].*' | sed -e 's%^\-%%'`"
   xDB_version="`echo -n "$DB_version" | sed -e 's%\\-%\\\\-%g' -e 's%\\.%\\\\.%g'`"
   xPATTERN="s%${xDB_version}%%"
   DB_nameonly="`echo -n "$PKGNAME" | sed -e "$xPATTERN" -e 's%\-$%%'`"
   DB_pkgrelease=""
  ;;
  *.tgz)
   #slack ex: xvidtune-1.0.1-i486-1.tgz  printproto-1.0.4-noarch-1.tgz
   PKGNAME="`echo -n "$PKGMAIN" | sed -e 's%\-i[3456]86.*%%' -e 's%\-noarch.*%%'`"
   DB_version="`echo -n "$PKGNAME" | grep -o '\-[0-9].*' | sed -e 's%^\-%%'`"
   xDB_version="`echo -n "$DB_version" | sed -e 's%\\-%\\\\-%g' -e 's%\\.%\\\\.%g'`"
   xPATTERN="s%${xDB_version}%%"
   DB_nameonly="`echo -n "$PKGNAME" | sed -e "$xPATTERN" -e 's%\-$%%'`"
   DB_pkgrelease="`echo -n "$PKGMAIN" | sed -e 's%.*\-i[3456]86%%' -e 's%.*\-x86_64%%' -e 's%.*\-amd64%%' -e 's%.*\-noarch%%' -e 's%^\-%%'`"
  ;;
  *.txz)
   #slack ex: xvidtune-1.0.1-i486-1.tgz  printproto-1.0.4-noarch-1.tgz
   PKGNAME="`echo -n "$PKGMAIN" | sed -e 's%\-i[3456]86.*%%' -e 's%\-noarch.*%%'`"
   DB_version="`echo -n "$PKGNAME" | grep -o '\-[0-9].*' | sed -e 's%^\-%%'`"
   xDB_version="`echo -n "$DB_version" | sed -e 's%\\-%\\\\-%g' -e 's%\\.%\\\\.%g'`"
   xPATTERN="s%${xDB_version}%%"
   DB_nameonly="`echo -n "$PKGNAME" | sed -e "$xPATTERN" -e 's%\-$%%'`"
   DB_pkgrelease="`echo -n "$PKGMAIN" | sed -e 's%.*\-i[3456]86%%' -e 's%.*\-noarch%%' -e 's%.*\-x86_64%%' -e 's%.*\-amd64%%' -e 's%^\-%%'`"
  ;;
  *.pkg.tar.gz)
   #arch ex: xproto-7.0.14-1-i686.pkg.tar.gz  trapproto-3.4.3-1.pkg.tar.gz
   PKGNAME="`echo -n "$PKGMAIN" | sed -e 's%\-i[3456]86.*%%' -e 's%\.pkg$%%' | rev | cut -f 2-9 -d '-' | rev`"
   DB_version="`echo -n "$PKGNAME" | grep -o '\-[0-9].*' | sed -e 's%^\-%%'`"
   xDB_version="`echo -n "$DB_version" | sed -e 's%\\-%\\\\-%g' -e 's%\\.%\\\\.%g'`"
   xPATTERN="s%${xDB_version}%%"
   DB_nameonly="`echo -n "$PKGNAME" | sed -e "$xPATTERN" -e 's%\-$%%'`"
   DB_pkgrelease="`echo -n "$PKGMAIN" | sed -e 's%\-i[3456]86.*%%' -e 's%\-x86_64.*%%' -e 's%\-amd64.*%%' -e 's%\.pkg$%%' | rev | cut -f 1 -d '-' | rev`"
  ;;
  *.pkg.tar.xz)
   #arch ex: xproto-7.0.14-1-i686.pkg.tar.gz  trapproto-3.4.3-1.pkg.tar.gz
   PKGNAME="`echo -n "$PKGMAIN" | sed -e 's%\-i[3456]86.*%%' -e 's%\.pkg$%%' | rev | cut -f 2-9 -d '-' | rev`"
   DB_version="`echo -n "$PKGNAME" | grep -o '\-[0-9].*' | sed -e 's%^\-%%'`"
   xDB_version="`echo -n "$DB_version" | sed -e 's%\\-%\\\\-%g' -e 's%\\.%\\\\.%g'`"
   xPATTERN="s%${xDB_version}%%"
   DB_nameonly="`echo -n "$PKGNAME" | sed -e "$xPATTERN" -e 's%\-$%%'`"
   DB_pkgrelease="`echo -n "$PKGMAIN" | sed -e 's%\-i[3456]86.*%%' -e 's%\-x86_64.*%%' -e 's%\-amd64.*%%' -e 's%\.pkg$%%' | rev | cut -f 1 -d '-' | rev`"
  ;;
  *.rpm) #110523
   #exs: hunspell-fr-3.4-1.1.el6.noarch.rpm
   PKGNAME="$PKGMAIN"
   DB_version="`echo -n "$PKGNAME" | grep -o '\-[0-9].*' | sed -e 's%^\-%%'`"
   xDB_version="`echo -n "$DB_version" | sed -e 's%\\-%\\\\-%g' -e 's%\\.%\\\\.%g'`"
   xPATTERN="s%${xDB_version}%%"
   DB_nameonly="`echo -n "$PKGNAME" | sed -e "$xPATTERN" -e 's%\-$%%'`"
   DB_pkgrelease=""
  ;;
  *.sb|*.lzm|*.xzm)
   PKGNAME="$PKGMAIN"
   DB_version=""
   xDB_version=""
   xPATTERN=""
   DB_nameonly="`echo -n "$PKGNAME" | sed -e "s/^[0-9]\-//"`"
   DB_pkgrelease=""
  ;;
  *.tcz|*.tce|*.tcem|*.tcel)
   PKGNAME="$PKGMAIN"
   DB_version=""
   xDB_version=""
   xPATTERN=""
   DB_nameonly="`echo -n "$PKGNAME" | sed -e "s/^[0-9]\-//"`"
   DB_pkgrelease=""
  ;;
  *.apk)
   PKGNAME="$PKGMAIN"
   DB_version="`echo -n "$PKGNAME" | grep -o '\-[0-9].*' | sed -e 's%^\-%%g' | cut -f 1 -d '-'`"
   xDB_version="`echo -n "$PKGNAME" | grep -o '\-[0-9].*'`"
   xPATTERN="s%${xDB_version}%%"
   DB_nameonly="`echo -n "$PKGNAME" | sed -e "$xPATTERN"`"
   DB_pkgrelease="`echo -n "$PKGNAME" | grep -o '\-[0-9].*' | sed -e 's%^\-%%g' | cut -f 2 -d '-' | sed -e "s%^r%%"`"
  ;;
  *.spack)
   PKGNAME="`echo -n "$PKGMAIN" | sed -e 's%\-i[3456]86.*%%' -e 's%\-noarch.*%%'`"
   DB_version="`echo -n "$PKGNAME" | grep -o '\-[0-9].*' | sed -e 's%^\-%%'`"
   xDB_version="`echo -n "$DB_version" | sed -e 's%\\-%\\\\-%g' -e 's%\\.%\\\\.%g'`"
   xPATTERN="s%${xDB_version}%%"
   DB_nameonly="`echo -n "$PKGNAME" | sed -e "$xPATTERN" -e 's%\-$%%'`"
   DB_pkgrelease="`echo -n "$PKGMAIN" | sed -e 's%.*\-i[3456]86%%' -e 's%.*\-noarch%%' -e 's%.*\-x86_64%%' -e 's%.*\-amd64%%' -e 's%^\-%%'`"
  ;;
  *.ipk)
   DB_nameonly="`echo -n "$PKGMAIN" | cut -f 1 -d '_'`"
   DB_pkgrelease="`echo -n "$PKGMAIN" | rev | cut -f 2 -d '_' | cut -f 1 -d '-' | rev`"
   prPATTERN="s%\-${DB_pkgrelease}.*%%"
   PKGNAME="`echo -n "$PKGMAIN" | sed -e "$prPATTERN"`"
   DB_version="`echo "$PKGNAME" | cut -f 2 -d '_'`"
  ;;
  *.xbps)
   DB_nameonly="`echo -n "$PKGMAIN" | cut -f 1 -d '_' | rev | cut -f 2 -d '-' | rev`"
   DB_pkgrelease="`echo -n "$PKGMAIN" | cut -f 2 -d '_' | cut -f 1 -d '.'`"
   PKGNAME="`echo -n "$PKGMAIN" | sed -e 's%.*\-i[3456]86%%' -e 's%.*\-noarch%%' -e 's%.*\-x86_64%%' -e 's%.*\-amd64%%'`"
   DB_version="`echo -n "$PKGMAIN" | cut -f 1 -d '_' | rev | cut -f 1 -d '-' | rev`"
  ;;
  *.eopkg)
   PKGNAME="$PKGMAIN"
   DB_version="`echo -n "$PKGNAME" | grep -o '\-[0-9].*' | sed -e 's%^\-%%' | cut -f 1 -d '-'`"
   xDB_version="`echo -n "$PKGNAME" | grep -o '\-[0-9].*'`"
   xPATTERN="s%${xDB_version}%%"
   DB_nameonly="`echo -n "$PKGNAME" | sed -e "$xPATTERN" -e 's%\-$%%'`"
   DB_pkgrelease="`echo -n "$PKGNAME" | grep -o '\-[0-9].*' | sed -e 's%^\-%%' | cut -f 2 -d '-'`"
  ;;
  *.cards.tar.xz|*.cards.tar.gz)
   PKGNAME="$PKGMAIN"
   DB_version=""
   xDB_version=""
   xPATTERN=""
   DB_nameonly="$PKGMAIN"
   DB_pkgrelease=""
  ;;
  *.pisi)
   PKGNAME="$PKGMAIN"
   DB_version="`echo -n "$PKGNAME" | grep -o '\-[0-9].*' | sed -e 's%^\-%%' | cut -f 1 -d '-'`"
   xDB_version="`echo "$PKGNAME" | grep -o '\-[0-9].*'`"
   xPATTERN="s%${xDB_version}%%"
   DB_nameonly="`echo -n "$PKGNAME" | sed -e "$xPATTERN" -e 's%\-$%%'`"
   DB_pkgrelease="`echo -n "$PKGNAME" | grep -o '\-[0-9].*' | sed -e 's%^\-%%' | cut -f 2-d '-'`"
  ;;
  *.dsl|*.slp)
   PKGNAME="$PKGMAIN"
   DB_version="`echo -n "$PKGNAME" | grep -o '\-[0-9].*' | sed -e 's%^\-%%'`"
   xDB_version="`echo -n "$PKGNAME" | grep -o '\-[0-9].*'`"
   xPATTERN="s%${xDB_version}%%"
   DB_nameonly="`echo -n "$PKGNAME" | sed -e "$xPATTERN" -e 's%\-$%%'`"
   DB_pkgrelease=""
  ;;
  *.pfs)
   PKGNAME="$PKGMAIN"
   DB_version="`echo -n "$PKGNAME" | grep -o '\-[0-9].*' | sed -e 's%^\-%%'`"
   xDB_version="`echo -n "$DB_version" | sed -e 's%\\-%\\\\-%g' -e 's%\\.%\\\\.%g'`"
   xPATTERN="s%${xDB_version}%%"
   DB_nameonly="`echo -n "$PKGNAME" | sed -e "$xPATTERN" -e 's%\-$%%'`"
   DB_pkgrelease=""
  ;;
esac

#131222 do not allow duplicate installs...
PTN1='^'"$DLPKG_NAME"'|'
if [ "`grep "$PTN1" /root/.packages/user-installed-packages`" != "" ];then
 if [ ! $DISPLAY ];then
  [ -f /tmp/petget-proc/install_quietly ] && DISPTIME1="--timeout 3" || DISPTIME1=''
  LANG=$LANG_USER
  dialog ${DISPTIME1} --msgbox "$(gettext 'This package is already installed. Cannot install it twice:') ${DLPKG_NAME}" 0 0
 else
  LANG=$LANG_USER
  if [ "$(</var/local/petget/ui_choice)" = "Classic" -o -f /tmp/petget-proc/install_classic ]; then
   /usr/lib/gtkdialog/box_ok "$(gettext 'Puppy package manager')" error "$(gettext 'This package is already installed. Cannot install it twice:')" "<i>${DLPKG_NAME}</i>"
   [ -f /tmp/petget-proc/install_classic ] && echo ${DLPKG_NAME} >> /tmp/petget-proc/pgks_failed_to_install_forced
  else
   /usr/lib/gtkdialog/box_ok "$(gettext 'Puppy package manager')" error "$(gettext 'This package is already installed. Cannot install it twice:')" "<i>${DLPKG_NAME}</i>" & 
   XPID=$!
   sleep 3
   pkill -P $XPID
   echo ${DLPKG_NAME} >> /tmp/petget-proc/pgks_failed_to_install_forced
  fi
 fi
 exit 1
fi

#boot from flash: bypass tmpfs top layer, install direct to pup_save file...
DIRECTSAVEPATH=""
 
if [ "$PUPMODE" = "2" ]; then # from BK's quirky6.1

#131220  131229 detect if not enough room in /tmp...
DIRECTSAVEPATH="/tmp/petget-proc/petget/directsavepath"
SIZEB=`stat --format=%s "${DLPKG_PATH}"/${DLPKG_BASE}`
SIZEK=`expr $SIZEB \/ 1024`
EXPK=`expr $SIZEK \* 5` #estimated worst-case expanded size.
NEEDK=$EXPK
TMPK=`df -k /tmp | grep '^tmpfs' | tr -s ' ' | cut -f 4 -d ' '` #free space in /tmp
if [ $EXPK -ge $TMPK ];then
  DIRECTSAVEPATH="/audit/directsavepath"
  NEEDK=`expr $NEEDK \* 2`
fi
if [ "$DIRECTSAVEPATH" ];then
 rm -rf $DIRECTSAVEPATH
 mkdir -p $DIRECTSAVEPATH
fi

# check enough space to install pkg...
#as the pkg gets expanded to an intermediate dir, maybe in main f.s...
PARTK=`df -k / | grep '/$' | tr -s ' ' | cut -f 4 -d ' '` #free space in partition.
if [ $NEEDK -gt $PARTK ];then
 LANG=$LANG_USER
 if [ $DISPLAY ];then
  /usr/lib/gtkdialog/box_ok "$(gettext 'Puppy package manager')" error "$(gettext 'Not enough free space in the partition to install this package'):" "<i>${DLPKG_BASE}</i>"
 else
  echo -e "$(gettext 'Not enough free space in the partition to install this package'):\n${DLPKG_BASE}"
 fi
 [ "$DLPKG_PATH" != "" ] && rm -f "${DLPKG_PATH}"/${DLPKG_BASE}
 exit 1
fi

#111013 shinobar: this currently not working, bypass for now... 111013 revert...
#elif [ "ABC" = "DEF" ];then #111013
elif [ $PUPMODE -eq 3 -o $PUPMODE -eq 7 -o $PUPMODE -eq 13 ];then
  # SFR: let user chose...
  [ -f /var/local/petget/install_mode ] && IMODE="`cat /var/local/petget/install_mode`" || IMODE="savefile"
  if [ "$IMODE" != "tmpfs" ]; then
    FLAGNODIRECT=1
    #100426 aufs can now write direct to save layer...
    #note: fsnotify now preferred not inotify, udba=notify uses whichever is enabled in module...
    busybox mount -t aufs -o remount,udba=notify unionfs / #remount aufs with best evaluation mode.
    FLAGNODIRECT=$?
    [ $FLAGNODIRECT -ne 0 ] && logger -s -t "installpkg.sh" "Failed to remount aufs / with udba=notify"
    if [ $FLAGNODIRECT -eq 0 ];then
     #note that /sbin/pup_event_frontend_d will not run snapmergepuppy if installpkg.sh or downloadpkgs.sh are running.
     while [ "`pidof snapmergepuppy`" != "" ];do
      sleep 1
     done
     DIRECTSAVEPATH="/initrd${SAVE_LAYER}" #SAVE_LAYER is in /etc/rc.d/PUPSTATE.
     rm -f $DIRECTSAVEPATH/pet.specs $DIRECTSAVEPATH/pinstall.sh $DIRECTSAVEPATH/puninstall.sh $DIRECTSAVEPATH/install/doinst.sh
    fi
  fi
fi

if [ $DISPLAY -a ! -f /tmp/petget-proc/install_quietly ];then #131222
 LANG=$LANG_USER
 . /usr/lib/gtkdialog/box_splash -close never -fontsize large -text "$(gettext 'Please wait, processing...')" &
 YAFPID1=$!
 trap 'pupkill $YAFPID1' EXIT #140318
fi

cd "$DLPKG_PATH"

#Extract Packages

case $DLPKG_BASE in
 *.pet)
  # determine compression
  file -b "$DLPKG_BASE" | grep -i -q "^xz" && EXT=xz || EXT=gz #131122 #140109 add -i, eg: "XZ"
  case $EXT in
  xz)OPT=-J ;;
  gz)OPT=-z ;;
  esac
  DLPKG_MAIN="`basename $DLPKG_BASE .pet`"
  cp -f $DLPKG_BASE base-$DLPKG_BASE
  pet2tgz $DLPKG_BASE
  retval=$?
  mv -f base-$DLPKG_BASE $DLPKG_BASE
  [ $retval -ne 0 ] && exit 1
  
  PETFILES="`tar --list ${OPT} -f ${DLPKG_MAIN}.tar.${EXT}`"
  #slackware pkg, got a case where passed the above test but failed here...
  [ $? -ne 0 ] && exit 1
  #check for renamed pets. Will produce an empty ${DLPKG_NAME}.files file
  PETFOLDER=$(echo "${PETFILES}" | cut -f 2 -d '/' | head -n 1)
  [ "$PETFOLDER" = "" ] && PETFOLDER=$(echo "${PETFILES}" | cut -f 1 -d '/' | head -n 1)
  if [ "${DLPKG_MAIN}" != "${PETFOLDER}" ]; then
   pupkill $YAFPID1
   LANG=$LANG_USER
   if [ "$DISPLAY" ]; then
    . /usr/lib/gtkdialog/box_ok "$(gettext 'Puppy Package Manager')" error "<b>${DLPKG_MAIN}.pet</b> $(gettext 'is named') <b>${PETFOLDER}</b> $(gettext 'inside the pet file. Will not install it!')"
   else
    . dialog --msgbox "$DLPKG_MAIN.pet $(gettext 'is named') $PETFOLDER $(gettext 'inside the pet file. Will not install it!')" 0 0
   fi
   exit 1
  fi
  if [ "`echo "$PETFILES" | grep '^\\./'`" != "" ];then
   #ttuuxx has created some pets with './' prefix...
   pPATTERN="s%^\\./${DLPKG_NAME}%%"
   echo "$PETFILES" | sed -e "$pPATTERN" > /root/.packages/package-files/${DLPKG_NAME}.files
   
   install_path_check
   
   tar ${OPT} -x -h --strip=2 --directory=${DIRECTSAVEPATH}/ -f ${DLPKG_MAIN}.tar.${EXT} #120102. 120107 remove --unlink-first
   
  else
   #new2dir and tgz2pet creates them this way...
   pPATTERN="s%^${DLPKG_NAME}%%"
   echo "$PETFILES" | sed -e "$pPATTERN" > /root/.packages/package-files/${DLPKG_NAME}.files
   
   install_path_check
   
   tar ${OPT} -x -h --strip=1 --directory=${DIRECTSAVEPATH}/ -f ${DLPKG_MAIN}.tar.${EXT} #120102. 120107. 131122
   
  fi
  [ $? -ne 0 ] && clean_and_die
 ;;
 *.deb)
  DLPKG_MAIN="`basename $DLPKG_BASE .deb`"
  PFILES="`dpkg-deb --contents $DLPKG_BASE | tr -s ' ' | cut -f 6 -d ' '`"
  [ $? -ne 0 ] && exit 1
  echo "$PFILES" > /root/.packages/package-files/${DLPKG_NAME}.files
  install_path_check
  dpkg-deb -x $DLPKG_BASE ${DIRECTSAVEPATH}/
  [ $? -ne 0 ] && clean_and_die
  [ -d /DEBIAN ] && rm -rf /DEBIAN #130112 precaution.
  dpkg-deb -e $DLPKG_BASE /DEBIAN #130112 extracts deb control files to dir /DEBIAN. may have a post-install script, see below.
  write_deb_spec
 ;;
 *.tgz)
  DLPKG_MAIN="`basename $DLPKG_BASE .tgz`" #ex: scite-1.77-i686-2as
  gzip --test $DLPKG_BASE > /dev/null 2>&1
  [ $? -ne 0 ] && exit 1
  PFILES="`tar --list -z -f $DLPKG_BASE`"
  #hmmm, got a case where passed the above test but failed here...
  [ $? -ne 0 ] && exit 1
  echo "$PFILES" > /root/.packages/package-files/${DLPKG_NAME}.files
   
   install_path_check

   tar -z -x -h --directory=${DIRECTSAVEPATH}/ -f $DLPKG_BASE #120102. 120107
   
  [ $? -ne 0 ] && clean_and_die
  
  write_slack_spec
  
 ;;
 *.txz) #100616
  DLPKG_MAIN="`basename $DLPKG_BASE .txz`" #ex: scite-1.77-i686-2as
  xz --test $DLPKG_BASE > /dev/null 2>&1
  [ $? -ne 0 ] && exit 1
  PFILES="`tar --list -J -f $DLPKG_BASE`"
  #hmmm, got a case where passed the above test but failed here...
  [ $? -ne 0 ] && exit 1
  echo "$PFILES" > /root/.packages/package-files/${DLPKG_NAME}.files
  install_path_check
  
  tar -J -x -h --directory=${DIRECTSAVEPATH}/ -f $DLPKG_BASE #120102. 120107
  
  [ $? -ne 0 ] && clean_and_die
  
  write_slack_spec
  
 ;;
 *.tar.gz)
  DLPKG_MAIN="`basename $DLPKG_BASE .tar.gz`" #ex: acl-2.2.47-1-i686.pkg
  gzip --test $DLPKG_BASE > /dev/null 2>&1
  [ $? -ne 0 ] && exit 1
  PFILES="`tar --list -z -f $DLPKG_BASE`"
  [ $? -ne 0 ] && exit 1
  echo "$PFILES" > /root/.packages/package-files/${DLPKG_NAME}.files
  install_path_check
  
  tar -z -x -h --directory=${DIRECTSAVEPATH}/ -f $DLPKG_BASE #120102. 120107
 
  [ $? -ne 0 ] && clean_and_die
 ;;
 *.tar.bz2) #100110
  DLPKG_MAIN="`basename $DLPKG_BASE .tar.bz2`"
  bzip2 --test $DLPKG_BASE > /dev/null 2>&1
  [ $? -ne 0 ] && exit 1
  PFILES="`tar --list -j -f $DLPKG_BASE`"
  [ $? -ne 0 ] && exit 1
  echo "$PFILES" > /root/.packages/package-files/${DLPKG_NAME}.files
  install_path_check
  
  tar -j -x -h --directory=${DIRECTSAVEPATH}/ -f $DLPKG_BASE #120102. 120107
  
  [ $? -ne 0 ] && clean_and_die
 ;;
 *.pkg.tar.xz) #130314 arch pkgs.
  DLPKG_MAIN="`basename $DLPKG_BASE .pkg.tar.xz`" #ex: acl-2.2.51-3-i686
  xz --test $DLPKG_BASE > /dev/null 2>&1
  [ $? -ne 0 ] && exit 1
  PFILES="`tar --list -J -f $DLPKG_BASE`"
  #hmmm, got a case where passed the above test but failed here...
  [ $? -ne 0 ] && exit 1
  echo "$PFILES" > /root/.packages/package-files/${DLPKG_NAME}.files
  install_path_check
  
  tar -J -x -h --directory=${DIRECTSAVEPATH}/ -f $DLPKG_BASE
  
  if [ $? -ne 0 ]; then
  clean_and_die
  fi
  
  if [ -f /.BUILDINFO ]; then
  rm -f /.BUILDINFO
  fi
  
  if [ -f /.MTREE ]; then
  rm -f /.MTREE
  fi
  
  write_arch_spec
  
  if [ -f /.PKGINFO ]; then
  rm -f /.PKGINFO
  fi
  
 ;;
  *.pkg.tar.gz)
  DLPKG_MAIN="`basename $DLPKG_BASE pkg.tar.gz`" #ex: acl-2.2.47-1-i686.pkg
  gzip --test $DLPKG_BASE > /dev/null 2>&1
  [ $? -ne 0 ] && exit 1
  PFILES="`tar --list -z -f $DLPKG_BASE`"
  [ $? -ne 0 ] && exit 1
  echo "$PFILES" > /root/.packages/package-files/${DLPKG_NAME}.files
  install_path_check
  
  tar -z -x -h --directory=${DIRECTSAVEPATH}/ -f $DLPKG_BASE #120102. 120107
 
  if [ $? -ne 0 ]; then
  clean_and_die
  fi
  
  if [ -f /.BUILDINFO ]; then
  rm -f /.BUILDINFO
  fi
  
  if [ -f /.MTREE ]; then
  rm -f /.MTREE
  fi
  
  write_arch_spec
  
  if [ -f /.PKGINFO ]; then
  rm -f /.PKGINFO
  fi
  
  ;;
  
 *.rpm) #110523
  DLPKG_MAIN="`basename $DLPKG_BASE .rpm`"
  busybox rpm -qp $DLPKG_BASE > /dev/null 2>&1
  [ $? -ne 0 ] && exit 1
  PFILES="`busybox rpm -qpl $DLPKG_BASE`"
  [ $? -ne 0 ] && exit 1
  echo "$PFILES" > /root/.packages/package-files/${DLPKG_NAME}.files
  install_path_check
  #110705 rpm -i does not work for mageia pkgs...
  exploderpm -i $DLPKG_BASE
  [ $? -ne 0 ] && clean_and_die
  busybox rpm -qpi $DLPKG_BASE > /rpm-info
  write_rpm_spec
 ;;
 
 *.pisi)
 DLPKG_MAIN="`basename $DLPKG_BASE .pisi`"
 /usr/local/petget/install_func pisi $DLPKG_PATH/$DLPKG_BASE ${DIRECTSAVEPATH}/
 [ $? -ne 0 ] && clean_and_die
 ;;
 
  *.tazpkg)
 DLPKG_MAIN="`basename $DLPKG_BASE .tazpkg`"
 /usr/local/petget/install_func taz $DLPKG_PATH/$DLPKG_BASE ${DIRECTSAVEPATH}/
 [ $? -ne 0 ] && clean_and_die
 ;;
 
  *.sb)
 DLPKG_MAIN="`basename $DLPKG_BASE .sb`"
 /usr/local/petget/install_func sb $DLPKG_PATH/$DLPKG_BASE ${DIRECTSAVEPATH}/
 [ $? -ne 0 ] && clean_and_die
 ;;

  *.lzm)
 DLPKG_MAIN="`basename $DLPKG_BASE .lzm`"
 /usr/local/petget/install_func lzm $DLPKG_PATH/$DLPKG_BASE ${DIRECTSAVEPATH}/
 [ $? -ne 0 ] && clean_and_die
 ;;
 
  *.xzm)
 DLPKG_MAIN="`basename $DLPKG_BASE .xzm`"
 /usr/local/petget/install_func xzm $DLPKG_PATH/$DLPKG_BASE ${DIRECTSAVEPATH}/
 [ $? -ne 0 ] && clean_and_die
 ;;
 
   *.pfs)
 DLPKG_MAIN="`basename $DLPKG_BASE .pfs`"
 /usr/local/petget/install_func pfs $DLPKG_PATH/$DLPKG_BASE ${DIRECTSAVEPATH}/
 [ $? -ne 0 ] && clean_and_die
 ;;

   *.apk)
 DLPKG_MAIN="`basename $DLPKG_BASE .apk`"
 /usr/local/petget/install_func apk $DLPKG_PATH/$DLPKG_BASE ${DIRECTSAVEPATH}/
 [ $? -ne 0 ] && clean_and_die
 ;;

   *.spack)
 DLPKG_MAIN="`basename $DLPKG_BASE .spack`"
 /usr/local/petget/install_func spack $DLPKG_PATH/$DLPKG_BASE ${DIRECTSAVEPATH}/
 [ $? -ne 0 ] && clean_and_die
 ;;
 
   *.ipk)
 DLPKG_MAIN="`basename $DLPKG_BASE .ipk`"
 /usr/local/petget/install_func ipk $DLPKG_PATH/$DLPKG_BASE ${DIRECTSAVEPATH}/
 [ $? -ne 0 ] && clean_and_die
 ;;
 
   *.xbps)
 DLPKG_MAIN="`basename $DLPKG_BASE .xbps`"
 /usr/local/petget/install_func xbps $DLPKG_PATH/$DLPKG_BASE ${DIRECTSAVEPATH}/
 [ $? -ne 0 ] && clean_and_die
 ;;
 
   *.eopkg)
 DLPKG_MAIN="`basename $DLPKG_BASE .eopkg`"
 /usr/local/petget/install_func eopkg $DLPKG_PATH/$DLPKG_BASE ${DIRECTSAVEPATH}/
 [ $? -ne 0 ] && clean_and_die
 ;;
 
   *.cards.tar.xz)
 DLPKG_MAIN="`basename $DLPKG_BASE .cards.tar.xz`"
 /usr/local/petget/install_func cards $DLPKG_PATH/$DLPKG_BASE ${DIRECTSAVEPATH}/
 [ $? -ne 0 ] && clean_and_die
 ;;
 
   *.tcz)
 DLPKG_MAIN="`basename $DLPKG_BASE .tcz`"
 /usr/local/petget/install_func tcz $DLPKG_PATH/$DLPKG_BASE ${DIRECTSAVEPATH}/
 [ $? -ne 0 ] && clean_and_die
 ;;

   *.tce|*.tcel|*.tcem)
  
	case "$TCE" in
	 *.tcel) ext1=".tcel";;
	 *.tcem) ext1=".tcem";;
	 *)      ext1=".tce";;
	esac
  
 DLPKG_MAIN="`basename $DLPKG_BASE $ext1`"
 /usr/local/petget/install_func tce $DLPKG_PATH/$DLPKG_BASE ${DIRECTSAVEPATH}/
 [ $? -ne 0 ] && clean_and_die
 ;;

   *.dsl)
 DLPKG_MAIN="`basename $DLPKG_BASE .dsl`"
 /usr/local/petget/install_func dsl $DLPKG_PATH/$DLPKG_BASE ${DIRECTSAVEPATH}/
 [ $? -ne 0 ] && clean_and_die
 ;;

   *.slp)
 DLPKG_MAIN="`basename $DLPKG_BASE .slp`"
 /usr/local/petget/install_func slp $DLPKG_PATH/$DLPKG_BASE ${DIRECTSAVEPATH}/
 [ $? -ne 0 ] && clean_and_die
 ;;
 
esac


if [ "$PUPMODE" = "2" ]; then #from BK's quirky6.1
 mkdir /audit/${DLPKG_NAME}-DEPOSED
 echo -n '' > /tmp/petget-proc/petget/FLAGFND
 find ${DIRECTSAVEPATH}/ -mindepth 1 | sed -e "s%${DIRECTSAVEPATH}%%" |
 while read AFILESPEC
 do
  if [ -f "$AFILESPEC" ];then
   ADIR="$(dirname "$AFILESPEC")"
   mkdir -p /audit/${DLPKG_NAME}-DEPOSED/${ADIR}
   cp -a -f "$AFILESPEC" /audit/${DLPKG_NAME}-DEPOSED/${ADIR}/
   echo -n '1' > /tmp/petget-proc/petget/FLAGFND
  fi
 done
 sync
 if [ -s /tmp/petget-proc/petget/FLAGFND ];then
  [ -f /audit/${DLPKG_NAME}-DEPOSED.sfs ] && rm -f /audit/${DLPKG_NAME}-DEPOSED.sfs #precaution, should not happen, as not allowing duplicate installs of same pkg.
  mksquashfs /audit/${DLPKG_NAME}-DEPOSED /audit/${DLPKG_NAME}-DEPOSED.sfs
 fi
 sync
 rm -rf /audit/${DLPKG_NAME}-DEPOSED
 #now write temp-location to final destination...
 cp -a -f --remove-destination ${DIRECTSAVEPATH}/* /  2> /tmp/petget-proc/petget/install-cp-errlog
 sync
 #can have a problem if want to replace a folder with a symlink. for example, got this error:
 # cp: cannot overwrite directory '/usr/share/mplayer/skins' with non-directory
 #3builddistro has this fix... which is a vice-versa situation...
 #firstly, the vice-versa, source is a directory, target is a symlink...
 CNT=0
 while [ -s /tmp/petget-proc/petget/install-cp-errlog ];do
  echo -n '' > /tmp/petget-proc/petget/install-cp-errlog2
  echo -n '' > /tmp/petget-proc/petget/install-cp-errlog3
  cat /tmp/petget-proc/petget/install-cp-errlog | grep 'cannot overwrite non-directory' | grep 'with directory' | tr '[`‘’]' "'" | cut -f 2 -d "'" |
  while read ONEDIRSYMLINK #ex: /usr/share/mplayer/skins
  do
   if [ -h "${ONEDIRSYMLINK}" ];then #source is a directory, target is a symlink...
    #adding that extra trailing / does the trick...
    cp -a -f --remove-destination ${DIRECTSAVEPATH}"${ONEDIRSYMLINK}"/* "${ONEDIRSYMLINK}"/ 2>> /tmp/petget-proc/petget/install-cp-errlog2
   else #source is a directory, target is a file...
    rm -f "${ONEDIRSYMLINK}" #delete the file!
    DIRPATH="$(dirname "${ONEDIRSYMLINK}")"
    cp -a -f ${DIRECTSAVEPATH}"${ONEDIRSYMLINK}" "${DIRPATH}"/ 2>> /tmp/petget-proc/petget/install-cp-errlog2 #copy directory (and contents).
   fi
  done
  #secondly, which is our mplayer example, source is a symlink, target is a folder...
  cat /tmp/petget-proc/petget/install-cp-errlog | grep 'cannot overwrite directory' | grep 'with non-directory' | tr '[`‘’]' "'" | cut -f 2 -d "'" |
  while read ONEDIRSYMLINK #ex: /usr/share/mplayer/skins
  do
   #difficult situation, whether to impose the symlink of package, or not. if not...
   #cp -a -f --remove-destination ${DIRECTSAVEPATH}"${ONEDIRSYMLINK}"/* "${ONEDIRSYMLINK}"/ 2> /tmp/petget-proc/petget/install-cp-errlog3
   #or, if we have chosen to follow link...
   DIRPATH="$(dirname "${ONEDIRSYMLINK}")"
   if [ -h ${DIRECTSAVEPATH}"${ONEDIRSYMLINK}" ];then #source is a symlink, trying to overwrite a directory...
    ALINK="$(readlink ${DIRECTSAVEPATH}"${ONEDIRSYMLINK}")"
    if [ "${ALINK:0:1}" = "/" ];then #test 1st char
     xALINK="$ALINK" #absolute
    else
     xALINK="${DIRPATH}/${ALINK}"
    fi
    if [ -d "$xALINK" ];then
     cp -a -f --remove-destination "${ONEDIRSYMLINK}"/* "$xALINK"/ 2>> /tmp/petget-proc/petget/install-cp-errlog3 #relocates target files.
     rm -rf "${ONEDIRSYMLINK}"
     cp -a -f ${DIRECTSAVEPATH}"${ONEDIRSYMLINK}" "${DIRPATH}"/ #creates symlink only.
    fi
   else #source is a file, trying to overwrite a directory...
    rm -rf "${ONEDIRSYMLINK}" #deleting directory!!!
    cp -a -f ${DIRECTSAVEPATH}"${ONEDIRSYMLINK}" "${DIRPATH}"/ #creates file only.
   fi
  done
  cat /tmp/petget-proc/petget/install-cp-errlog2 >> /tmp/petget-proc/petget/install-cp-errlog3
  cat /tmp/petget-proc/petget/install-cp-errlog3 > /tmp/petget-proc/petget/install-cp-errlog
  sync
  CNT=`expr $CNT + 1`
  [ $CNT -gt 10 ] && break #something wrong, get out.
 done

 #end 131220
 rm -rf ${DIRECTSAVEPATH} #131229 131230

[ "$DL_SAVE_FLAG" != "true" ] && rm -f $DLPKG_BASE 2>/dev/null
rm -f $DLPKG_MAIN.tar.gz 2>/dev/null

#pkgname.files may need to be fixed...
FIXEDFILES="`cat /root/.packages/package-files/${DLPKG_NAME}.files | grep -v '^\\./$'| grep -v '^/$' | sed -e 's%^\\.%%' -e 's%^%/%' -e 's%^//%/%'`"
echo "$FIXEDFILES" > /root/.packages/package-files/${DLPKG_NAME}.files 

else


[ "$DL_SAVE_FLAG" != "true" ] &&  rm -f $DLPKG_BASE 2>/dev/null
rm -f $DLPKG_MAIN.tar.${EXT} 2>/dev/null #131122

#pkgname.files may need to be fixed...
FIXEDFILES="`cat /root/.packages/package-files/${DLPKG_NAME}.files | grep -v '^\\./$'| grep -v '^/$' | sed -e 's%^\\.%%' -e 's%^%/%' -e 's%^//%/%'`"
echo "$FIXEDFILES" > /root/.packages/package-files/${DLPKG_NAME}.files

#120102 install may have overwritten a symlink-to-dir...
#tar defaults to not following symlinks, for both dirs and files, but i want to follow symlinks
#for dirs but not for files. so, fix here... (note, dir entries in .files have / on end)
cat /root/.packages/package-files/${DLPKG_NAME}.files | grep '[a-zA-Z0-9]/$' | sed -e 's%/$%%' | grep -v '^/mnt' |
while read ONESPEC
do
 if [ -d "${DIRECTSAVEPATH}${ONESPEC}" ];then
  if [ ! -h "${DIRECTSAVEPATH}${ONESPEC}" ];then
   DIRLINK=""
   if [ -h "/initrd${PUP_LAYER}${ONESPEC}" ];then #120107
    DIRLINK="`readlink -m "/initrd${PUP_LAYER}${ONESPEC}" | sed -e "s%/initrd${PUP_LAYER}%%"`" #PUP_LAYER: see /etc/rc.d/PUPSTATE. 120107
    xDIRLINK="`readlink "/initrd${PUP_LAYER}${ONESPEC}"`" #120107
   fi
   if [ ! "$DIRLINK" ];then
    if [ -h "/initrd${SAVE_LAYER}${ONESPEC}" ];then #120107
     DIRLINK="`readlink -m "/initrd${SAVE_LAYER}${ONESPEC}" | sed -e "s%/initrd${SAVE_LAYER}%%"`" #SAVE_LAYER: see /etc/rc.d/PUPSTATE. 120107
     xDIRLINK="`readlink "/initrd${SAVE_LAYER}${ONESPEC}"`" #120107
    fi
   fi
   if [ "$DIRLINK" ];then
    if [ -d "$DIRLINK"  ];then
     if [ "$DIRLINK" != "${ONESPEC}" ];then #precaution.
      mkdir -p "${DIRECTSAVEPATH}${DIRLINK}" #120107
      cp -a -f --remove-destination ${DIRECTSAVEPATH}"${ONESPEC}"/* "${DIRECTSAVEPATH}${DIRLINK}/" #ha! fails if put double-quotes around entire expression.
      rm -rf "${DIRECTSAVEPATH}${ONESPEC}"
      if [ "$DIRECTSAVEPATH" = "" ];then
       ln -s "$xDIRLINK" "${ONESPEC}"
      else
       DSOPATH="`dirname "${DIRECTSAVEPATH}${ONESPEC}"`"
       DSOBASE="`basename "${DIRECTSAVEPATH}${ONESPEC}"`"
       rm -f "${DSOPATH}/.wh.${DSOBASE}" #allow underlying symlink to become visible on top.
      fi
     fi
    fi
   fi
  fi
 fi
done

#121217 it seems that this problem is occurring in other modes (13 reported)...
#121123 having a problem with multiarch symlinks in full-installation...
#it seems that the symlink is getting replaced by a directory.
if [ "$DISTRO_ARCHDIR" ];then #in /etc/rc.d/DISTRO_SPECS. 130112 change test from DISTRO_ARCHDIR. 130114 revert DISTRO_ARCHDIR_SYMLINKS==yes.
  if [ -d /usr/lib/${DISTRO_ARCHDIR} ];then
   if [ ! -h /usr/lib/${DISTRO_ARCHDIR} ];then
    cp -a -f --remove-destination /usr/lib/${DISTRO_ARCHDIR}/* /usr/lib/
    sync
    rm -r -f /usr/lib/${DISTRO_ARCHDIR}
    ln -s ./ /usr/lib/${DISTRO_ARCHDIR}
   fi
  fi
  if [ -d /lib/${DISTRO_ARCHDIR} ];then
   if [ ! -h /lib/${DISTRO_ARCHDIR} ];then
    cp -a -f --remove-destination /lib/${DISTRO_ARCHDIR}/* /lib/
    sync
    rm -r -f /lib/${DISTRO_ARCHDIR}
    ln -s ./ /lib/${DISTRO_ARCHDIR}
   fi
  fi
  if [ -d /usr/bin/${DISTRO_ARCHDIR} ];then
   if [ ! -h /usr/bin/${DISTRO_ARCHDIR} ];then
    cp -a -f --remove-destination /usr/bin/${DISTRO_ARCHDIR}/* /usr/bin/
    sync
    rm -r -f /usr/bin/${DISTRO_ARCHDIR}
    ln -s ./ /usr/bin/${DISTRO_ARCHDIR}
   fi
  fi
fi

#flush unionfs cache, so files in pup_save layer will appear "on top"...
if [ "$DIRECTSAVEPATH" != "" ];then
 #but first, clean out any bad whiteout files...
 # 22sep10 shinobar: bugfix was not working clean out whiteout files
 find /initrd/pup_rw -mount -type f -name .wh.\*  -printf '/%P\n'|
 while read ONEWHITEOUT
 do
  ONEWHITEOUTFILE="`basename "$ONEWHITEOUT"`"
  ONEWHITEOUTPATH="`dirname "$ONEWHITEOUT"`"
  if [ "$ONEWHITEOUTFILE" = ".wh.__dir_opaque" ];then
   [ "`grep "$ONEWHITEOUTPATH" /root/.packages/package-files/${DLPKG_NAME}.files`" != "" ] && rm -f "/initrd/pup_rw/$ONEWHITEOUT"
   continue
  fi
  ONEPATTERN="`echo -n "$ONEWHITEOUT" | sed -e 's%/\\.wh\\.%/%'`"'/*'	;#echo "$ONEPATTERN" >&2
  [ "`grep -x "$ONEPATTERN" /root/.packages/package-files/${DLPKG_NAME}.files`" != "" ] && rm -f "/initrd/pup_rw/$ONEWHITEOUT"
 done
 #111229 /usr/local/petget/removepreview.sh when uninstalling a pkg, may have copied a file from sfs-layer to top, check...
 cat /root/.packages/package-files/${DLPKG_NAME}.files |
 while read ONESPEC
 do
  [ "$ONESPEC" = "" ] && continue #precaution.
  if [ ! -d "$ONESPEC" ];then
   [ -e "/initrd/pup_rw${ONESPEC}" ] && rm -f "/initrd/pup_rw${ONESPEC}"
  fi
 done
 #now re-evaluate all the layers...
 busybox mount -t aufs -o remount,udba=reval unionfs / #remount with faster evaluation mode.
 [ $? -ne 0 ] && logger -s -t "installpkg.sh" "Failed to remount aufs / with udba=reval"

 sync
fi

fi

#some .pet pkgs have images at '/'...
mv /*24.xpm /usr/local/lib/X11/pixmaps/ 2>/dev/null
mv /*32.xpm /usr/local/lib/X11/pixmaps/ 2>/dev/null
mv /*32.png /usr/local/lib/X11/pixmaps/ 2>/dev/null
mv /*48.xpm /usr/local/lib/X11/pixmaps/ 2>/dev/null
mv /*48.png /usr/local/lib/X11/pixmaps/ 2>/dev/null
mv /*.xpm /usr/local/lib/X11/mini-icons/ 2>/dev/null
mv /*.png /usr/local/lib/X11/mini-icons/ 2>/dev/null

ls -dl /tmp | grep -q '^drwxrwxrwt' || chmod 1777 /tmp #130305 rerwin.

#post-install script?...
if [ -f /pinstall.sh ];then #pet pkgs.
 chmod +x /pinstall.sh
 cd /
  LANG=$LANG_USER nohup sh /pinstall.sh &
  sleep 0.2
 rm -f /pinstall.sh
fi

if [ -f /install/doinst.sh ];then #slackware pkgs.
 chmod +x /install/doinst.sh
 cd /
 LANG=$LANG_USER nohup sh /install/doinst.sh &
 sleep 0.2
 rm -rf /install
else
rm -rf /install
fi

if [ -e /DEBIAN/postinst ];then #130112 deb post-install script.
 cd /
 LANG=$LANG_USER nohup sh DEBIAN/postinst &
 sleep 0.2
 rm -rf /DEBIAN
else
rm -rf /DEBIAN
fi

#130314 run arch linux pkg post-install script...
if [ -f /.INSTALL ];then #arch post-install script.
 if [ -f /usr/local/petget/ArchRunDotInstalls ];then #precaution. see 3builddistro, script created by noryb009.
  #this code is taken from below...
  dlPATTERN='|'"`echo -n "$DLPKG_BASE" | sed -e 's%\\-%\\\\-%'`"'|'
  archVER="`cat /tmp/petget-proc/petget_missing_dbentries-Packages-* | grep "$dlPATTERN" | head -n 1 | cut -f 3 -d '|'`"
  if [ "$archVER" ];then #precaution.
   cd /
   mv -f .INSTALL .INSTALL1-${archVER}
   cp -a /usr/local/petget/ArchRunDotInstalls /ArchRunDotInstalls
   LANG=$LANG_USER /ArchRunDotInstalls
   rm -f ArchRunDotInstalls
   rm -f .INSTALL*
  fi
 fi
fi

#v424 .pet pkgs may have a post-uninstall script...
if [ -f /puninstall.sh ];then
 mv -f /puninstall.sh /root/.packages/remove-script/${DLPKG_NAME}.remove
fi

#w465 <pkgname>.pet.specs is in older pet pkgs, just dump it...
#maybe a '$APKGNAME.pet.specs' file created by dir2pet script...
rm -f /*.pet.specs 2>/dev/null
retval=$?

#...note, this has a setting to prevent .files and entry in user-installed-packages, so install not registered.

if [ ! -f /pet.specs ]; then
    echo "${DLPKG_NAME}|$DB_nameonly|$DB_version|||$PKGSIZEK||${DLPKG_BASE}|||" > /pet.specs
fi

#add entry to /root/.packages/user-installed-packages...
#w465 a pet pkg may have /pet.specs which has a db entry...
if [ -f /pet.specs -a -s /pet.specs ];then #w482 ignore zero-byte file.
 DB_ENTRY="`cat /pet.specs | head -n 1`"
 rm -f /pet.specs
else
 [ -f /pet.specs ] && rm -f /pet.specs #w482 remove zero-byte file.
 dlPATTERN='|'"`echo -n "$DLPKG_BASE" | sed -e 's%\\-%\\\\-%'`"'|'
 DB_ENTRY="`cat /tmp/petget-proc/petget_missing_dbentries-Packages-* | grep "$dlPATTERN" | head -n 1`"
fi
##+++2011-12-27 KRG check if $DLPKG_BASE matches DB_ENTRY 1 so uninstallation works :Ooops:
db_pkg_name=`echo "$DB_ENTRY" |cut -f 1 -d '|'`
if [ "$db_pkg_name" != "$DLPKG_NAME" ];then
 echo "Mismatched: $db_pkg_name | $DLPKG_NAME"
 DB_ENTRY=`echo "$DB_ENTRY" | sed "s#$db_pkg_name#$DLPKG_NAME#"`
fi
##+++2011-12-27 KRG

#see if a .desktop file was installed, fix category... 120628 improve...
#120818 overhauled. Pkg db now has category[;subcategory] (see 0setup), xdg enhanced (see /etc/xdg and /usr/share/desktop-directories), and generic icons for all subcategories (see /usr/local/lib/X11/mini-icons).
#note, similar code also in Woof 2createpackages.
ONEDOT=""
CATEGORY="`echo -n "$DB_ENTRY" | cut -f 5 -d '|'`" #exs: Document, Document;edit
[ "$CATEGORY" = "" ] && CATEGORY='BuildingBlock' #paranoid precaution.
#xCATEGORY and DEFICON will be the fallbacks if Categories entry in .desktop is invalid...
xCATEGORY="`echo -n "$CATEGORY" | sed -e 's%^%X-%' -e 's%;%-%'`" #ex: X-Document-edit (refer /etc/xdg/menu/*.menu)
DEFICON="`echo -n "$CATEGORY" | sed -e 's%^%mini-%' -e 's%;%-%'`"'.xpm' #ex: mini-Document-edit (refer /usr/local/lib/X11/mini-icons -- these are in jwm search path) 121206 need .xpm extention.
case $CATEGORY in
 Calculate)     CATEGORY='Business'             ; xCATEGORY='X-Business'            ; DEFICON='mini-Business.xpm'            ;; #Calculate is old name, now Business.
 Develop)       CATEGORY='Utility;development'  ; xCATEGORY='X-Utility-development' ; DEFICON='mini-Utility-development.xpm' ;; #maybe an old pkg has this.
 Help)          CATEGORY='Utility;help'         ; xCATEGORY='X-Utility-help'        ; DEFICON='mini-Help.xpm'                ;; #maybe an old pkg has this.
 BuildingBlock) CATEGORY='Utility'              ; xCATEGORY='Utility'               ; DEFICON='mini-BuildingBlock.xpm'       ;; #unlikely to have a .desktop file.
esac
topCATEGORY="`echo -n "$CATEGORY" | cut -f 1 -d ';'`"
tPATTERN="^${topCATEGORY} "
cPATTERN="s%^Categories=.*%Categories=${xCATEGORY}%"
iPATTERN="s%^Icon=.*%Icon=${DEFICON}%"

#121119 if only one .desktop file, first check if a match in /usr/local/petget/categories.dat...
CATDONE='no'
if [ -f /usr/local/petget/categories.dat ];then #precaution, but it will be there.
 NUMDESKFILE="$(grep 'share/applications/.*\.desktop$' /root/.packages/package-files/${DLPKG_NAME}.files | wc -l)"
 if [ "$NUMDESKFILE" = "1" ];then
  #to lookup categories.dat, we need to know the generic name of the package, which may be different from pkg name...
  #db entry format: pkgname|nameonly|version|pkgrelease|category|size|path|fullfilename|dependencies|description|compileddistro|compiledrelease|repo|
  DBNAMEONLY="$(echo -n "$DB_ENTRY" | cut -f 2 -d '|')"
  DBPATH="$(echo -n "$DB_ENTRY" | cut -f 7 -d '|')"
  DBCOMPILEDDISTRO="$(echo -n "$DB_ENTRY" | cut -f 11 -d '|')"
  [ ! "$DBCOMPILEDDISTRO" ] && DBCOMPILEDDISTRO='puppy' #any name will do here.
  case $DBCOMPILEDDISTRO in
   debian|devuan|ubuntu|raspbian)
    if [ "$DBPATH" ];then #precaution
     xNAMEONLY="$(basename ${DBPATH})"
    else
     xNAMEONLY="$DBNAMEONLY"
    fi
   ;;
   *) xNAMEONLY="$DBNAMEONLY" ;;
  esac
  xnPTN=" ${xNAMEONLY} "
  #130126 categories.dat format changed slightly... 130219 ignore case...
  CATVARIABLE="$(grep -i "$xnPTN" /usr/local/petget/categories.dat | grep '^PKGCAT' | head -n 1 | cut -f 1 -d '=' | cut -f 2,3 -d '_' | tr '_' '-')" #ex: PKGCAT_Graphic_camera=" gphoto2 gtkam "
  if [ "$CATVARIABLE" ];then #ex: Graphic-camera
   xCATEGORY="X-${CATVARIABLE}"
   cPATTERN="s%^Categories=.*%Categories=${xCATEGORY}%" #121120
   CATFOUND="yes"
   CATDONE='yes'
  fi
 fi
fi

for ONEDOT in `grep 'share/applications/.*\.desktop$' /root/.packages/package-files/${DLPKG_NAME}.files | tr '\n' ' '` #121119 exclude other strange .desktop files.
do
 #120901 get rid of param on end of Exec, ex: Exec=gimp-2.8 %U
 #sed -i -e 's/\(^Exec=[^%]*\).*/\1/' -e 's/ *$//' $ONEDOT #'s/\(^Exec=[^ ]*\).*/\1/'
 #121015 01micko: alternative that may work better...
 for PARMATER in u U f F #refer:  http://standards.freedesktop.org/desktop-entry-spec/latest/ar01s06.html
 do
  sed -i "s/ %${PARMATER}//" $ONEDOT
 done
 
 #w478 find if category is already valid (see also 2createpackages)..
 if [ "$CATDONE" = "no" ];then #121119
  CATFOUND="no"
  for ONEORIGCAT in `cat $ONEDOT | grep '^Categories=' | head -n 1 | cut -f 2 -d '=' | tr ';' ' ' | rev` #search in reverse order.
  do
   ONEORIGCAT="`echo -n "$ONEORIGCAT" | rev`" #restore rev of one word.
   oocPATTERN=' '"$ONEORIGCAT"' '
   [ "`echo "$PUPHIERARCHY" | tr -s ' ' | grep "$tPATTERN" | cut -f 3 -d ' ' | tr ',' ' ' | sed -e 's%^% %' -e 's%$% %' | grep "$oocPATTERN"`" != "" ] && CATFOUND="yes"
   #got a problem with sylpheed, "Categories=GTK;Network;Email;News;" this displays in both Network and Internet menus...
   if [ "$CATFOUND" = "yes" ];then
    cPATTERN="s%^Categories=.*%Categories=${ONEORIGCAT}%"
    break
   fi
  done
  #121109 above may fail, as DB_category field may not match that in .desktop file, so leave out that $tPATTERN match in $PUPHIERARCHY...
  if [ "$CATFOUND" = "no" ];then
   for ONEORIGCAT in `cat $ONEDOT | grep '^Categories=' | head -n 1 | cut -f 2 -d '=' | tr ';' ' ' | rev` #search in reverse order.
   do
    ONEORIGCAT="`echo -n "$ONEORIGCAT" | rev`" #restore rev of one word.
    oocPATTERN=' '"$ONEORIGCAT"' '
    [ "`echo "$PUPHIERARCHY" | tr -s ' ' | cut -f 3 -d ' ' | tr ',' ' ' | sed -e 's%^% %' -e 's%$% %' | grep "$oocPATTERN"`" != "" ] && CATFOUND="yes"
    #got a problem with sylpheed, "Categories=GTK;Network;Email;News;" this displays in both Network and Internet menus...
    if [ "$CATFOUND" = "yes" ];then
     cPATTERN="s%^Categories=.*%Categories=${ONEORIGCAT}%"
     break
    fi
   done
  fi
 fi
 sed -i -e "$cPATTERN" $ONEDOT #fix Categories= entry.

 #w019 does the icon exist?...
 ICON="`grep '^Icon=' $ONEDOT | cut -f 2 -d '='`"
 if [ "$ICON" != "" ];then
  [ -e "$ICON" ] && continue #it may have a hardcoded path.
  ICONBASE="`basename "$ICON"`"
  #110706 fix icon entry in .desktop... 110821 improve...
  #first search where jwm looks for icons... 111207...
  FNDICON="`find /usr/local/lib/X11/mini-icons /usr/share/pixmaps -maxdepth 1 -name $ICONBASE -o -name $ICONBASE.png -o -name $ICONBASE.xpm -o -name $ICONBASE.jpg -o -name $ICONBASE.jpeg -o -name $ICONBASE.gif -o -name $ICONBASE.svg | grep -i -E 'png$|xpm$|jpg$|jpeg$|gif$|svg$' | head -n 1`"
  if [ "$FNDICON" ];then
   ICONNAMEONLY="`basename $FNDICON`"
   iPTN="s%^Icon=.*%Icon=${ICONNAMEONLY}%"
   sed -i -e "$iPTN" $ONEDOT
   continue
  else
   #look elsewhere... 111207...
   FNDICON="`find /usr/share/icons /usr/local/share/pixmaps -name $ICONBASE -o -name $ICONBASE.png -o -name $ICONBASE.xpm -o -name $ICONBASE.jpg -o -name $ICONBASE.jpeg -o -name $ICONBASE.gif -o -name $ICONBASE.svg | grep -i -E 'png$|xpm$|jpg$|jpeg$|gif$|svg$' | head -n 1`"
   #111207 look further afield, ex parole pkg has /usr/share/parole/pixmaps/parole.png...
   [ ! "$FNDICON" ] && [ -d /usr/share/$ICONBASE ] && FNDICON="`find /usr/share/${ICONBASE} -name $ICONBASE -o -name $ICONBASE.png -o -name $ICONBASE.xpm -o -name $ICONBASE.jpg -o -name $ICONBASE.jpeg -o -name $ICONBASE.gif -o -name $ICONBASE.svg | grep -i -E 'png$|xpm$|jpg$|jpeg$|gif$|svg$' | head -n 1`"
   #111207 getting desperate...
   [ ! "$FNDICON" ] && FNDICON="`find /usr/share -name $ICONBASE -o -name $ICONBASE.png -o -name $ICONBASE.xpm -o -name $ICONBASE.jpg -o -name $ICONBASE.jpeg -o -name $ICONBASE.gif -o -name $ICONBASE.svg | grep -i -E 'png$|xpm$|jpg$|jpeg$|gif$|svg$' | head -n 1`"
   if [ "$FNDICON" ];then
    ICONNAMEONLY="`basename "$FNDICON"`"
    ln -snf "$FNDICON" /usr/share/pixmaps/${ICONNAMEONLY}
    iPTN="s%^Icon=.*%Icon=${ICONNAMEONLY}%"
    sed -i -e "$iPTN" $ONEDOT
    continue
   fi
  fi
  #substitute a default icon...
  sed -i -e "$iPATTERN" $ONEDOT #note, ONEDOT is name of .desktop file.
 fi
 
 #120926 if a langpack installed, it will have /usr/share/applications.in (see /usr/sbin/momanager, /usr/share/doc/langpack-template/pinstall.sh).
 ABASEDESKTOP="`basename $ONEDOT`"
 ADIRDESKTOP="`dirname $ONEDOT`"
 if [ -f /usr/share/applications.in/${ABASEDESKTOP} ];then
  TARGETLANG="`echo -n $LANG_USER | cut -f 1 -d '_'`" #ex: de
  tlPTN="^Name\[${TARGETLANG}\]"
  if [ "$(grep "$tlPTN" ${ADIRDESKTOP}/${ABASEDESKTOP})" = "" ];then
   if [ "$(grep "$tlPTN" /usr/share/applications.in/${ABASEDESKTOP})" != "" ];then
    #aaargh, these accursed back-slashes! ....
    INSERTALINE="`grep "$tlPTN" /usr/share/applications.in/${ABASEDESKTOP} | sed -e 's%\[%\\\\[%' -e 's%\]%\\\\]%'`"
    sed -i -e "s%^Name=%${INSERTALINE}\\nName=%" ${ADIRDESKTOP}/${ABASEDESKTOP}
   fi
  fi
  #do same for Comment field...
  tlPTN="^Comment\[${TARGETLANG}\]"
  if [ "$(grep "$tlPTN" ${ADIRDESKTOP}/${ABASEDESKTOP})" = "" ];then
   if [ "$(grep "$tlPTN" /usr/share/applications.in/${ABASEDESKTOP})" != "" ];then
    #aaargh, these accursed back-slashes! ....
    INSERTALINE="`grep "$tlPTN" /usr/share/applications.in/${ABASEDESKTOP} | sed -e 's%\[%\\\\[%' -e 's%\]%\\\\]%'`"
    sed -i -e "s%^Comment=%${INSERTALINE}\\nComment=%" ${ADIRDESKTOP}/${ABASEDESKTOP}
   fi
  fi
  #well, i suppose need this too...
  TARGETLANG="`echo -n $LANG_USER | cut -f 1 -d '.'`" #ex: de_DE
  tlPTN="^Name\[${TARGETLANG}\]"
  if [ "$(grep "$tlPTN" ${ADIRDESKTOP}/${ABASEDESKTOP})" = "" ];then
   if [ "$(grep "$tlPTN" /usr/share/applications.in/${ABASEDESKTOP})" != "" ];then
    #aaargh, these accursed back-slashes! ....
    INSERTALINE="`grep "$tlPTN" /usr/share/applications.in/${ABASEDESKTOP} | sed -e 's%\[%\\\\[%' -e 's%\]%\\\\]%'`"
    sed -i -e "s%^Name=%${INSERTALINE}\\nName=%" ${ADIRDESKTOP}/${ABASEDESKTOP}
   fi
  fi
  #do same for Comment field...
  tlPTN="^Comment\[${TARGETLANG}\]"
  if [ "$(grep "$tlPTN" ${ADIRDESKTOP}/${ABASEDESKTOP})" = "" ];then
   if [ "$(grep "$tlPTN" /usr/share/applications.in/${ABASEDESKTOP})" != "" ];then
    #aaargh, these accursed back-slashes! ....
    INSERTALINE="`grep "$tlPTN" /usr/share/applications.in/${ABASEDESKTOP} | sed -e 's%\[%\\\\[%' -e 's%\]%\\\\]%'`"
    sed -i -e "s%^Comment=%${INSERTALINE}\\nComment=%" ${ADIRDESKTOP}/${ABASEDESKTOP}
   fi
  fi
 fi
 
done

#due to images at / in .pet and post-install script, .files may have some invalid entries...
INSTFILES="`cat /root/.packages/package-files/${DLPKG_NAME}.files`"
echo "$INSTFILES" |
while read ONEFILE
do
 if [ ! -e "$ONEFILE" ];then
  ofPATTERN='^'"$ONEFILE"'$'
  grep -v "$ofPATTERN" /root/.packages/package-files/${DLPKG_NAME}.files > /tmp/petget-proc/petget_instfiles
  mv -f /tmp/petget-proc/petget_instfiles /root/.packages/package-files/${DLPKG_NAME}.files
 fi
done

#w482 DB_ENTRY may be missing DB_category and DB_description fields...
#pkgname|nameonly|version|pkgrelease|category|size|path|fullfilename|dependencies|description|
#optionally on the end: compileddistro|compiledrelease|repo| (fields 11,12,13)
DESKTOPFILE="`grep '\.desktop$' /root/.packages/package-files/${DLPKG_NAME}.files | head -n 1`"
if [ "$DESKTOPFILE" != "" ];then
 DB_category="`echo -n "$DB_ENTRY" | cut -f 5 -d '|'`"
 DB_description="`echo -n "$DB_ENTRY" | cut -f 10 -d '|'`"
 CATEGORY="$DB_category"
 DESCRIPTION="$DB_description"
 zCATEGORY="`cat $DESKTOPFILE | grep '^Categories=' | sed -e 's%;$%%' | cut -f 2 -d '=' | rev | cut -f 1 -d ';' | rev`" #121109
 if [ "$zCATEGORY" != "" ];then #121109
  #v424 but want the top-level menu category...
  catPATTERN="[ ,]${zCATEGORY},|[ ,]${zCATEGORY} |[ ,]${zCATEGORY}"'$' #121119 fix bug in pattern.
  CATEGORY="`echo "$PUPHIERARCHY" | cut -f 1 -d '#' | grep -E "$catPATTERN" | grep ':' | cut -f 1 -d ' ' | head -n 1`" #121119 /etc/xdg/menus/hierarchy 
 fi
 if [ "$DB_description" = "" ];then
  DESCRIPTION="`cat $DESKTOPFILE | grep '^Comment=' | cut -f 2 -d '='`"
  [ "$DESCRIPTION" = "" ] && DESCRIPTION="`cat $DESKTOPFILE | grep '^Name=' | cut -f 2 -d '='`"	# shinobar
 fi
 if [ "$DB_category" = "" -o "$DB_description" = "" ];then
  newDB_ENTRY="`echo -n "$DB_ENTRY" | cut -f 1-4 -d '|'`"
  newDB_ENTRY="$newDB_ENTRY"'|'"$CATEGORY"'|'
  newDB_ENTRY="$newDB_ENTRY""`echo -n "$DB_ENTRY" | cut -f 6-9 -d '|'`"
  newDB_ENTRY="$newDB_ENTRY"'|'"$DESCRIPTION"'|'
  newDB_ENTRY="$newDB_ENTRY""`echo -n "$DB_ENTRY" | cut -f 11-14 -d '|'`"
  DB_ENTRY="$newDB_ENTRY"
 fi
fi

pkgn1=`echo "$DB_ENTRY" | cut -f 2 -d '|'`

update_file_list $pkgn1

echo "$DB_ENTRY" >> /root/.packages/user-installed-packages

#110706 fix 'Exec filename %u' line...
DESKTOPFILES="`grep '\.desktop$' /root/.packages/package-files/${DLPKG_NAME}.files | tr '\n' ' '`"
for ONEDESKTOP in $DESKTOPFILES
do
 sed -i -e 's/ %u$//' $ONEDESKTOP
done

#120907 post-install hacks...
/usr/local/petget/hacks-postinstall.sh $DLPKG_MAIN

#announcement of successful install...
#announcement is done after all downloads, in downloadpkgs.sh...
CATEGORY="`echo -n "$CATEGORY" | cut -f 1 -d ';'`"
[ "$CATEGORY" = "" ] && CATEGORY="none"
[ "$CATEGORY" = "BuildingBlock" ] && CATEGORY="none"
echo "PACKAGE: $DLPKG_NAME CATEGORY: $CATEGORY" >> /tmp/petget-proc/petget-installed-pkgs-log

#110503 change ownership of some files if non-root...
#hmmm, i think this will only work if running this script as root...
# (the entry script pkg_chooser.sh has sudo to switch to root)
HOMEUSER="`grep '^tty1' /etc/inittab | tr -s ' ' | cut -f 3 -d ' '`" #root or fido.
if [ "$HOMEUSER" != "root" ];then
 grep -E '^/var|^/root|^/etc' /root/.packages/package-files/${DLPKG_NAME}.files |
 while read FILELINE
 do
  busybox chown ${HOMEUSER}:users "${FILELINE}"
 done
fi

PKGFILE="/root/.packages/package-files/${DLPKG_NAME}.files"

arch1="$(uname -m)"

case $arch1 in
i?86)
 ldpaths="lib lib32 lib/i386-linux-gnu"
;;
x86_64|amd64)
 ldpaths="lib lib64 lib/x86_64-linux-gnu lib/amd64-linux-gnu"
;;
esac

for libfld in $ldpaths
do
	if [ "`grep "^/$libfld/gio/modules/" "$PKGFILE"`" != "" ];then
	 gio-querymodules /$libfld/gio/modules
	fi
done

for pkgpath in /usr /usr/local
do

	#120523 precise puppy needs this... (refer also rc.update and 3builddistro)
	if [ "`grep "$pkgpath/share/glib-2.0/schemas/" "$PKGFILE"`" != "" ];then
	 glib-compile-schemas $pkgpath/share/glib-2.0/schemas
	fi

	if [ "`grep "$pkgpath/share/mime/" "$PKGFILE"`" != "" ];then
	 update-mime-database $pkgpath/share/mime
	fi

	if [ "`grep "$pkgpath/share/icons/hicolor/" "$PKGFILE"`" != "" ];then
	 gtk-update-icon-cache $pkgpath/share/icons/hicolor
	fi

	if [ "`grep "$pkgpath/share/applications/" "$PKGFILE"`" != "" ];then
	 rm -f $pkgpath/share/applications/mimeinfo.cache
	 update-desktop-database $pkgpath/share/applications
	fi
	
	for libfld in $ldpaths
	 do
		if [ "`grep "$pkgpath/$libfld/gio/modules/" "$PKGFILE"`" != "" ];then
		 gio-querymodules $pkgpath/$libfld/gio/modules
		fi
    done	
done

if [ "`grep '/share/fonts/' "$PKGFILE"`" != "" ];then
 fc-cache -f
fi

if [ "`grep '/gconv/' "$PKGFILE" | grep "/lib"`" != "" ];then
 iconvconfig
fi

if [ "`grep '/gdk-pixbuf' "$PKGFILE" | grep "/lib"`" != "" ];then
 gdk-pixbuf-query-loaders --update-cache
fi

if [ "`grep '/pango/' "$PKGFILE" | grep "/lib"`" != "" ];then
 pango-querymodules --update-cache
fi

for gtkver in $GTKVERLIST
do
 if [ "`grep "/gtk-$gtkver" "$PKGFILE" | grep "/immodules" | grep "/lib"`" != "" ];then
  gtk-query-immodules-$gtkver --update-cache
 fi
done

if [ "`grep '/wine' "$PKGFILE"`" != "" ];then
 if [ "$(which xdg-wine)" != "" ] && [ "$(pidof xdg-wine)" == "" ]; then
  xdg-wine
 fi
fi

KVER="$(uname -r)"

if [ "`grep "/lib/modules/$KVER/" "$PKGFILE"`" != "" ];then
 depmod -a
fi

rm -f $HOME/nohup.out

###END###