#!/bin/sh
#script by semme to start wirless ethernet: 
#http://murga-linux.com/puppy/viewtopic.php?p=944374#944374
#to use: mofify  /etc/network-wizard/wireless/wpa_profiles.ex.semme
# and rename to  /etc/network-wizard/wireless/wpa_profiles
ifconfig INTERFACE up
sleep 2
wpa_supplicant -i INTERFACE -D wext -c /etc/network-wizard/wireless/wpa_profiles/wpa_supplicant2.conf -dd -B
sleep 5
rm -f /var/lib/dhcpcd/*.info
rm -f /var/run/*.pid
dhcpcd -I '' -t 30 -h puppypcxxxxx -d INTERFACE