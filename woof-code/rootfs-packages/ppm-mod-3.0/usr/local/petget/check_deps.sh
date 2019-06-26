#!/bin/sh
#choose an installed pkg and find all its dependencies.
#when entered with a passed param, it is a list of pkgs, '|' delimited,
#ex: abiword-1.2.3|aiksaurus-3.4.5|yabby-5.0
#100718 bug fix: code block copied from /usr/local/petget/pkg_chooser.sh
#100718 reduce size of missing-libs list, to fit in window.
#100830 missing libs, but some pkgs have a startup script that makes some libs visible.
#101220 reported missing 'alsa-lib' but wary has 'alsa-lib21a', quick hack fix.
#101221 yaf-splash fix.
#110706 finding missing dependencies fix (running mageia 1).
#120203 BK: internationalized.
#120222 npierce: use list widget, support '_' in name.
#120905 vertical scrollbars, fix window too high.
#130511 need to include devx-only-installed-packages, if loaded.

mkdir -p /tmp/petget-proc

[ "$(cat /var/local/petget/nt_category 2>/dev/null)" != "true" ] && \
 [ -f /tmp/petget-proc/install_quietly ] && set -x
 #; mkdir -p /tmp/petget-proc/PPM_LOGs ; NAME=$(basename "$0"); exec 1>> /tmp/petget-proc/PPM_LOGs/"$NAME".log 2>&1

export TEXTDOMAIN=petget___check_deps.sh
export OUTPUT_CHARSET=UTF-8

. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
. /root/.packages/DISTRO_PKGS_SPECS

echo -n "" > /tmp/petget-proc/missinglibs.txt
echo -n "" > /tmp/petget-proc/missinglibs_details.txt
echo -n "" > /tmp/petget-proc/missingpkgs.txt
echo -n "" > /tmp/petget-proc/missinglibs_cut.txt #100830
echo -n "" > /tmp/petget-proc/missinglibs_hidden.txt #100830

###130511 also this copied from pkg_chooser.sh...
if [ ! -f /root/.packages/layers-installed-packages ];then
 #need to include devx-only-installed-packages, if loaded...
 if which gcc;then
  cp -f /root/.packages/woof-installed-packages /tmp/petget-proc/ppm-layers-installed-packages
  cat /root/.packages/devx-only-installed-packages >> /tmp/petget-proc/ppm-layers-installed-packages
  sort -u /tmp/petget-proc/ppm-layers-installed-packages > /root/.packages/layers-installed-packages
 else
  cp -f /root/.packages/woof-installed-packages /root/.packages/layers-installed-packages
 fi
fi

#######100718 code block copied from /usr/local/petget/pkg_chooser.sh#######
. /root/.packages/PKGS_MANAGEMENT #has PKG_REPOS_ENABLED, PKG_NAME_ALIASES

#finds all user-installed pkgs and formats ready for display...
/usr/local/petget/finduserinstalledpkgs.sh #writes to /tmp/petget-proc/installedpkgs.results

#100711 moved from findmissingpkgs.sh...
if [ ! -f /tmp/petget-proc/petget_installed_patterns_system ];then
 INSTALLED_PATTERNS_SYS="`cat /root/.packages/layers-installed-packages | cut -f 2 -d '|' | sed -e 's%^%|%' -e 's%$%|%' -e 's%\\-%\\\\-%g'`"
 echo "$INSTALLED_PATTERNS_SYS" > /tmp/petget-proc/petget_installed_patterns_system
 #PKGS_SPECS_TABLE also has system-installed names, some of them are generic combinations of pkgs...
 INSTALLED_PATTERNS_GEN="`echo "$PKGS_SPECS_TABLE" | grep '^yes' | cut -f 2 -d '|' |  sed -e 's%^%|%' -e 's%$%|%' -e 's%\\-%\\\\-%g'`"
 echo "$INSTALLED_PATTERNS_GEN" >> /tmp/petget-proc/petget_installed_patterns_system
 sort -u /tmp/petget-proc/petget_installed_patterns_system > /tmp/petget-proc/petget_installed_patterns_systemx
 mv -f /tmp/petget-proc/petget_installed_patterns_systemx /tmp/petget-proc/petget_installed_patterns_system
fi
#100711 this code repeated in findmissingpkgs.sh...
cp -f /tmp/petget-proc/petget_installed_patterns_system /tmp/petget-proc/petget_installed_patterns_all
INSTALLED_PATTERNS_USER="`cat /root/.packages/user-installed-packages | cut -f 2 -d '|' | sed -e 's%^%|%' -e 's%$%|%' -e 's%\\-%\\\\-%g'`"
echo "$INSTALLED_PATTERNS_USER" >> /tmp/petget-proc/petget_installed_patterns_all

