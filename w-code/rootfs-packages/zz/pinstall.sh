
#w-code/_00build.conf
#the PTHEME variable con be specified in build.conf
if [ "$PTHEME" != "" ] ; then
	theme="$PTHEME"
fi

if [ ! -f usr/share/ptheme/globals/"${theme}" ];then
	echo "Invalid theme: $theme - Dark_Blue"
	theme="Dark_Blue"
fi
