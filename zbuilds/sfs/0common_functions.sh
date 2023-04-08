#!/bin/sh

if [ -z "${OUTPUT_DIR}" ] ; then
	echo "ERROR: \${OUTPUT_DIR} has not been specified"
	exit 1
fi


cleanup() {
	if [ -s /tmp/dlxxmm$$ ] ; then
		rm -f $(cat /tmp/dlxxmm$$)
		rm -f /tmp/dlxxmm$$
	fi
}
trap cleanup EXIT


common_dl_file() #<url> [outfile]
{
	url=${1}
	file=${url##*/} # basename
	if [ "$2" ] ; then
		file=${2}
	fi
	if ! [ -f "$file" ] ; then
		echo $PWD/${file} > /tmp/dlxxmm$$
		if ! wget --no-check-certificate -O "$file" "$url" ; then
			rm -f "$file"
			exit 1
		fi
		sync
		rm -f /tmp/dlxxmm$$
	fi
}


common_dir2sfs () # <dir>
{
	sdir=$1
	hash='md5' # sha256
	rm -f ${sdir}.sfs
	mksquashfs ${sdir} ${sdir}.sfs ${S_COMP}
	${hash}sum ${sdir}.sfs > ${sdir}.sfs.${hash}.txt
	chown nobody ${sdir}.sfs
	chown nobody ${sdir}.sfs.${hash}.txt
	mv ${sdir}.sfs             ${OUTPUT_DIR}/
	mv ${sdir}.sfs.${hash}.txt ${OUTPUT_DIR}/
}
