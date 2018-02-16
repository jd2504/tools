#!/bin/bash

if [ $# -ne 3 ]
then
    echo "Usage: yyyy-mm-dd fieldnum file"
    exit
fi

date=$1
fieldnum=$2
file=$3

#
# if delim != \t : delete commas between double quotes
#
## awk -F'"' -v OFS='' '{ for (i=2; i<=NF; i+=2) gsub(",", "", $i) } 1' $file

#
# reformat date values as yyyy-mm-dd
#
sed 1q $file
sed -r '1d
s;([0-9]{2})/([0-9]{2})/([0-9]{4});\3-\1-\2;g' $file |
awk '-F	' '$'$fieldnum' >= "'"$date"'"'
