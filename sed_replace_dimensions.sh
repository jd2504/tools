#!/bin/bash

$file=$1

sed 's/(measure|dimension[_group]*): *\([a-zA-Z0-9_]*\) *{/\1: fw_\2 {/g' $1 |
    sed 's/dimension: *\([a-zA-Z0-9_]*\) *{/dimension: fw_\1 {/g' |
    sed 's/dimension_group: *\([a-zA-Z0-9_]*\) *{/dimension_group: fw_\1 {/g'
