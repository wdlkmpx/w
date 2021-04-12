#!/bin/bash
# compile musl static apps
# - ./build tarball to produce initrd_progs.xz
# - ./build w       to build speciall C apps
#
# compile apps at will and run:
# - ./build pet to generate individual pet pkgs
# - ./build sfs to produce big sfs packages

#set -x
if ! [ "$BUILD_CONF" ] ; then
	BUILD_CONF='./build.conf'
fi
if [ -f ${BUILD_CONF} ] ; then
	. ${BUILD_CONF}
fi

export MKFLG
export MWD=`pwd`
export TARGET_TRIPLET=

ARCH_LIST="i686 x86_64 arm aarch64"

SITE=http://musl.cc

X86_CC='i686-linux-musl-cross.tgz'
X86_64_CC='x86_64-linux-musl-cross.tgz'
ARM_CC='armv6-linux-musleabihf-cross.tgz'
ARM64_CC='aarch64-linux-musl-cross.tgz'

ARCH=`uname -m`
OS_ARCH=$ARCH

function fatal_error() { echo -e "$@" ; exit 1 ; }
function exit_error() { echo -e "$@" ; exit 1 ; }

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

case "$1" in
	pet|pets)
		dirs=$(ls -d $PWD/out_static/00_*)
		for dir in $dirs
		do
			pkgs=$(find $dir -maxdepth 2 -type d -name '*_musl_static')
			if [ -z "$pkgs" ] ; then
				continue
			fi
			for i in ${pkgs} ; do
				(
				cd $(dirname ${i})
				dir2pet -x -s -n $(basename ${i}) 1>/dev/null
				mv -f ${i}.pet ../
				)
			done
			echo "-- ${dir}/${i}.pet"
		done
		echo ; echo ; echo Finished.
		exit
		;;
	sfs)
		dirs=$(ls -d $PWD/out_static/00_*)
		for dir in $dirs
		do
			arch=$(dirname "$dir")
			arch=${arch#00_}
			echo "Creating SFS file $arch"
			pkg_dir=${dir}/static_packages-$(date "+%Y%m%d")-${arch}
			mkdir -p ${pkg_dir}
			pkgs=$(find $dir -maxdepth 2 -type d -name '*_musl_static')
			if [ -z "$pkgs" ] ; then
				continue
			fi
			for i in ${pkgs} ; do
				cp -a --remove-destination ${i}/* ${pkg_dir}/
			done
			mksquashfs ${pkg_dir} ${pkg_dir}.sfs -comp xz
			echo "Finished: ${pkg_dir}.sfs"
			echo
		done
		exit
		;;
esac

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

help_msg() {
	echo "Build static packages

Usage: 
	[0] use build.conf to automate target arch and packages to compile
	[1] [-f] $0 <-arch target> <-pkg pkg>
	[2] [-f] $0 tarball|initrd_progs
	[3] $0 -download
	[4] $0 sfs        (create sfs file of all the compiled packages - 1 sfs per arch)
	[5] $0 pets       (create pet packages of all the compiled packages)

-f: rebuild / overwrite existing packages
[1] target can be '${ARCH_LIST}', -arch & -pkg can also be 'all'
[2] produce initrd_progs-DATE.tar.xz (initrd_progs.conf)
[3] only download all source packages and cross-compilers
[4] & [5] only create packages, you have to compile them first with another command.

The compiled binaries and pacakges can be found in output_static/00_ARCH/
"
	exit
}

## defaults (other defaults are in build.conf) ##
BUILD_ALL=no
export DLD_ONLY=no

if [ -z "$1" ] && [ ! -f ${BUILD_CONF} ] ; then
	help_msg
fi

## command line ##
while [ "$1" ]
do
	case $1 in
		-download|download) PACKAGES='all' ; TARGET_ARCH='all'
		           DLD_ONLY='yes'
		           break ;;
		-p|-pkg)      BUILD_PKG="$2"      ; shift 2
			       [ "$BUILD_PKG" = "" ] && fatal_error "$0 -pkg: Specify a pkg to compile"
			       PACKAGES=${BUILD_PKG}
			       ;;
		-a|-arch)  TARGET_ARCH="$2"    ; shift 2
			       [ "$TARGET_ARCH" = "" ] && fatal_error "$0 -arch: Specify a target arch" ;;
		-h|-help|--help) help_msg ; exit ;;
		w|w_apps|c) PACKAGES='w_apps' ; TARGET_ARCH='all' ; break ;;
		release|tarball)
			if [ -f initrd_progs.conf ] ; then
				. ./initrd_progs.conf
				export INITRD_PROGS
			else
				exit_error 'initrd_progs.conf is missing'
			fi
			ipr=out_static/initrd_progs-$(date "+%Y%m%d")-static.tar.xz
			if [ "$FORCE_BUILD" = "" ] && [ -f $ipr ] ; then
				exit_error " -- File $ipr already exists\n Use -f to overwrite"
			fi
			PACKAGES=$(echo "$INITRD_PROGS"  | sed -e '/^$/d' -e '/^#.*/d' | cut -f 1 -d ':')
			TARGET_ARCH='all'
			break
			;;
		-f|f)
			export FORCE_BUILD=1
			shift
			;;
		-clean)
			echo -e "Press P and hit enter to proceed, any other combination to cancel.." ; read zz
			case $zz in p|P)
				rm -rf out_static 0sources *-linux-musl* cross-compiler* ;;
			esac
			exit
			;;
		*)
			echo "Unrecognized option: $1"
			shift
			;;
	esac
