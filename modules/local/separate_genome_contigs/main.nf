process SEPARATE_GENOME_CONTIGS {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'nf-core/ubuntu:20.04' }"
    
    input:
    tuple val(meta), path(fai)

    output:
    tuple val(meta), path("*.txt"), emit: txts
    path "versions.yml"           , emit: versions


    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    separate_genome_contigs.sh ${fai} ${prefix}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(echo \$(bash --version | grep -Eo 'version [[:alnum:].]+' | sed 's/version //'))
    END_VERSIONS
    """
}
