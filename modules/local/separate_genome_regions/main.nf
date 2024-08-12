process SEPARATE_GENOME_REGIONS {
    tag "$meta.id"
    label 'process_single'
    
    input:
    tuple val(meta), val(fai)

    output:
    path("*.txt"), emit: regions_txt

    script:
    """
    separategenomes.py -input ${fai} -output \${PWD}
    """
}
