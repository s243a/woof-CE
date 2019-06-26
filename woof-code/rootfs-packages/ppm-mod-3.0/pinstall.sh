#!/bin/sh

. /root/.packages/DISTRO_PET_REPOS
. /root/.packages/DISTRO_COMPAT_REPOS

if [ ! -d /root/.packages/package-files ]; then
mkdir /root/.packages/package-files
fi

if [ ! -d /root/.packages/repo ]; then
mkdir /root/.packages/repo
fi

if [ ! -d /root/.packages/downloaded-pkg ]; then
mkdir /root/.packages/downloaded-pkg
fi

if [ ! -d /root/.packages/system-app-files ]; then
mkdir /root/.packages/system-app-files
fi

if [ ! -d /root/.packages/remove-script ]; then
mkdir /root/.packages/remove-script
fi

if [ ! -d /root/.packages/database ]; then
mkdir /root/.packages/database
fi

if [ ! -d /root/.packages/package-info ]; then
mkdir /root/.packages/package-info
fi

mv -f /root/.packages/*.files /root/.packages/package-files/ 
mv -f /root/.packages/*.remove /root/.packages/remove-script/ 
mv -f /root/.packages/Packages-* /root/.packages/repo/ 


for line in $PET_REPOS
do
echo "$line" >> /root/.packages/database/PET_REPO_LIST
done

for line in $PKG_DOCS_PET_REPOS
do
echo "$line" >> /root/.packages/database/PET_DB_REPO
done

for line in $PACKAGELISTS_PET_ORDER
do
echo "$line" >> /root/.packages/database/PET_ORDER_LIST
done

for line in $REPOS_DISTRO_COMPAT
do
echo "$line" >> /root/.packages/database/COMPAT_REPO_LIST
done

for line in $PKG_DOCS_DISTRO_COMPAT
do
echo "$line" >> /root/.packages/database/COMPAT_DB_REPO
done

echo "This petget is currently modified" > /root/.packages/petget-mod-notes

for dir2 in /usr /usr/local
do
 update-desktop-database $dir2/share/applications
 update-mime-database $dir2/share/applications
 gtk-update-icon-cache $dir2/share/icons/hicolor
done

echo "exec probe-wine" >> /usr/local/pup_event/frontend_timeout
