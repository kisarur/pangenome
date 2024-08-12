process COMBINE_PAF {
    tag "$meta.id"
    label 'process_single'

    input:
    tuple val(meta), val(pafs)

    output:
    tuple val(meta), path("*.paf"), emit: paf

    script:
    """
    cat ${pafs.join(' ')} > ${meta.id}.paf
    """
}