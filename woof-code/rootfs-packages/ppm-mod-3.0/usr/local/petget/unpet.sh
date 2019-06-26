#!/bin/bash

export TEXTDOMAIN=petget___ui_Ziggy
export OUTPUT_CHARSET=UTF-8

ALLITEM='' ; ALLSTOCK='' ; CATHEIGHT='100' ; WINHEIGHT='380'
if [ "$ALLCATEGORY" != "" ];then
 ALLITEM="<item stock=\"gtk-ALL\">$(gettext 'ALL')</item>"
 ALLSTOCK='stock["gtk-ALL"] = {{ "pet24.png", *, *, *}}'
 CATHEIGHT='112'
 WINHEIGHT='388'
fi

APPICONXMLINSERT=' icon-column="1"' #120811 each line is format: abiword0-1.2.3|subcategory|description of abiword|stuff

#120224 handle translated help.htm
LANG1="${LANG%_*}" #ex: de
HELPFILE="/usr/local/petget/help.htm"
[ -f /usr/local/petget/help-${LANG1}.htm ] && HELPFILE="/usr/local/petget/help-${LANG1}.htm"

mkdir -p /tmp/petget-proc
[ ! -d /tmp/petget-proc/petget ] && mkdir /tmp/petget-proc/petget

GTKDIALOG=gtkdialog

MAIN_DIALOG='<window title="'$(gettext 'Uninstall Puppy Package')'" icon-name="application-pet" default_height="380" default_width="450">
 <vbox>
  <text><label>'$(gettext 'Click on an item in the list to uninstall package')'</label></text>  
  <tree>
    <label>'$(gettext 'Installed Package|Description')'</label>
    <variable>TREE2</variable>
    <input>/usr/local/petget/finduserinstalledpkgs.sh</input>
    <input'${APPICONXMLINSERT}'>cat /tmp/petget-proc/petget/installedpkgs.results.post | grep "|"</input>
    <action signal="button-release-event">/usr/local/petget/removepreview.sh</action>
    <action signal="button-release-event">/usr/local/petget/finduserinstalledpkgs.sh</action>
    <action signal="button-release-event">refresh:TREE2</action>
  </tree>
  <hbox>
   <button tooltip-text="'$(gettext 'Remove SFS files')'">
    <label>'$(gettext 'Uninstall SFS'"'"'s')'</label>
    <input file icon="squashfs-image"></input>
    <action>sfs_load&</action>
   </button>
   <button tooltip-text="'$(gettext 'Remove Built in Packages')'">
    <label>'$(gettext 'Remove Built in Packages')'</label>
    <input file icon="zen-icon"></input>
    <action>/usr/sbin/remove_builtin&</action>
   </button>
   <button tooltip-text="'$(gettext 'Open Puppy Package Manager')'">
    <label>'$(gettext 'Package Manager')'</label>
    <input file icon="application-pet"></input>
    <action>/usr/local/petget/pkg_chooser.sh&</action>
   </button>
   <button cancel></button>
   </hbox>
  </vbox>
</window>' 

export MAIN_DIALOG

case $1 in
	-d | --dump) echo "$MAIN_DIALOG" ;;
	*) $GTKDIALOG --program=MAIN_DIALOG ;;
esac
