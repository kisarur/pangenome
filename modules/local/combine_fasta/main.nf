process COMBINE_FASTA {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'nf-core/ubuntu:20.04' }"
    
    input:
    tuple val(meta), path(ref_fasta_gz), path(genomes_fasta_gz)

    output:
    tuple val(meta), path("*.gz"), emit: fasta_gz
    path "versions.yml"          , emit: versions

    script:
    def prefix = task.ext.prefix ? task.ext.prefix : ref_fasta_gz.baseName.split("\\.")[0] + "." + genomes_fasta_gz.baseName.split("\\.")[0]
    """
    cat ${ref_fasta_gz} ${genomes_fasta_gz} > ${prefix}.fa.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(echo \$(bash --version | grep -Eo 'version [[:alnum:].]+' | sed 's/version //'))
    END_VERSIONS
    """
}