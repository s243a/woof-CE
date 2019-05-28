#!/bin/sh
curdir="`realpath .`"
if [ "$curdir" != '/' ]; then
  curdir="$curdir/"
fi
which_path="`which which`"
which(){
  set +x &>/dev/null
  if [ "$curdir" = "/" ]; then #Chroot case
    "$which_path" $1
  else #Relative Case
    PATH2="$(echo $PATH | tr ":" '\n')"
    for a_path in $PATH2; do
      if [ -x "$curdir$a_path" ]; then
        echo "$curdir$a_path"
        break
      fi
    done 
  fi
}
for a_util in df mount umount ps losetup; do
   full_util_path="`which $a_util`"
   is_full=0
   case "$a_util" in
   df) 
     [ $("$full_util_path" --help | \
           grep -c coreutils) -gt 0 ] && \
     [ $(file --mime-type "$full_util_path" | \
           grep -c text/plain) -eq 0 ] && is_full=1     
     ;;
   losetup|mount|umount)
     [ $("$full_util_path" -V | \
           grep -c util-linux) -gt 0 ] && \
     [ $(file --mime-type "$full_util_path" | \
           grep -c text/plain) -eq 0 ] && is_full=1 
     ;;
   ps)
     [ $("$full_util_path" -V | \
           grep -c procps-ng) -gt 0 ] && \
     [ $(file --mime-type "$full_util_path" | \
           grep -c text/plain) -eq 0 ] && is_full=1 
     ;;     
   *)
     [ $("$full_util_path" --help | \
           grep -c BusyBox) -eq 0 ] && \
     [ $(file --mime-type "$full_util_path" | \
           grep -c text/plain) -eq 0 ] && is_full=1 
     ;;
   esac 
     full_util_dir="$(dirname "$full_util_path")"
     puppy_util_path="$(which "$a_util.new")"
     puppy_util_dir="$(dirname "$puppy_util_path")"   
   if [ $is_full -eq 1 ]; then
     #if [ ! -z "" ] && [ ! -z "" ]; then
     
       #TODO maybe do a more in depth check before removing this. 
       if [ -e "$full_util_dir/$a_util-FULL" ]; then
         rm "$full_util_dir/$a_util-FULL"
       fi
       mv "$full_util_dir/$a_util" "$full_util_dir/$a_util-FULL"
       mv "$puppy_util_dir/$a_util.new" "$puppy_util_dir/$a_util"     
     #fi
   #elif [ $("$full_util_path" --help | \
   #        grep -c BusyBox) -gt 0 ]; then
   else
     [ -e "$full_util_path" ] && rm "$full_util_path"
     mv "$puppy_util_dir/$a_util.new" "$puppy_util_dir/$a_util"
   fi
done
