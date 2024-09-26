#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <mappings_paf_list> <output_prefix>"
    exit 1
fi

mappings_paf=($(echo $1 | tr -d '[],'))
output_prefix=$2

if [ -n "$output_prefix" ]; then
    output_prefix="${output_prefix}."
fi

num_files=${#mappings_paf[@]} 

# Collect rescues from each mappings_paf 
for i in $(seq 0 $(($num_files - 1))); do
    basename=$(basename ${mappings_paf[i]} .paf)
    cat ${mappings_paf[i]} | awk '{ print $1,$11,$0 }' | tr ' ' '\t' |  sort -n -r -k 1,2 | awk '$1 != last { print; last = $1; }' > ${output_prefix}${basename}.rescue.paf
done