#process name aliases into patterns (used in filterpkgs.sh, findmissingpkgs.sh) ... 100126...
xPKG_NAME_ALIASES="`echo "$PKG_NAME_ALIASES" | tr ' ' '\n' | grep -v '^$' | sed -e 's%^%|%' -e 's%$%|%' -e 's%,%|,|%g' -e 's%\\*%.*%g'`"
echo "$xPKG_NAME_ALIASES" > /tmp/petget-proc/petget_pkg_name_aliases_patterns_raw #110706
cp -f /tmp/petget-proc/petget_pkg_name_aliases_patterns_raw /tmp/petget-proc/petget_pkg_name_aliases_patterns #110706 _raw see findmissingpkgs.sh

sed -e 's%\\%%g' /tmp/petget-proc/petget_installed_patterns_all > /tmp/petget-proc/petget_installed_patterns_all2 #101220 hack bugfix, \- should be just -.

#100711 above has a problem as it has wildcards. need to expand...
#ex: PKG_NAME_ALIASES has an entry 'cxxlibs,glibc*,libc-*', the above creates '|cxxlibs|,|glibc.*|,|libc\-.*|',
#    after expansion: '|cxxlibs|,|glibc|,|libc-|,|glibc|,|glibc_dev|,|glibc_locales|,|glibc-solibs|,|glibc-zoneinfo|'
echo -n "" > /tmp/petget-proc/petget_pkg_name_aliases_patterns_expanded
for ONEALIASLINE in `cat /tmp/petget-proc/petget_pkg_name_aliases_patterns | tr '\n' ' '` #ex: |cxxlibs|,|glibc.*|,|libc\-.*|
do
 echo -n "" > /tmp/petget-proc/petget_temp1
 for PARTONELINE in `echo -n "$ONEALIASLINE" | tr ',' ' '`
 do
  grep "$PARTONELINE" /tmp/petget-proc/petget_installed_patterns_all2 >> /tmp/petget-proc/petget_temp1 #101220 hack see above.
 done
 ZZZ="`echo "$ONEALIASLINE" | sed -e 's%\.\*%%g' | tr -d '\\'`"
 [ -s /tmp/petget-proc/petget_temp1 ] && ZZZ="${ZZZ},`cat /tmp/petget-proc/petget_temp1 | tr '\n' ',' | tr -s ',' | tr -d '\\'`"
 ZZZ="`echo -n "$ZZZ" | sed -e 's%,$%%'`"
 echo "$ZZZ" >> /tmp/petget-proc/petget_pkg_name_aliases_patterns_expanded
done
cp -f /tmp/petget-proc/petget_pkg_name_aliases_patterns_expanded /tmp/petget-proc/petget_pkg_name_aliases_patterns

#w480 PKG_NAME_IGNORE is definedin PKGS_MANAGEMENT file... 100126...
xPKG_NAME_IGNORE="`echo "$PKG_NAME_IGNORE" | tr ' ' '\n' | grep -v '^$' | sed -e 's%^%|%' -e 's%$%|%' -e 's%,%|,|%g' -e 's%\\*%.*%g'`"
echo "$xPKG_NAME_IGNORE" > /tmp/petget-proc/petget_pkg_name_ignore_patterns
#######100718 end copied code block#######

