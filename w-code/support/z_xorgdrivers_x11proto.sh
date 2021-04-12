#!/bin/bash
# get all xorg input/video drivers from Packages-distro-*
# .. and paste the result in yes|xserver_xorg|...|exe,dev,doc,nls
# specially for ubuntu as it has many drivers in the Universe repo
#
# Usage:
# run
#    ./0setup
# then run this script"
#    ./support/z_xorgdrivers_x11proto.sh
#

distros='debian devuan raspbian slackware slackware64'

for i in $distros ; do
	if [ -f Packages-${i}-*-main ] ; then #ex: Packages-debian-stretch-main
		distro=${i}
		break
	fi
	if [ -f Packages-${i}-*-official ] ; then #ex: Packages-slackware-14.0-official
		distro=${i}
		break
	fi
done

case $distro in

debian|devuan|raspbian)
	echo -n 'yes|xorg_drivers|'
	# nvidia drivers require many more files
	grep -E '^xserver-xorg-input-|^xserver-xorg-video-' Packages-${distro}-* \
		| cut -f 2 -d '|' \
		| grep -v '.*-lts-.*' \
		| grep -v nvidia \
		| sort \
		| tr '\n' ',' \
		| sed 's%,$%|exe,dev,doc,nls%'
	echo
	echo -n 'yes|x11proto|'
	grep '|x11proto' Packages-${distro}-* \
		| cut -f 2 -d ':' \
		| cut -f 1 -d '_' \
		| sort \
		| tr '\n' ',' \
		| sed 's%,$%|exe,dev,doc,nls%'
	echo
	;;

slackware*)
	echo -n 'yes|xorg_drivers|'
	grep -E '^xf86-video-|^xf86-input-' Packages-${distro}-* \
		| cut -f 2 -d '|' \
		| grep -v nvidia \
		| sort \
		| tr '\n' ',' \
		| sed 's%,$%|exe,dev,doc,nls%'
	echo
	;;
esac

