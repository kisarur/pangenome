#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <combined_paf> <references_fai> <output_prefix>"
    exit 1
fi

combined_paf=$1
references_fai=$2
output_prefix=$3

# Separate out chr1, ..., chr22, chrX, chrY contigs from combined_paf and references_fai
for i in $(seq 22; echo X; echo Y); do
    awk '$6 ~ "chr'$i'$"' "$combined_paf" | cut -f 1 | sort > "${output_prefix}.community.chr${i}.txt"
    grep -w "chr${i}" "$references_fai" | cut -f 1 | sed 's/^>//' >> "${output_prefix}.community.chr${i}.txt"
done