dependcheckfunc() {
 #entered with ex: APKGNAME=abiword-1.2.3
 
 if [ ! -f /tmp/petget-proc/install_quietly ]; then
  /usr/lib/gtkdialog/box_splash -close never -placement center -text "$(gettext 'Checking') ${APKGNAME} $(gettext 'for missing shared library files...')" &
  X1PID=$!
 fi
 
 #a hack if OO is installed...
 if [ "`echo -n "$APKGNAME" | grep 'openoffice'`" != "" ];then
  [ -d /opt ] && FNDOO="`find /opt -maxdepth 2 -type d -iname 'openoffice*'`"
  [ "$FNDOO" = "" ] && FNDOO="`find /usr -maxdepth 2 -type d -iname 'openoffice*'`"
  [ "$FNDOO" = "" ] && LD_LIBRARY_PATH="${FNDOO}/program:${LD_LIBRARY_PATH}"
 fi

 FNDFILES="`cat /root/.packages/package-files/$APKGNAME.files`"
 for ONEFILE in $FNDFILES
 do
  ISANEXEC="`file --brief $ONEFILE | grep --extended-regexp "LSB executable|shared object"`"
  if [ ! "$ISANEXEC" = "" ];then
   LDDRESULT="`ldd $ONEFILE`"
   MISSINGLIBS="`echo "$LDDRESULT" | grep "not found" | cut -f 2 | cut -f 1 -d " " | tr "\n" " "`"
   if [ ! "$MISSINGLIBS" = "" ];then
    echo "$(gettext 'File') $ONEFILE $(gettext 'has these missing library files:')" >> /tmp/petget-proc/missinglibs_details.txt #100718
    echo " $MISSINGLIBS" >> /tmp/petget-proc/missinglibs_details.txt #100718
    echo " $MISSINGLIBS" >> /tmp/petget-proc/missinglibs.txt #100718
   fi
  fi
 done
 if [ -s /tmp/petget-proc/missinglibs.txt ];then #100718 reduce size of list, to fit in window...
  MISSINGLIBSLIST="`cat /tmp/petget-proc/missinglibs.txt | tr '\n' ' ' | tr -s ' ' | tr ' ' '\n' | sort -u | tr '\n' ' '`"
  echo "$MISSINGLIBSLIST" > /tmp/petget-proc/missinglibs.txt
  #100830 some packages, such as EudoraOSE-1.0rc1-Lucid.pet used in Lucid Puppy 5.1, have a
  #startup script that makes some libs visible (/opt/eudora), so do this extra check...
  for ONEMISSINGLIB in `cat /tmp/petget-proc/missinglibs.txt` #100830
  do
   if [ "`find /opt /usr/lib /usr/local/lib -maxdepth 3 -name $ONEMISSINGLIB`" == "" ];then
    echo -n "$ONEMISSINGLIB " >> /tmp/petget-proc/missinglibs_cut.txt
   else
    echo -n "$ONEMISSINGLIB " >> /tmp/petget-proc/missinglibs_hidden.txt
   fi
  done
  cp -f /tmp/petget-proc/missinglibs_cut.txt /tmp/petget-proc/missinglibs.txt
 fi
 [ ! -f /tmp/petget-proc/install_quietly ] && kill $X1PID || echo
}

#searches deps of all user-installed pkgs...
missingpkgsfunc() {
 if [ ! -f /tmp/petget-proc/install_quietly ]; then
  /usr/lib/gtkdialog/box_splash -close never -text "$(gettext 'Checking all user-installed packages for any missing dependencies...')" &
  X2PID=$!
 fi
  USER_DB_dependencies="`cat /root/.packages/user-installed-packages | cut -f 9 -d '|' | tr ',' '\n' | sort -u | tr '\n' ','`"
  /usr/local/petget/findmissingpkgs.sh "$USER_DB_dependencies"
  #...returns /tmp/petget-proc/petget_installed_patterns_all, /tmp/petget-proc/petget_pkg_deps_patterns, /tmp/petget-proc/petget_missingpkgs_patterns
  MISSINGDEPS_PATTERNS="`cat /tmp/petget-proc/petget_missingpkgs_patterns`" #v431
  [ ! -f /tmp/petget-proc/install_quietly ] && kill $X2PID || echo
}

if [ $1 ];then
 for APKGNAME in `echo -n $1 | tr '|' ' '`
 do
  [ -f /root/.packages/${APKGNAME}.files ] && dependcheckfunc
 done
else
 #ask user what pkg to check...
 ACTIONBUTTON="<button>
     <label>$(gettext 'Check dependencies')</label>
     <action type=\"exit\">BUTTON_CHK_DEPS</action>
    </button>"
 echo -n "" > /tmp/petget-proc/petget_depchk_buttons
 cat /root/.packages/user-installed-packages | cut -f 1,10 -d '|' |
 while read ONEPKGSPEC
 do
  [ "$ONEPKGSPEC" = "" ] && continue
  ONEPKG="`echo -n "$ONEPKGSPEC" | cut -f 1 -d '|'`"
  ONEDESCR="`echo -n "$ONEPKGSPEC" | cut -f 2 -d '|'`"
  #120222 npierce: replaced radiobuttons with list and items 
  echo "${ONEPKG}|${ONEDESCR}" >> /tmp/petget-proc/petget_depchk_buttons
 done
 RADBUTTONS="`cat /tmp/petget-proc/petget_depchk_buttons`"
 if [ "$RADBUTTONS" = "" ];then
  ACTIONBUTTON=""
  RADBUTTONS="<item>$(gettext "No packages installed by user, click 'Cancel' button")</item>"
 fi
 export DEPS_DIALOG="<window title=\"$(gettext 'Puppy Package Manager')\" icon-name=\"gtk-about\">
  <vbox>
   <text><label>$(gettext 'Please choose what package you would like to check the dependencies of:')</label></text>
   <frame $(gettext 'User-installed packages')>

    <tree column-header-active=\"false|false\" space-fill=\"true\">
    <label>Package|Description</label>
    <variable>LIST</variable>
    <input>cat /tmp/petget-proc/petget_depchk_buttons</input>
    </tree>
    
   </frame>
   <hbox>
    ${ACTIONBUTTON}
    <button cancel></button>
   </hbox>
  </vbox>
 </window>
