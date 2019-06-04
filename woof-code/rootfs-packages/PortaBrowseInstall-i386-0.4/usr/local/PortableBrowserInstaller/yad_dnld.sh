#!/bin/sh
#open in terminal
tty -s; if [ $? -ne 0 ]; then xterm -hold -e "'$0'"; exit; fi

YD=`grep "yad-" /root/.packages/woof-installed-packages | cut -d "." -f 2`
if [ "$YD" -lt "40" ]; then
  gxmessage -bg yellow -file /usr/share/doc/yad_install
  echo "Would you like to install a newer Yad? y/n"
  read YN
  if [[ $YN == "y" ]]; then
    cd /root
    wget -c http://distro.ibiblio.org/puppylinux/pet_packages-common32/yad-0.40.3-i686_common32.pet
    petget +/root/yad-0.40.3-i686_common32.pet
  fi
fi

PortableBrowserInstall



