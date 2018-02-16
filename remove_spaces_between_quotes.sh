#!/bin/bash

# doesn't work... fix OFS

#field=$1
file=$1

awk -F"\'" '
    /sitesectionname.*(LIKE|like|=)/
    BEGIN {
	OFS="\'";
	gsub(/[ \t]+/, "", $2);

	print $0
    } $file

echo "Thank you come again..."


# python...

#import sys

#for l in sys.stdin:
#    f = l.split("'")
#    if len(f) > 1:
#        print("%s'%s'" % (f[0], ''.join(f[1].split())))