done

if [ "$BUILD_ALL" = "yes" ] ; then
	PACKAGES="all"
elif [ "$BUILD_PKG" != "" ] ; then
	PACKAGES="$BUILD_PKG"
fi

if [ "$PACKAGES" = "all" ] ; then
	if [ -d pkg2 ] ; then
		pkg2='pkg2'
	fi
	PACKAGES=$(find pkg $pkg2 -maxdepth 3 -type f -name '*.pbuild' | sed -e 's|.*/||' -e 's%\.pbuild%%' | sort)
fi

if [ -z "$1" ] && [ -z "$PACKAGES" ] ; then
	help_msg
fi

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

function create_initrd_progs_tarball()
{
	cd out_static
	echo ; echo
	pkgx=initrd_progs-$(date "+%Y%m%d")-static.tar.xz
	for arch00 in $(ls -d 00_*)
	do
		cd $arch00 || exit_error aaah
		mkdir -p bin/
		while read iprog
		do
			case $iprog in '#'*) continue ;; esac
			case $iprog in '') continue ;; esac
			pkgname=$(echo $iprog | cut -f1 -d ':')
			pkgname=${pkgname%_static}
			bins=$(echo $iprog | cut -f2 -d ':')
			pkgdir=$(ls -d pkg/${pkgname}-* | tail -1)
			if ! [ -d $pkgdir ] ; then
				exit_error
			fi
			for bin in $bins ; do
				fbin=$(find $pkgdir -type f -or -type l -name $bin -executable | head -1)
				if ! [ "$fbin" ] ; then
					exit_error "cannot find '$bin' in '$pkgdir'"
				fi
				cp -av --remove-destination ${fbin} bin/
				progs2tar+=" ${arch00}/bin/${bin}"
			done
		done <<< "$INITRD_PROGS"
		echo -----------
		cd ..
	done
	echo -e "\n\n*** Creating $pkgx"
	tar -Jcf $pkgx ${progs2tar}
	cd ..
	echo "Done."
	exit
}


#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

function setup_target_arch()
{
	#-- defaults
	case $TARGET_ARCH in
		default) TARGET_ARCH=${ARCH} ;;
		x86|i?86)TARGET_ARCH=i686    ;;
		arm64)   TARGET_ARCH=aarch64 ;;
		arm*)    TARGET_ARCH=arm     ;;
	esac
	VALID_TARGET_ARCH=no
	for a in $ARCH_LIST ; do
		if [ "$TARGET_ARCH" = "$a" ] ; then
			VALID_TARGET_ARCH=yes
			ARCH=$a
			break
		fi
	done
	if [ "$VALID_TARGET_ARCH" = "no" ] ; then
		exit_error "Cross compiler for $TARGET_ARCH is not available."
	fi
	#--
	case $ARCH in
		i*86)    CC_TARBALL=${X86_CC}    ;;
		x86_64)  CC_TARBALL=${X86_64_CC} ;;
		arm*)    CC_TARBALL=${ARM_CC}    ;;
		aarch64) CC_TARBALL=${ARM64_CC}  ;;
	esac
	export TARGET_TRIPLET=$(echo $CC_TARBALL | cut -f 1-3 -d '-')
	export XCOMPILER=${TARGET_TRIPLET}
	#--
	echo -e "\n*** Arch: $ARCH  [$TARGET_TRIPLET]"
	sleep 1.0
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

