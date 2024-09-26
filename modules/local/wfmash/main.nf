process WFMASH {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::wfmash=0.21.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/wfmash:0.21.0--h11f254b_0':
        'biocontainers/wfmash:0.21.0--h11f254b_0' }"

    input:
    tuple val(meta), path(ref_fasta_gz), path(query_fasta_gz), path(query_list_txt), path(paf), path(gzi), path(fai)

    output:
    tuple val(meta), path("*.paf"), emit: paf
    path "versions.yml"           , emit: versions


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def paf_tag = paf ? "." + paf.baseName.split("\\.")[-1] : ""
    def query_list_tag = query_list_txt ? "." + query_list_txt.baseName.split("\\.")[-1] : ""
    def prefix = task.ext.prefix ? task.ext.prefix : "${meta.id}" + paf_tag + query_list_tag
    def reference = ref_fasta_gz ? "${ref_fasta_gz}" : ""
    def query_list = query_list_txt ? "--query-list ${query_list_txt}" : ""
    def paf_mappings = paf ? "--input-paf ${paf}" : ""
    """
    wfmash \\
        $reference \\
        ${query_fasta_gz} \\
        $query_list \\
        --threads $task.cpus \\
        $paf_mappings \\
        $args > ${prefix}.paf


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wfmash: \$(echo \$(wfmash --version 2>&1) | cut -f 1 -d '-' | cut -f 2 -d 'v')
    END_VERSIONS
    """
}
