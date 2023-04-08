#!/bin/sh
# Verions:
# https://aur.archlinux.org/cgit/aur.git/log/PKGBUILD?h=freeoffice
# https://aur.archlinux.org/packages/freeoffice
#
# http://cdn02.foxitsoftware.com/pub/foxit/reader/desktop/linux/1.x/1.1/enu/FoxitReader_1.1.0_i386.deb
#

help() {
    echo "create SFS of softmaker freeoffice
usage:

    $0 <32|64>
"
    exit
}

S_COMP="-comp gzip" #xz gzip lzo lz4

OUTPUT_DIR=$(pwd)/output
. ./0common_functions.sh

if [ -d /opt/wfonts ] && [ -d /opt/softmaker/wspell ] ; then
	# have stuff in wdata
	WCLEANUP=1
	echo "## WCLEANUP enabled ##"
fi

mkdir -p tmp_softmaker
cd tmp_softmaker

case ${1} in
	32|i686)
		# freeoffice 2018
		# 982 is the last i686 version
		VER=982
		TAR2='freeoffice2018.tar.lzma'
		MIME_XML='softmaker-freeoffice18.xml'
		URL=http://www.softmaker.net/down/softmaker-freeoffice-${VER}-i386.tgz
		ARCH=i686
		;;
	64|x86_64)
		# freeoffice 2021 -- supported, receives updates
		VER=1062
		TAR2='freeoffice2021.tar.lzma'
		URL=http://www.softmaker.net/down/softmaker-freeoffice-2021-${VER}-amd64.tgz
		MIME_XML='softmaker-freeoffice21.xml'
		ARCH=x86_64
		;;
	*)
		help
		;;
esac


#============================================================================

common_dl_file ${URL}
CWD=$(pwd)
set -x

pkgdir=office_softmaker-office-${VER}-${ARCH}
OFFICE_DIR=${pkgdir}/opt/softmaker/freeoffice-${VER}

if [ ! -d "${pkgdir}" ] ; then
	mkdir -p ${pkgdir}/opt/softmaker/freeoffice-${VER}
	ln -snfv freeoffice-${VER} ${pkgdir}/opt/softmaker/office
	if [ -n "$KEY" ] ; then
		echo "$KEY" > ${pkgdir}/opt/softmaker/freeoffice-${VER}-key.txt
	fi

	tar -xf $(basename ${URL})    || exit 1
	tar -C ${pkgdir}/opt/softmaker/freeoffice-${VER} -xf ${TAR2} || exit 1
fi


mkdir -p ${pkgdir}/usr/bin
mkdir -p ${pkgdir}/usr/share/pixmaps
mkdir -p ${pkgdir}/usr/share/applications
mkdir -p ${pkgdir}/usr/share/mime/packages

cp -fv ${OFFICE_DIR}/icons/pml_64.png ${pkgdir}/usr/share/pixmaps/planmaker.png
cp -fv ${OFFICE_DIR}/icons/prl_64.png ${pkgdir}/usr/share/pixmaps/presentations.png
cp -fv ${OFFICE_DIR}/icons/tml_64.png ${pkgdir}/usr/share/pixmaps/textmaker.png

sed -i '/xml:lang/d' ${OFFICE_DIR}/mime/${MIME_XML}
sed -i '/icon /d' ${OFFICE_DIR}/mime/${MIME_XML}
cp -fv ${OFFICE_DIR}/mime/${MIME_XML} ${pkgdir}/usr/share/mime/packages


if [ "$WCLEANUP" ] ; then
	# subshell
	(
	cd ${pkgdir}/opt/softmaker/freeoffice-${VER}
	#rm -rf mime
	#rm -rf icons

	exceptions='_en|_es|_us'

	find . -name 'html_*' | grep -v -E ${exceptions} | \
		while read i ; do rm -rf $i ; done

	find . -name 'planmaker_*' | grep -v -E ${exceptions} | \
		while read i ; do rm -rf $i ; done

	find . -name 'presentations_*' | grep -v -E ${exceptions} | \
		while read i ; do rm -rf $i ; done

	find . -name 'textmaker_*' | grep -v -E ${exceptions} | \
		while read i ; do rm -rf $i ; done

	find . -name '*_de.pdf' | \
		while read i ; do rm -rf $i ; done

	find . -name '*.pdf' -delete

	rm -rf inst

	rm -rf fonts
	ln -sv /opt/wfonts fonts

	rm -rf spell
	ln -sv /opt/softmaker/wspell spell
	)
fi