" 
 RETPARAMS="`gtkdialog3 --geometry=630x327 --program=DEPS_DIALOG`" #120222
 #ex returned:
 #LIST="audacious-1.5.1"
 #EXIT="BUTTON_CHK_DEPS"

 [ "`echo "$RETPARAMS" | grep 'BUTTON_CHK_DEPS'`" = "" ] && exit
 
 #120222 npierce: Allow '_' in package name.  CAUTION: Names must not contain spaces. 
 APKGNAME="`echo "$RETPARAMS" | grep '^LIST=' | cut -f 1 -d ' ' | cut -f 2 -d '"'`" #'geanyfix
 dependcheckfunc
 
fi

if [ -f /tmp/petget-proc/install_pets_quietly ]; then
 LEFT=$(cat /tmp/petget-proc/pkgs_left_to_install | wc -l)
 [ "$LEFT" -le 1 ] && missingpkgsfunc
else
 missingpkgsfunc
fi

DEPFILES=0
PKGCOUNT=0
HIDDENLIBS=0

#present results to user...
MISSINGMSG0="<text ypad=\"5\" xpad=\"5\" yalign=\"0\" xalign=\"0\" use-markup=\"true\" space-fill=\"true\"><label>$(gettext 'These libraries are missing:')</label></text>"

if [ -s /tmp/petget-proc/missinglibs.txt ];then

	echo -n "" > /tmp/petget-proc/missinglibs-sort.txt

	for l1 in `cat /tmp/petget-proc/missinglibs.txt`
	do
	echo $l1 >> /tmp/petget-proc/missinglibs-sort.txt
	done

	DEPFILES=$(wc -l < /tmp/petget-proc/missinglibs-sort.txt)
	
	if [ $DEPFILES -gt 0 ]; then
    MISSINGMSG1="<text ypad=\"5\" xpad=\"5\" yalign=\"0\" xalign=\"0\" use-markup=\"true\" space-expand=\"true\" space-fill=\"true\"><label>\"`cat /tmp/petget-proc/missinglibs-sort.txt`\"</label></text>"
	else
	MISSINGMSG1="<text ypad=\"5\" xpad=\"5\" yalign=\"0\" xalign=\"0\" use-markup=\"true\" space-expand=\"true\" space-fill=\"true\"><label>\"$(gettext 'No missing shared libraries')\"</label></text>"
	fi
else
	MISSINGMSG1="<text ypad=\"5\" xpad=\"5\" yalign=\"0\" xalign=\"0\" use-markup=\"true\" space-expand=\"true\" space-fill=\"true\"><label>\"$(gettext 'No missing shared libraries')\"</label></text>"
fi

HIDDENMSG1="<text ypad=\"5\" xpad=\"5\" yalign=\"0\" xalign=\"0\" use-markup=\"true\" space-expand=\"true\" space-fill=\"true\"><label>$(gettext 'These needed libraries exist but are not in the library search path (it is assumed that a startup script in the package makes these libraries loadable by the application):')</label></text>"

if [ -s /tmp/petget-proc/missinglibs_hidden.txt ];then #100830
    
	echo -n "" > /tmp/petget-proc/missingpkg-sort.txt

	for l1 in `cat /tmp/petget-proc/missinglibs_hidden.txt`
	do
	echo $l1 >> /tmp/petget-proc/missingpkghidden-sort.txt
	done
	
	HIDDENLIBS=$(wc -l < /tmp/petget-proc/missingpkghidden-sort.txt)
	
	if [ $HIDDENLIBS -gt 0 ]; then
    HIDDENMSG2="<text ypad=\"5\" xpad=\"5\" yalign=\"0\" xalign=\"0\" use-markup=\"true\" space-expand=\"true\" space-fill=\"true\"><label>\"$(cat /tmp/petget-proc/missingpkghidden-sort.txt)\"</label></text>"
	else
	HIDDENMSG2="<text ypad=\"5\" xpad=\"5\" yalign=\"0\" xalign=\"0\" use-markup=\"true\" space-expand=\"true\" space-fill=\"true\"><label>\"$(gettext 'No missing shared libraries')\"</label></text>"
	fi
