#!/bin/bash
close_FDs(){
 exec 15>&-
}  
DPKG_ADMIN="${DPKG_ADMIN:-/var/lib/dpkg/info}"
PUPPY_ADMIN="${PUPPY_ADMIN:-/root/.packages}"
SYNC_DUMMY=${SYNC_DUMMY:-0}
[ -z "$PUPPY_ADMIN_LIST" ] && PUPPY_ADMIN_LIST="$PUPPY_ADMIN/builtin_files"
mkdir -p "$PUPPY_ADMIN"
mkdir -p "$PUPPY_ADMIN_LIST"
trap close_FDs EXIT
trap close_FDs SIGKILL
trap close_FDs SIGTERM
spec_target=${spec_target:-"$PUPPY_ADMIN/woof-installed-packages"}
mkdir -p /sync_pet_specs_fm_dpkg/deb-build/
exec 15<> /sync_pet_specs_fm_dpkg/deb-build/fd_15


# process
while read -r -u15 -d $'\n' line; do
  echo "line=$line"
  #read -p "Press enter to continue"
  case "$line" in
  'Package: '*)
    field=${line%%': '*}; val=${line#*': '}     
    pet_specs_PKG_NAME="$val" 
  ;;
  'Status: '*)
    field=${line%%': '*}; val=${line#*': '}    
  ;;
  'Priority: '*)
    field=${line%%': '*}; val=${line#*': '}      
  ;;
  'Section: '*)
    field=${line%%': '*}; val=${line#*': '} 
    pet_specs_CATEGORY="$val"    
  ;;
  'Installed-Size: '*)
    field=${line%%': '*}; val=${line#*': '} 
    pet_specs_SIZE="$val"k #TODO: Verify this is the right units
        
  ;;
  'Maintainer: '*)
    field=${line%%': '*}; val=${line#*': '} 
     
  ;;
  'Architecture: '*)
    field=${line%%': '*}; val=${line#*': '}  
  ;;
  'Version: '*)
    field=${line%%': '*}; val=${line#*': '}  
    pet_specs_VERSION="$val"
  ;;
  'Depends: '*)
    field=${line%%': '*}; val1=${line#*': '}
    val2=(${val1//,/ }) #${line#*': '}  
    val3=''
    for item in "${val2[@]}"; do
      item=${item##,*}
      item=${item##' '*}
      val3="$val3,+$item"
      val=${val3#,}
    done
    pet_specs_DEPENDS="$val"
  ;;
  'Description: '*)
    field=${line%%': '*}; val=${line#*': '}  
    pet_specs_SHORT_DESC="$val"
  ;;
  '')
    pkg_file_list="$DPKG_ADMIN/$pet_specs_PKG_NAME".list
    if [ $(wc -c <"$pkg_file_list") -gt 4 ] || [ SYNC_DUMMY -eq 1 ]; then
      if [ "$(basename "$PUPPY_ADMIN_LIST")" = builtin_files ]; then
        ln $DPKG_ADMIN/"$pet_specs_PKG_NAME".list "$PUPPY_ADMIN_LIST/$pet_specs_PKG_NAME"
      else
        ln $DPKG_ADMIN/"$pet_specs_PKG_NAME".list \
           "$PUPPY_ADMIN_LIST/$pet_specs_PKG_NAME"_"$pet_specs_VERSION".files
      fi
      #Write pet specs
      pet_specs_FULL_NAME="$pet_specs_PKG_NAME-$pet_specs_VERSION"	
	  #pet_specs_PKG_NAME=[1]
	  #pet_specs_VERSION=specs[2]
	  #pet_specs_CATEGORY=specs[4]
	  #pet_specs_SIZE=specs[5]		
	  pet_specs_BRANCH='' #specs[6] #Repository Folder
	  pet_specs_FILE_NAME="$pet_specs_PKG_NAME"_"pet_specs_VERSION".deb #specs[7] #File Namer
	  #pet_specs_DEPENDS=specs[8]
	  #pet_specs_SHORT_DESC=specs[9]
	  pet_specs_COMPILED_WITHIN='' #specs[10]
	  pet_specs_COMPAT_DISTRO_VER='' #specs[11]	
	  pet_specs_REPO_NAME='' #specs[12]
	  pet_spec="$pet_specs_FULL_NAME|$pet_specs_PKG_NAME|$pet_specs_VERSION||\
$pet_specs_CATEGORY|$pet_specs_SIZE|$pet_specs_BRANCH|$pet_specs_FILE_NAME|\
$pet_specs_DEPENDS|$pet_specs_SHORT_DESC|$pet_specs_COMPILED_WITHIN|\
$pet_specs_COMPAT_DISTRO_VER|$pet_specs_REPO_NAME"
	
	#AWK example: https://pastebin.com/bry5CweW
	  AWK_PRG="BEGIN{FS=\"|\"}
  {
    if ( \$2 == \"$pet_specs_PKG_NAME\" ) {
     print 
    }
  }"
	  file_spec_list=( "/root/.packages/"*"-installed-packages" )
	  #cat "${file_spec_list[@]}" | awk -F'|' "$AWK_PRG" #'{print $2;}'
	  specs="$( cat "${file_spec_list[@]}" | awk "$AWK_PRG" )" 
	  #match_cnt=$( echo $specs | grep -cF "$pet_specs_PKG_NAME" )
	  #if [ $match_cnt -eq 0 ]; then
	  if [ -z "$specs" ]; then
	    echo "spec_target=$spec_target"
	    mkdir -p "$(dirname "`realpath $spec_target`")" 
	    echo "$pet_spec" >> "$spec_target"
	  fi
	  #read -p "Press enter to continue"
	fi
	  ;;
	*)
	  val="$val$'\n'$line" #THis is the long description. Currently we do nothing with this. 
	  ;;
	esac
	#read -p "Press enter to continue"
done 15< <( cat /var/lib/dpkg/status )
exec 15>&-