#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <genomes_fai> <output_prefix>"
    exit 1
fi

genomes_fai=$1
output_prefix=$2

# Process each line from the input file (first field)
cut -f1 "$genomes_fai" | while IFS= read -r line; do
    # Extract the unique genome identifier (first two fields separated by '#')
    genome=$(echo "$line" | cut -d'#' -f1,2)

    # Write the entire line to the corresponding genome file
    echo "$line" >> "${output_prefix}.${genome}.txt"
done