else
	HIDDENMSG2="<text ypad=\"5\" xpad=\"5\" yalign=\"0\" xalign=\"0\" use-markup=\"true\" space-expand=\"true\" space-fill=\"true\"><label>\"$(gettext 'No missing shared libraries')\"</label></text>"
fi


MISSINGMSG2="<text ypad=\"5\" xpad=\"5\" yalign=\"0\" xalign=\"0\" use-markup=\"true\" space-expand=\"true\" space-fill=\"true\"><label>\"$(gettext 'No missing dependent packages')\"</label></text>"

if [ "$MISSINGDEPS_PATTERNS" != "" ];then #[ -s /tmp/petget-proc/petget_missingpkgs ];then

 MISSINGPKGS="`echo "$MISSINGDEPS_PATTERNS" | sed -e 's%|%%g' | tr '\n' ' '`" #v431
 
	echo -n "" > /tmp/petget-proc/missingpkg-sort.txt

	for l1 in ${MISSINGPKGS}
	do
	echo $l1 >> /tmp/petget-proc/missingpkg-sort.txt
	done
	
	PKGCOUNT=$(wc -l < /tmp/petget-proc/missingpkg-sort.txt)
	
 MISSINGPKGS=`cat /tmp/petget-proc/missingpkg-sort.txt`

 MISSINGMSG2="<text ypad=\"5\" xpad=\"5\" yalign=\"0\" xalign=\"0\" use-markup=\"true\" space-expand=\"true\" space-fill=\"true\"><label>\"${MISSINGPKGS}\"</label></text>"

fi


DETAILSBUTTON=""
if [ -s /tmp/petget-proc/missinglibs.txt -o -s /tmp/petget-proc/missinglibs_hidden.txt ];then #100830 details button
 DETAILSBUTTON="<button><label>$(gettext 'View details')</label><action>defaulttextviewer /tmp/petget-proc/missinglibs_details.txt & </action></button>"
fi

PKGS="$APKGNAME"
[ $1 ] && PKGS="`echo -n "${1}" | tr '|' ' '`"

#120905 vertical scrollbars, fix window too high...
if [ ! -f /tmp/petget-proc/install_quietly ]; then
export DEPS_DIALOG="<window title=\"$(gettext 'Puppy Package Manager')\" icon-name=\"gtk-about\" resizable=\"false\">
  <vbox>
  
  <vbox>
   <text><label>$(gettext 'Puppy has searched for any missing shared libraries of these packages:')</label></text>
   <text><label>${PKGS}</label></text>
   <text><label>\" \"</label></text>
  </vbox>
  
 <notebook labels=\"Missing Files (${DEPFILES})|Missing Dependencies (${PKGCOUNT})|Hidden (${HIDDENLIBS})\"> 

	   <vbox height-request=\"250\" width-request=\"450\" margin=\"8\">
			  ${MISSINGMSG0}
			  <vbox scrollable=\"true\">
			  ${MISSINGMSG1}
			  </vbox>
	   </vbox>
	   
	   <vbox margin=\"8\">
		   <vbox>
		   <text ypad=\"5\" xpad=\"5\" yalign=\"0\" xalign=\"0\" use-markup=\"true\" space-fill=\"true\"><label>$(gettext 'Puppy has examined all user-installed packages and found these missing dependencies:')</label></text>
		   </vbox>
		   	   <vbox scrollable=\"true\">
			   ${MISSINGMSG2}
			   </vbox>
	   </vbox>
   
	   <vbox margin=\"8\">
		   <vbox>
		   ${HIDDENMSG1}
		   </vbox>
			   <vbox scrollable=\"true\">
			   ${HIDDENMSG2}
			   </vbox>
	   </vbox>
   
   </notebook>
   
   <hbox>
    ${DETAILSBUTTON}
    <button ok></button>
   </hbox>
   
  </vbox>
 </window>
" 
 RETPARAMS="`gtkdialog4 --center --program=DEPS_DIALOG`"
else
 RETPARAMS='EXIT="OK"'
 rm -f /tmp/petget-proc/petget_missing_dbentries-* 2>/dev/null
 cat /tmp/petget-proc/petget_missingpkgs_patterns_with_versioning >> \
  /tmp/petget-proc/overall_petget_missingpkgs_patterns.txt
 rm -f /tmp/petget-proc/petget_missingpkgs_patterns* 2>/dev/null
 cat /tmp/petget-proc/missinglibs.txt >> /tmp/petget-proc/overall_missing_libs.txt
 cat /tmp/petget-proc/missinglibs_hidden.txt >> /tmp/petget-proc/overall_missing_libs_hidden.txt
 rm -f /tmp/petget-proc/missinglibs* 2>/dev/null
fi

###END###