cat > ${pkgdir}/usr/share/applications/planmaker.desktop <<EOF
[Desktop Entry]
Encoding=UTF-8
Type=Application
GenericName=Spreadsheet
Comment=PlanMaker lets you create all kinds of spreadsheets
Terminal=false
Categories=WordProcessor
MimeType=application/x-pmd;application/x-pmdx;application/x-pmv;application/excel;application/x-excel;application/x-ms-excel;application/x-msexcel;application/x-sylk;application/x-xls;application/xls;application/vnd.ms-excel;application/vnd.stardivision.calc;application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;application/vnd.openxmlformats-officedocument.spreadsheetml.template;application/vnd.ms-excel.sheet.macroenabled.12;application/vnd.ms-excel.sheet.macroEnabled.12;application/vnd.openxmlformats-officedocument.spreadsheetml.template;application/vnd.ms-excel.template.macroenabled.12;application/vnd.ms-excel.template.macroEnabled.12;text/csv;application/x-dbf;application/x-dif;application/x-prn;application/vnd.stardivision.calc;text/spreadsheet;application/x-pagemaker;
Version=1.0
Name=Office PlanMaker (Excel)
Icon=planmaker.png
TryExec=planmaker
Exec=planmaker
EOF

cat > ${pkgdir}/usr/share/applications/textmaker.desktop <<EOF
[Desktop Entry]
Encoding=UTF-8
Type=Application
GenericName=Word Processor
Comment=The TextMaker word processor
Terminal=false
Categories=WordProcessor
MimeType=application/x-tmd;application/x-tmv;application/msword;application/vnd.ms-word;application/x-doc;text/rtf;application/rtf;application/vnd.oasis.opendocument.text;application/vnd.oasis.opendocument.text-template;application/vnd.stardivision.writer;application/vnd.sun.xml.writer;application/vnd.sun.xml.writer.template;application/vnd.openxmlformats-officedocument.wordprocessingml.document;application/vnd.ms-word.document.macroenabled.12;application/vnd.ms-word.document.macroEnabled.12;application/vnd.openxmlformats-officedocument.wordprocessingml.template;application/vnd.ms-word.template.macroenabled.12;application/vnd.ms-word.template.macroEnabled.12;application/x-pocket-word;application/vnd.wordperfect;
Version=1.0
Name=Office TextMaker (Word)
Icon=textmaker.png
TryExec=textmaker
Exec=textmaker
EOF

cat > ${pkgdir}/usr/share/applications/presentations.desktop <<EOF
[Desktop Entry]
Encoding=UTF-8
Type=Application
GenericName=Presentation
Comment=The Presentations software lets you design any kind of presentation
Terminal=false
Categories=WordProcessor
MimeType=application/x-prd;application/x-prv;application/x-prs;application/ppt;application/mspowerpoint;application/vnd.ms-powerpoint;application/vnd.openxmlformats-officedocument.presentationml.presentation;application/vnd.ms-powerpoint.presentation.macroenabled.12;application/vnd.ms-powerpoint.presentation.macroEnabled.12;application/vnd.openxmlformats-officedocument.presentationml.template;application/vnd.ms-powerpoint.template.macroenabled.12;application/vnd.ms-powerpoint.template.macroEnabled.12;application/vnd.ms-powerpoint.slideshow.macroenabled.12;application/vnd.ms-powerpoint.slideshow.macroEnabled.12;application/vnd.openxmlformats-officedocument.presentationml.slideshow;
Version=1.0
Name=Office Presentations (PowerPoint)
Icon=presentations.png
TryExec=presentations
Exec=presentations
EOF


for app in planmaker presentations textmaker
do
	(
	echo '#!/bin/sh

RD=
case $0 in ./*) # testing
	path=$(realpath "$0")
	dir=${path%/*}
	cd $dir
	RD=$(realpath ../../)
	;;
esac

exe=${RD}/opt/softmaker/office/'${app}'
'
	if [ "$app" = "presentations" ] ; then
		echo 'ext="${@##*.}"
shopt -s nocasematch
case "$ext" in
	"prs")  exec $exe -S\""$@"\";;
	"pps")  exec $exe -S\""$@"\";;
	"ppsx") exec $exe -S\""$@"\";;
	*) exec $exe "$@";;
esac'
	else
		echo 'exec $exe "$@"'
	fi
	echo
	) > ${pkgdir}/usr/bin/${app}
	chmod +x ${pkgdir}/usr/bin/${app}
done

#============================================================================

cd ${CWD}
mksquashfs ${pkgdir} ${pkgdir}.sfs ${S_COMP}
sha256sum ${pkgdir}.sfs > ${pkgdir}.sfs.sha256.txt
mv ${pkgdir}.sfs* ${OUTPUT_DIR}

