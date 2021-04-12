#!/bin/sh
#post-install script.
#PLinux
#assume current directory is rootfs-complete, which has the final filesystem.

. etc/DISTRO_SPECS

# if defaultbrowser = mozstart, it probably needs some automatic logic
if grep -q 'mozstart' usr/local/bin/defaultbrowser ; then
	DEFBROWSER=
	if [ -f usr/bin/firefox ] ; then
		DEFBROWSER=firefox
	elif [ -f usr/bin/seamonkey ] ; then
		DEFBROWSER=seamonkey
	elif [ -f usr/bin/palemoon ] ; then
		DEFBROWSER=palemoon
	fi
	if [ "$DEFBROWSER" ] ; then
		echo "Setting $DEFBROWSER as a potentially default web browser"
		echo '#!/bin/ash
exec '${DEFBROWSER}' "$@"
' > usr/local/bin/defaultbrowser
	fi
fi

### END ###
