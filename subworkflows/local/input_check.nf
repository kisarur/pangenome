//
// Check input FASTA and prepare indices
//

include { TABIX_BGZIP                          } from '../../modules/nf-core/tabix/bgzip/main.nf'
include { TABIX_BGZIP as TABIX_BGZIP_REF       } from '../../modules/nf-core/tabix/bgzip/main.nf'
include { SAMTOOLS_FAIDX                       } from '../../modules/nf-core/samtools/faidx/main.nf'
include { SAMTOOLS_FAIDX as SAMTOOLS_FAIDX_REF } from '../../modules/nf-core/samtools/faidx/main.nf'

workflow INPUT_CHECK {
    take:
    fasta // file: /path/to/sequences.fasta
    ref_fasta

    main:

    ch_versions = Channel.empty() // we collect all versions here
    ch_fasta = Channel.empty() // final output channel for input genomes [ val(meta) , [ fasta ] ]

    fai_path = file("${params.input}.fai")
    gzi_path = file("${params.input}.gzi")

    fai = Channel.empty() // we store the .fai index here [ fai ]
    gzi = Channel.empty() // we store the .gzi index here [ gzi ]

    meta_fasta = Channel.empty() // intermediate channel where we build our [ val(meta) , [ fasta ] ]
    fasta_file_name = fasta.getName()

    if (params.input.endsWith(".gz")) {
        meta_fasta = tuple([ id:fasta_file_name ], fasta)
        // TODO We want to check, if the input file was actually compressed with bgzip with the upcoming grabix module.
        // For now we assume it was bgzip. If not WFMASH will complain instantly anyhow.
        if (!fai_path.exists() || !gzi_path.exists()) { // the assumption is that none of these files exist if only one does not exist
            SAMTOOLS_FAIDX(meta_fasta, [[],[]])
            fai = SAMTOOLS_FAIDX.out.fai
            gzi = SAMTOOLS_FAIDX.out.gzi
            ch_versions = ch_versions.mix(SAMTOOLS_FAIDX.out.versions)
        } else {
            fai = Channel.of([ [ id:fasta_file_name ], fai_path ])
            gzi = Channel.of([ [ id:fasta_file_name ], gzi_path ])
        }
        ch_fasta = meta_fasta
    } else {
        if (params.input.endsWith("fa")) {
            fasta_file_name = fasta_file_name.substring(0, fasta_file_name.length() - 3)
        } else {
            if (params.input.endswith("fasta")) {
                fasta_file_name = fasta_file_name.substring(0, fasta_file_name.length() - 6)
            } else { // we assume "fna" here
                fasta_file_name = fasta_file_name.substring(0, fasta_file_name.length() - 4)
            }
        }
        meta_fasta = tuple([ id:fasta_file_name ], fasta)
        TABIX_BGZIP(meta_fasta)
        ch_fasta = TABIX_BGZIP.out.output
        SAMTOOLS_FAIDX(ch_fasta, [[],[]])
        gzi = SAMTOOLS_FAIDX.out.gzi
        fai = SAMTOOLS_FAIDX.out.fai
        ch_versions = ch_versions.mix(SAMTOOLS_FAIDX.out.versions)
        ch_versions = ch_versions.mix(TABIX_BGZIP.out.versions)
    }

    ch_ref_fasta = Channel.empty() // final output channel for reference genomes [ val(meta) , [ ref_fasta ] ]
    ref_fai_path = file("${params.references}.fai")
    ref_fai = Channel.empty() // we store the references' .fai index here [ fai ]
    
    meta_ref_fasta = Channel.empty() // intermediate channel where we build our [ val(meta) , [ ref_fasta ] ]
    ref_fasta_file_name = ref_fasta.getName()
    
    // NOTE: we use fasta_file_name for meta id of ref_fasta and ref_fai too for easier downstream meta map handling
    if (params.references.endsWith(".gz")) {
        meta_ref_fasta = tuple([ id:fasta_file_name ], ref_fasta) 
        // TODO We want to check, if the input references file was actually compressed with bgzip with the upcoming grabix module.
        // For now we assume it was bgzip.
        if (!ref_fai_path.exists()) { 
            SAMTOOLS_FAIDX_REF(meta_ref_fasta, [[],[]])
            ref_fai = SAMTOOLS_FAIDX_REF.out.fai
            ch_versions = ch_versions.mix(SAMTOOLS_FAIDX_REF.out.versions)
        } else {
            ref_fai = Channel.of([ [ id:fasta_file_name ], ref_fai_path ]) 
        }
        ch_ref_fasta = meta_ref_fasta
    } else {
        meta_ref_fasta = tuple([ id:fasta_file_name ], ref_fasta) 
        TABIX_BGZIP_REF(meta_ref_fasta)
        ch_ref_fasta = TABIX_BGZIP_REF.out.output
        SAMTOOLS_FAIDX_REF(ch_ref_fasta, [[],[]])
        ref_fai = SAMTOOLS_FAIDX_REF.out.fai
        ch_versions = ch_versions.mix(SAMTOOLS_FAIDX_REF.out.versions)
        ch_versions = ch_versions.mix(TABIX_BGZIP_REF.out.versions)
    }

    emit:
    references_fasta = ch_ref_fasta  // channel: [ val(meta), [ ref_fasta ] ]
    references_fai = ref_fai         // channel: [ val(meta), [ ref_fasta.fai ] ]
    genomes_fasta = ch_fasta         // channel: [ val(meta), [ fasta ] ]
    genomes_fai = fai                // channel: [ val(meta), fasta.fai ]
    genomes_gzi = gzi                // channel: [ val(meta), fasta.gzi ]
    versions = ch_versions   // channel: [ versions.yml ]
}
