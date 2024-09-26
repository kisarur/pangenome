process COLLECT_UNMAPPED_CONTIGS {
    tag "$meta.id"
    label 'process_single'
    
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'nf-core/ubuntu:20.04' }"
    
    input:
    tuple val(meta), val(sample_contigs), val(mappings_paf)

    output:
    path("*.unmapped.txt"), emit: unmapped_contigs
    path "versions.yml"   , emit: versions


    script:
    def prefix = task.ext.prefix ?: ""
    """
    collect_unmapped_contigs.sh "${sample_contigs}" "${mappings_paf}" "${prefix}"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(echo \$(bash --version | grep -Eo 'version [[:alnum:].]+' | sed 's/version //'))
    END_VERSIONS
    """
}
