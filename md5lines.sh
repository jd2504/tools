#!/bin/bash

#
# return md5 hash line by line
#

if [ $# -ne 2 ]
then
    echo """
Usage: fieldnum file

Returns MD5 checksum values line by line.
Header and tab delimited assumed.
"""
    exit
fi

fieldnum=$1
file=$2

sed 1d $file |
    cut -d$'\t' -f$fieldnum |
    while read line;
    do echo -n $line|md5sum;
    done |
    awk '{ print $1 }'
