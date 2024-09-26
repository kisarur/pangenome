process SEPARATE_CHROMOSOME_COMMUNITIES {
    tag "$meta.id"
    label 'process_single'
    
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'nf-core/ubuntu:20.04' }"
    
    input:
    tuple val(meta), path(combined_paf), path(references_fai)

    output:
    path("*.community.*.txt"), emit: communities
    path "versions.yml"      , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    separate_chromosome_communities.sh ${combined_paf} ${references_fai} ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(echo \$(bash --version | grep -Eo 'version [[:alnum:].]+' | sed 's/version //'))
    END_VERSIONS
    """
}
