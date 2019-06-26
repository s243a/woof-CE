#!/bin/sh

mv -f /root/.packages/package-files/*.files /root/.packages/
mv -f /root/.packages/remove-script/*.remove /root/.packages/ 
mv -f /root/.packages/repo/Packages-* /root/.packages/
rm -f /root/.packages/database/*
rm -f /root/.packages/package-info/*

if [ -d /root/.packages/package-files ]; then
rmdir /root/.packages/package-files
fi

if [ -d /root/.packages/repo ]; then
rmdir /root/.packages/repo
fi

if [ -d /root/.packages/downloaded-pkg ]; then
rmdir /root/.packages/downloaded-pkg
fi

if [ -d /root/.packages/system-app-files ]; then
rmdir /root/.packages/system-app-files
fi

if [ -d /root/.packages/remove-script ]; then
rmdir /root/.packages/remove-script
fi

if [ -d /root/.packages/database ]; then
rmdir /root/.packages/database
fi

if [ -d /root/.packages/package-info ]; then
rmdir /root/.packages/package-info
fi
	
rm -f /root/.packages/petget-mod-notes

for dir2 in /usr /usr/local
do
 update-desktop-database $dir2/share/applications
 update-mime-database $dir2/share/applications
 gtk-update-icon-cache $dir2/share/icons/hicolor
done

sed -i -e "s#exec\ probe-wine##g" /usr/local/pup_event/frontend_timeout