function setup_cross_compiler()
{
	mkdir -p cross-compiler
	TARBALL_DIR=$(echo ${CC_TARBALL} | cut -f 1 -d '.')
	CC_DIR=cross-compiler/${TARBALL_DIR}
	echo
	## download
	if [ ! -f "0sources/${CC_TARBALL}" ];then
		echo "Download cross compiler"
		wget -c -P 0sources ${SITE}/${CC_TARBALL}
		if [ $? -ne 0 ] ; then
			rm -rf ${CC_DIR}
			exit_error "failed to download ${CC_TARBALL}"
		fi
		[ "$DLD_ONLY" = "yes" ] && return
	else
		if [ "$DLD_ONLY" = "yes" ] ; then
			echo "Already downloaded ${CC_TARBALL}"
		fi
	fi
	## extract
	if [ ! -d "$CC_DIR" ] ; then
		tar --directory=${PWD}/cross-compiler -xaf 0sources/${CC_TARBALL}
		if [ $? -ne 0 ] ; then
			rm -rf ${CC_DIR}
			rm -fv 0sources/${CC_TARBALL}
			exit_error "failed to extract ${CC_TARBALL}"
		fi
	fi
	#--
	if [ ! -d "$CC_DIR" ] ; then
		exit_error "$CC_DIR not found"
	fi
	case $OS_ARCH in i*86)
		_gcc=$(find $CC_DIR/bin -name '*gcc' | head -1)
		if [ ! -z $_gcc ] && file $_gcc | grep '64-bit' ; then
			exit_error "\nERROR: trying to use a 64-bit (static) cross compiler in a 32-bit system"
		fi
	esac
	export OVERRIDE_ARCH=${ARCH}   # = cross compiling # see ./func
	export XPATH=${PWD}/${CC_DIR}  # = cross compiling # see ./func
	export CC_INSTALL_DIR=${XPATH} # = cross compiling # see ./func
}


function build_pkgs()
{
	rm -f .fatal
	mkdir -p out_static/00_${ARCH}/bin out_static/00_${ARCH}/log 0sources
	#--
	for pkg_sttc in ${PACKAGES}
	do
		case $pkg_sttc in ""|'#'*) continue ;; esac
		if [ -f .fatal ] ; then
			rm -f .fatal_error
			exit_error "Exiting.."
		fi
		pkg_sttc=${pkg_sttc%_static}
		pkg_sttc=${pkg_sttc}_static
		for i in ./${pkg_sttc}.pbuild pkg/${pkg_sttc}.pbuild pkg/${pkg_sttc}/${pkg_sttc}.pbuild \
			pkg2/${pkg_sttc}.pbuild pkg2/${pkg_sttc}/${pkg_sttc}.pbuild
		do
			if [ -f $i ] ; then
				pkg_dir=$(dirname $i)
			fi
		done
		cd ${pkg_dir}
		mkdir -p ${MWD}/out_static/00_${ARCH}/log
		sh ${pkg_sttc}.pbuild 2>&1 | tee ${MWD}/out_static/00_${ARCH}/log/${pkg_sttc}--build.log
		cd ${MWD}
		if [ "$DLD_ONLY" = "yes" ] ; then
			continue
		fi
	done
	rm -f .fatal
}


###############################################
#                 MAIN
###############################################

which gcc &>/dev/null || fatal_error "Install make"
which gcc &>/dev/null || fatal_error "Install gcc"

ARCHES=${TARGET_ARCH}
case $TARGET_ARCH in
	all) ARCHES=${ARCH_LIST} ;;
	"") echo -e "\nMust specify target arch: -a <arch>"
		echo "  <arch> can be one of these: $ARCH_LIST default"
		echo -e "\nSee also: $0 --help"
		exit 1 ;;
esac

for i in $ARCHES
do
	TARGET_ARCH=${i}
	setup_target_arch
	setup_cross_compiler
	build_pkgs
	cd ${MWD}
done

if [ "$INITRD_PROGS" ] ; then
	create_initrd_progs_tarball
fi

### END ###
