#!/bin/bash

#
# split a file into equal partitions keeping original header row
#

if [ $# -ne 2 ]
then
    echo "Usage: npartitions filename"
    exit
fi

parts=$1
file=$2
lines=$(wc -l < ${file})
#
# calculate lines per file
#
((lpf=(lines-1)/parts))

echo "Total lines in ${file} = ${lines}"
echo "Lines per partition = ${lpf}"

#
# confirm to continue
#
read -p "Create partitions [Y/N]: " -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]
then
    #
    # continue if user input was [Yy]
    # split full file without header
    #
    tail -n +2 $file |
	split --lines=${lpf} - z_part.

    #
    # append header to each partition
    #
    for npart in z_part.*
    do head -1 $file > split_temp
       cat $npart >> split_temp
       mv -f split_temp $npart
    done

    printf "\nCombined lines in split files =\n"
    wc -l z_part*

fi

echo "Thanks for playing..."
