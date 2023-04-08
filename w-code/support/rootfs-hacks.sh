#!/bin/sh

echo
echo "Executing ${0}.."

SR=
[ "$1" ] && SR="$1" #SYSROOT

#===================================================================

# xmessage symlink
if [ -x ${SR}/usr/bin/gxmessage ] && [ ! -L ${SR}/usr/bin/xmessage ] ; then
    ln -snfv gxmessage ${SR}/usr/bin/xmessage
fi
# rxvt-unicode symlink
if [ ! -e ${SR}/usr/bin/rxvt-unicode ] && [ -f ${SR}/usr/bin/urxvt ] ; then
    ln -snfv urxvt ${SR}/usr/bin/rxvt-unicode
fi
# zenity symlink
if [ ! -L ${SR}/usr/bin/zenity ] && [ -f ${SR}/usr/bin/yad ] ; then
    ln -snfv yad ${SR}/usr/bin/zenity
fi

# disable ext4 64bit feature in /etc/mke2fs.conf
#  ...the 'wee' bootloader does not support it
if [ -f ${SR}/etc/mke2fs.conf ] ; then
    sed -i 's/64bit,//g' ${SR}/etc/mke2fs.conf
fi

# enable xorg mouse keys
for i in ${SR}/usr/share/X11/xkb/symbols/pc ${SR}/etc/X11/xkb/symbols/pc
do
    if [ -f $i ] ; then
        sed -i 's%key <NMLK>.*Num_Lock.*%key <NMLK> { [ Num_Lock, Pointer_EnableKeys ] };%' $i
        # grep 'key <NMLK>.*Num_Lock' /usr/share/X11/xkb/symbols/pc
    fi
done
# (running system, just in case)
if command -v setxkbmap &>/dev/null ; then
    setxkbmap -option keypad:pointerkeys
fi

# need a working wget
if [ -f ${SR}/etc/wgetrc ] ; then
    if ! grep -q "check_certificate = off" ${SR}/etc/wgetrc ; then
        echo "check_certificate = off
#ca_certificate = /etc/ssl/certs/ca-certificates.crt
continue = on" >> ${SR}/etc/wgetrc
    fi
fi

# need a working curl
if [ ! -f ${SR}/root/.curlrc ] ; then
    echo "-L
-k" > ${SR}/root/.curlrc
fi

# fix some apps to work without root
for i in usr/bin/xsane usr/bin/xchat usr/bin/hexchat usr/bin/amule
do
    if [ -f ${SR}/${i} ] ; then
        sed -i "s/getuid/getpid/g" ${SR}/${i}
    fi
done

# slackware doesn't have libtinfo.so.5
if [ -e ${SR}/lib/libncurses.so.5 ] && [ ! -e ${SR}/lib/libtinfo.so.5 ] ; then
    ln -sv /lib/libncurses.so.5 ${SR}/lib/libtinfo.so.5
fi
if [ -e ${SR}/lib64/libncurses.so.5 ] && [ ! -e ${SR}/lib64/libtinfo.so.5 ] ; then
    ln -sv /lib64/libncurses.so.5 ${SR}/lib64/libtinfo.so.5
fi

# remove slackware's ugly color scheme
if [ -f ${SR}/etc/dialogrc ] ; then
    rm -fv ${SR}/etc/dialogrc
fi

# w freedesktop.org.xml
if [ -f ${SR}/usr/share/mime/packages/freedesktop.org.xml-w ] ; then
    mv -fv ${SR}/usr/share/mime/packages/freedesktop.org.xml-w \
            ${SR}/usr/share/mime/packages/freedesktop.org.xml
fi

#===================================================================

if [ -f ${SR}/etc/slackware-version ] ; then
    read slack_version < ${SR}/etc/slackware-version
    if [ "$slack_version" = "Slackware 14.2+" ] ; then
        ln -snfv slackyd14.2.conf ${SR}/etc/slackyd/slacky.conf
        SLACKYD_CONF=1
    fi
    if [ -n "$SLACKYD_CONF" ] ; then
        if command -v slackyd ; then
            slackyd -f -u
        fi
    fi
fi

#===================================================================
# call other $0_hacks..

for i in ${0}_*
do
    if [ -f $i ] ; then
        ${i} "$@"
    fi
done

### END ###
