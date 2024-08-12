#!/usr/bin/env python3

import os
import argparse

def process_fai_file(fai_filename, output_folder):
    with open(fai_filename, 'r') as file:
        lines = file.readlines()

    genomes = {}

    # Parse the fai file
    for line in lines:
        parts = line.split('\t')
        contig_name = parts[0]
        genome_id = contig_name.split('#', 2)[:2]
        genome_id = '#'.join(genome_id) + '#'
        
        if genome_id not in genomes:
            genomes[genome_id] = []
        
        genomes[genome_id].append(contig_name)

    # Create the output folder if it doesn't exist
    os.makedirs(output_folder, exist_ok=True)

    # Create output files for each genome
    for genome_id, contigs in genomes.items():
        base_name = genome_id.replace('#', '_').rstrip('_')
        output_filename = os.path.join(output_folder, f"{base_name}.txt")
        with open(output_filename, 'w') as output_file:
            for contig in contigs:
                output_file.write(f"{contig}\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process a .fai file to generate genome-specific contig lists.')
    parser.add_argument('-input', required=True, help='Input .fai file path')
    parser.add_argument('-output', required=True, help='Output folder for the generated .txt files')
    
    args = parser.parse_args()
    
    process_fai_file(args.input, args.output)
