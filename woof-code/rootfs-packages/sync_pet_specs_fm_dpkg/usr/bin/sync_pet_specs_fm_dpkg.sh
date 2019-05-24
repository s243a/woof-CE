#!/bin/bash
close_FDs(){
 exec 15>&-
}  

trap close_FDs EXIT
trap close_FDs SIGKILL
trap close_FDs SIGTERM
spec_target=${spec_target:-"/root/.packages/woof-installed-packages"}
mkdir -p /sync_pet_specs_fm_dpkg/deb-build/
exec 15<> /sync_pet_specs_fm_dpkg/deb-build/fd_15


# process
while read -r -u15 line; do

  case field in
  'Package: ')
    field=${line%%': '*}; val=${line#*': '}     
    pet_specs_PKG_NAME="$val" 
  ;;
  'Status: ')
    field=${line%%': '*}; val=${line#*': '} 
    pet_specs_VERSION="$val"      
  ;;
  Priority: )
    field=${line%%': '*}; val=${line#*': '}      
  ;;
  Section)
    field=${line%%': '*}; val=${line#*': '} 
    pet_CATEGORY="$val"    
  ;;
  Installed-Size)
    field=${line%%': '*}; val=${line#*': '} 
    pet_specs_SIZE="$val"k #TODO: Verify this is the right units
        
  ;;
  Maintainer)
    field=${line%%': '*}; val=${line#*': '} 
     
  ;;
  Architecture)
    field=${line%%': '*}; val=${line#*': '}  
  ;;
  Version)
    field=${line%%': '*}; val=${line#*': '}  
    pet_specs_VERSION="$val"
  ;;
  Depends)
    field=${line%%': '*}; val1=${line#*': '}
    val2=(${val//,/ }) ${line#*': '}  
    val3=''
    for item in "${val2[@]}"; do
      item={item##,*}
      item={item## *}
      val3="$val3,+$item"
      val=${val3#,}
    fi
    pet_specs_DEPENDS="$val"
  ;;
  Description)
    field=${line%%': '*}; val=${line#*': '}  
    pet_specs_SHORT_DESC="$val"
  ;;
  '')
    #Write pet specs
    pet_specs_FULL_NAME="$pet_specs_PKG_NAME-pet_specs_VERSION"	
	#pet_specs_PKG_NAME=[1]
	#pet_specs_VERSION=specs[2]
	#pet_specs_CATEGORY=specs[4]
	#pet_specs_SIZE=specs[5]		
	pet_specs_BRANCH='' #specs[6] #Repository Folder
	pet_FILE_NAME="$pet_specs_PKG_NAME"_"pet_specs_VERSION".deb #specs[7] #File Namer
	#pet_specs_DEPENDS=specs[8]
	#pet_specs_SHORT_DESC=specs[9]
	pet_specs_COMPILED WITHIN='' #specs[10]
	pet_specs_COMPAT_DISTRO_VER='' #specs[11]	
	process_pet_REPO_NAME='' #specs[12]
	#AWK example: https://pastebin.com/bry5CweW
	  AWK_PRG="BEGIN{FS=\"|\"}
  {
    if ( \$2 == \"$app\" ) {
     print 
    }
  }"
  file_spec_list=( "$rootfs_full/root/.packages/"*"-installed-packages" )
  #cat "${file_spec_list[@]}" | awk -F'|' "$AWK_PRG" #'{print $2;}'
  spec=$( cat "${file_spec_list[@]}" | awk "$AWK_PRG"  >> "$spec_target" ) 
  match_cnt=$( grep -cF "$spec" "$spec_target" )
  if [ $match_cnt -eq 0 ]; then
    echo "$spec" >> "$spec_target"
  fi
  *)
   val="$val$'\n'$line" #THis is the long description. Currently we do nothing with this. 
  esac
  
done 15< <( cat /var/lib/dpkg/status )
exec 15>&-