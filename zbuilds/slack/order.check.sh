#!/bin/sh

(
while read i
do
	[ "$i" ] || continue
	if [ -d "$i" ] ; then
		echo $i
	fi
done < ORDER
) | sort -u > ORDER.new