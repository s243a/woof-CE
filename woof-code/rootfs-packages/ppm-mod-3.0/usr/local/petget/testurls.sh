#!/bin/sh
#called from /usr/local/petget/downloadpkgs.sh
#/tmp/petget-proc/petget_repos has the list of repos, each line in this format:
#repository.slacky.eu|http://repository.slacky.eu/slackware-12.2|Packages-slackware-12.2-slacky
#...only the first field is of interest in this script.


echo '#!/bin/sh' >  /tmp/petget-proc/petget_urltest
echo 'echo "Testing the URLs:"' >>  /tmp/petget-proc/petget_urltest
echo '[ "$(cat /var/local/petget/nt_category 2>/dev/null)" != "true" ] && [ -f /tmp/petget-proc/install_quietly ] && set -x' >>  /tmp/petget-proc/petget_urltest

for ONEURLSPEC in `cat /tmp/petget-proc/petget_repos`
do
 URL_TEST="`echo -n "$ONEURLSPEC" | cut -f 1 -d '|'`"
 
 #[ "`wget -t 2 -T 20 --waitretry=20 --spider -S $ONE_PET_SITE -o /dev/stdout 2>/dev/null | grep '200 OK'`" != "" ]
 
 echo 'echo' >> /tmp/petget-proc/petget_urltest
 echo "wget -t 2 -T 20 --waitretry=20 --spider -S $URL_TEST" >> /tmp/petget-proc/petget_urltest
 
done

echo 'echo "
TESTING FINISHED
Read the above, any that returned \"200 OK\" succeeded."' >>  /tmp/petget-proc/petget_urltest
echo 'echo -n "Press ENTER key to exit: "
read ENDIT'  >>  /tmp/petget-proc/petget_urltest

chmod 777 /tmp/petget-proc/petget_urltest
if [ ! -f /tmp/petget-proc/install_quietly ]; then
 rxvt -title "Puppy Package Manager: download" -bg orange \
 -fg black -e /tmp/petget-proc/petget_urltest
else
 exec /tmp/petget-proc/petget_urltest
fi

###END###
