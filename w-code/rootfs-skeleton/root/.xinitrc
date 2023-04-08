#!/bin/sh
# $Xorg: xinitrc.cpp,v 1.3 2000/08/17 19:54:30 cpqbld Exp $
#130202 xrandr set vert freq. see also /usr/sbin/quicksetup.

. /etc/rc.d/PUPSTATE

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/usr/lib/X11/xinit/Xresources
sysmodmap=/usr/lib/X11/xinit/.Xmodmap

# merge in defaults and keymaps

if [ -f $sysresources ]; then
    xrdb -merge -nocpp $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f $userresources ]; then
    xrdb -merge -nocpp $userresources
fi

if [ -f $usermodmap ]; then
    xmodmap $usermodmap
fi

CURRENTWM="`cat /etc/windowmanager`"

if [ "$CURRENTWM" = "startkde" ];then
 exec startkde
fi

if [ "$CURRENTWM" = "startxfce4" ];then
 exec startxfce4
fi

#100501 if full nvidia pkg installed, it has a gui config app...
if [ -f /root/.nvidia-settings-rc ] ; then
	nvidia-settings --load-config-only
fi

xrandrshell start

if [ -f /root/.xset.sh ];then
	#this is created by /usr/bin/pupx...
	eval "/root/.xset.sh"
else
	xset s 600 600 s blank
fi

if [ -f /usr/bin/xsetroot ] ; then
	xsetroot -cursor_name top_left_arrow
fi

sleep 2 # let the dust settle

xrandrshell start

if [ -f /etc/mousehide ];then
	IDLETIME="`cat /etc/mousehide | cut -f 1 -d ','`"
	[ ! "$IDLETIME" = "0" ] && unclutter -idle $IDLETIME &
fi

/usr/sbin/delayedrun &

echo "DISPLAY='${DISPLAY}'" > /tmp/services/x_display

exec startwde

###END###
