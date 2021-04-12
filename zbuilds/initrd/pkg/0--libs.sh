#!/bin/sh
#
# - sourced by app_static.pbuild
# - xxx_download
# - xxx_build
# - uses functions from ../../func (already sourced by app_static.pbuild)
#
# $XPATH , $CC_INSTALL_DIR is exported by build.sh
#

# Versions:
ncurses_ver=6.2       # 2020-02-12
# libuuid, libblkid, libfdisk, etc
util_linux_ver=2.36.2 
util_linux_ver2=$(echo $util_linux_ver | cut -f 1,2 -d '.')


#==========================================================
#                       sys/queue.h
#==========================================================

lib__sys_queue_download() {
	retrieve https://raw.githubusercontent.com/ataraxialinux/netbsd-tools/master/include/sys/queue.h
}

lib__sys_queue_install() {
	if ! [ "$XPATH" ] ; then
		return 0
	fi
	if ! [ -f ${XPATH}/include/sys/queue.h ] ; then
		mkdir -p ${XPATH}/include/sys
		cp -av ${MWD}/0sources/queue.h ${XPATH}/include/sys/
	fi
	return;
}


#==========================================================
#                        NCURSES
#==========================================================

ncurses_download() {
	retrieve https://ftp.gnu.org/pub/gnu/ncurses/ncurses-${ncurses_ver}.tar.gz
}

ncurses_build() {
	if [ -f ${XPATH}/lib/libncurses.a ] ; then
		export NC_CFLAGS=$(${XPATH}/bin/ncurses6-config --cflags)
		export NC_LIBS=$(${XPATH}/bin/ncurses6-config --libs)
		export NCURSESW_CFLAGS=$NC_CFLAGS
		export NCURSESW_LIBS=$NC_LIBS
		export NCURSES_CFLAGS=$NC_CFLAGS
		export NCURSES_LIBS=$NC_LIBS
		return 0 # already done
	fi
	#--
	extract ncurses-${ncurses_ver}.tar.gz
	cd ncurses-${ncurses_ver}
	opts="--prefix=${XPATH}
--without-manpages
--without-progs
--without-tests
--disable-db-install
--without-ada
--without-gpm
--without-shared
--without-debug
--without-develop
--without-cxx
--without-cxx-binding
--disable-big-core
--disable-big-strings
"
	_configure
	_make ${MKFLG}
	_make install
	ret=$?
	cd ..
	if [ $ret -eq 0 ] ; then
		rm -rf ncurses-${ncurses_ver}
	fi
	export NC_CFLAGS=$(${XPATH}/bin/ncurses6-config --cflags)
	export NC_LIBS=$(${XPATH}/bin/ncurses6-config --libs)
	export NCURSESW_CFLAGS=$NC_CFLAGS
	export NCURSESW_LIBS=$NC_LIBS
	export NCURSES_CFLAGS=$NC_CFLAGS
	export NCURSES_LIBS=$NC_LIBS
	return $ret
}

#==========================================================
#                      UTIL-LINUX
#==========================================================

util_linux_download() {
	retrieve https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v${util_linux_ver2}/util-linux-${util_linux_ver}.tar.xz
}

util_linux_build()
{
	if [ -f ${XPATH}/lib/libblkid.a ] ; then
		return 0
	fi
	extract util-linux-${util_linux_ver}.tar.xz
	cd util-linux-${util_linux_ver}
	 # cross compiler path
	opts="--prefix=${XPATH}
--disable-all-programs
--disable-symvers
--disable-nls
--enable-libblkid
--enable-libuuid
--enable-libmount
--enable-libsmartcols
--enable-libfdisk
--without-python
--without-systemd
--without-btrfs
--without-user
--without-udev
--without-ncursesw
"
	_configure
	_make
	_make install
	rv=$?
	cd ..
	if [ $rv -eq 0 ] ; then
		rm -rf util-linux-${util_linux_ver}
	fi
	return $rv
}

