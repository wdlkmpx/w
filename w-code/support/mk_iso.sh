#!/bin/bash
#
# sandbox3 or $PX $BUILD
# called from 3builddistro (or build-iso.sh)

if [ -f ../_00build.conf ] ; then
	. ../_00build.conf
	if [ -f ../_00build_2.conf ] ; then
		. ../_00build_2.conf
	fi
	. ../DISTRO_SPECS
elif [ -f ./build.conf ] ; then #zwoof-next
	. ./build.conf
	. ./DISTRO_SPECS
fi

[ -z "$PX" ]    && PX=rootfs-complete
[ -z "$BUILD" ] && BUILD=build

#===================================================

ISO_BASENAME=${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${XTRA_FLG}
W_OUTPUT=../woof-output-${ISO_BASENAME}
if [ -L ../w-code ] ; then #zwoof-next
	W_OUTPUT=${W_OUTPUT#../} #use current dir
fi
[ -d $W_OUTPUT ] || mkdir -p $W_OUTPUT
OUT=${W_OUTPUT}/${ISO_BASENAME}.iso

#======================================================

# grub4dos
mkdir -p ${BUILD}/boot/grub/
cp -f ${PX}/usr/share/boot-dialog/menu.lst ${BUILD}/boot/grub/
cp -f ${PX}/usr/share/boot-dialog/menu_phelp.lst ${BUILD}/boot/grub/
cp -f ${PX}/usr/share/boot-dialog/grldr ${BUILD}/
sed -i 's%configfile.*/menu%configfile /boot/grub/menu%' ${BUILD}/boot/grub/menu*

if [ -f ${PX}/etc/os-release ] ; then
	. ${PX}/etc/os-release # need $PRETTY_NAME
else
	PRETTY_NAME="$DISTRO_NAME $DISTRO_VERSION"
fi

sed -i -e "s/DISTRO_FILE_PREFIX/${DISTRO_FILE_PREFIX}/g" \
		-e "s/DISTRO_DESC/${PRETTY_NAME}/g" \
		-e "s/#distrodesc#/${PRETTY_NAME}/g" \
		${GRUB_CFG} ${BUILD}/boot/grub/menu*

sed -i -e "s% /splash.jpg% /boot/splash.jpg%" ${GRUB_CFG} ${BUILD}/boot/grub/menu*
sed -i -e "s% /splash.png% /boot/splash.png%" ${GRUB_CFG} ${BUILD}/boot/grub/menu*

#======================================================

# build the iso
mkisofs -iso-level 4 -D -R -o $OUT \
    -b grldr -no-emul-boot -boot-load-size 4 -boot-info-table \
    -c boot/boot.catalog "$BUILD" || exit 101
sync
(
	cd $W_OUTPUT
	md5sum ${ISO_BASENAME}.iso > ${ISO_BASENAME}.iso.md5.txt
	sha256sum ${ISO_BASENAME}.iso > ${ISO_BASENAME}.iso.sha256.txt
)

### END ###
