#!/bin/sh
# install huge kernel to build
# * called by 3builddistro
# * can be run independently
# * we're in sandbox3

. ../_00build.conf
[ -f ../_00build_2.conf ] && . ../_00build_2.conf
. ../DISTRO_SPECS

if [ -L w-code ] ; then # zwoof-next
	HUGE_KERNEL_DIR=workdir/huge_kernel
else
	HUGE_KERNEL_DIR=../huge_kernel
fi

if [ ! -d ../../local-repositories/huge_kernels ] ; then
	rm -f ../../local-repositories/huge_kernels
fi

mkdir -p ../../local-repositories/huge_kernels
mkdir -p build
[ -z $ZDRVSFS ] && ZDRVSFS="zdrv_${DISTRO_FILE_PREFIX}_${DISTRO_VERSION}.sfs"
[ -z $FDRVSFS ] && FDRVSFS="fdrv_${DISTRO_FILE_PREFIX}_${DISTRO_VERSION}.sfs"

#-----------------------------------------

echo "Installing HUGE kernel to build/"
sleep 1

#----------

mkdir -p ${HUGE_KERNEL_DIR}
IS_KERNEL=`ls ${HUGE_KERNEL_DIR}/*.tar.* 2>/dev/null | wc -l`

#==========
# functions
#==========

download_kernel() {
	local URL="$1" TARBALL="${1##*/}"
	if [ ! -f ../../local-repositories/huge_kernels/${TARBALL} ] ; then
		if [ -f ${HUGE_KERNEL_DIR}/${TARBALL} ] ; then
			cp ${HUGE_KERNEL_DIR}/${TARBALL} ../../local-repositories/huge_kernels/${TARBALL}
		fi
	fi
	../support/download_file.sh "$URL" ../../local-repositories/huge_kernels || \
		../support/download_file.sh "$URL" ../../local-repositories/huge_kernels
	[ $? -ne 0 ] && exit 1
	if [ ! -f ${HUGE_KERNEL_DIR}/${TARBALL} ] ; then
		cp ../../local-repositories/huge_kernels/${TARBALL} ${HUGE_KERNEL_DIR}/${TARBALL}
	fi
}

choose_kernel_to_download() {
	TMP=/tmp/kernels$$
	TMP2=/tmp/kernels2$$
	wget ${KERNEL_REPO_URL} -O $TMP
	if [ $? -ne 0 ] ; then
		echo "Could not get kernel list"
		echo "If you have connectivity issues (or the site is unreachable)"
		echo " place a huge kernel in the 'huge_kernel' directory"
		echo "Type A in hit enter to retry, any other key to exit"
		read zzz
		case $zzz in
			A|a) exec $0 ;;
			*) exit 1 ;;
		esac
	fi
	# grok out what kernels are available
	c=1
	cat $TMP|tr '>' ' '|tr '<' ' '|tr ' ' '\n'|grep -v 'md5'| \
		grep -v 'kernels'|grep 'huge'|grep -v 'href'|\
		while read q
		do
			echo "$c $q" >> $TMP2
			c=$(($c + 1))
		done
	while [ 1 ]
	do
		echo "Please choose the number of the kernel you wish to download"
		cat $TMP2
		read choice_k
		choice=`grep "^$choice_k " $TMP2`
		[ ! "$choice" ] && echo "invalid choice" && continue
		echo "You chose ${choice##* }."
		sleep 3
		break
	done
	download_kernel "$KERNEL_REPO_URL/${choice##* }"
	rm $TMP
	rm $TMP2
}

choose_kernel() {
	TMP=/tmp/kernels3$$
	x=1
	for j in `ls -1 ${HUGE_KERNEL_DIR}/*.tar.* 2>/dev/null |grep -v 'md5'`
	do
		echo "$x $j" >> $TMP
		x=$(($x + 1))
	done
	while [ 1 ]
	do
		echo "Please choose the number of the kernel you wish to use"
		cat $TMP
		read choice_k3
		choice3=`grep ^$choice_k3 $TMP`
		[ ! "$choice3" ] && echo "invalid choice3" && continue
		echo "You chose ${choice3##* }."
		sleep 3
		break
	done
	KERNEL_VERSION=`echo ${choice3##* } |cut -d '-' -f2-|rev|cut -d '.' -f3-|rev`
	rm $TMP
}
#==========

if [ "$IS_KERNEL" = 0 ] ; then
	#no kernel, get 1
	if [ "$KERNEL_TARBALL_URL" != "" ] ; then
		download_kernel ${KERNEL_TARBALL_URL} #build.conf
	else
		choose_kernel_to_download
	fi
fi

IS_KERNEL2=`ls ${HUGE_KERNEL_DIR}/*.tar.* 2>/dev/null | wc -l`

if [ "$IS_KERNEL2" -gt 1 ] ; then
	#too many, choose 1
	choose_kernel
elif [ "$IS_KERNEL2" == 1 ] ; then
	# 1 kernel
	# check if it was a failed/incomplete download
	# as it keeps hitting the same error everytime you
	# run 3builddistro
	if [ "$IS_KERNEL" == 1 ] ; then
		if [ "$KERNEL_TARBALL_URL" != "" ] ; then
			download_kernel ${KERNEL_TARBALL_URL} #build.conf
		else
			KERNEL_VERSION=`ls ${HUGE_KERNEL_DIR}/*.tar.* 2>/dev/null | grep -v 'md5'|cut -d '-' -f2-|rev|cut -d '.' -f3-|rev`
			download_kernel "$KERNEL_REPO_URL/$(basename ${HUGE_KERNEL_DIR}/huge-${KERNEL_VERSION}.tar.*)"
		fi
	fi
	KERNEL_VERSION=`ls ${HUGE_KERNEL_DIR}/*.tar.* 2>/dev/null | grep -v 'md5'|cut -d '-' -f2-|rev|cut -d '.' -f3-|rev`
fi

echo "Kernel is $KERNEL_VERSION version"
export KERNEL_VERSION

cp -a ${HUGE_KERNEL_DIR}/huge-${KERNEL_VERSION}.tar.* build/

cd build
tar -xvf huge-${KERNEL_VERSION}.tar.*
[ "$?" = 0 ] || exit 1
rm -f huge-${KERNEL_VERSION}.tar.* #remove pkg
mv -f kernel-modules.sfs-$KERNEL_VERSION $ZDRVSFS
mv -f vmlinuz-$KERNEL_VERSION vmlinuz
cd ..

exit 0

### END ###