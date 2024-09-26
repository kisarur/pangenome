#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <sample_contigs_list> <mappings_paf_list> <output_prefix>"
    exit 1
fi

sample_contigs=($(echo $1 | tr -d '[],'))
mappings_paf=($(echo $2 | tr -d '[],'))
output_prefix=$3

if [ -n "$output_prefix" ]; then
    output_prefix="${output_prefix}."
fi

num_files=${#sample_contigs[@]} 

# Extract unmapped contigs using sample_contigs and mappings_paf 
for i in $(seq 0 $(($num_files - 1))); do
    basename=$(basename ${sample_contigs[i]} .txt)
    comm -23 <(cat ${sample_contigs[i]} | sort) <(cut -f 1 ${mappings_paf[i]} | sort) > ${output_prefix}${basename}.unmapped.txt
done