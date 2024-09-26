//
// Run the Reference-based Community pipeline
//

include { WFMASH as WFMASH_MAP_REFERENCE_BASED_COMMUNITY            } from '../../modules/local/wfmash/main'
include { WFMASH as WFMASH_UNMAPPED_REMAP_REFERENCE_BASED_COMMUNITY } from '../../modules/local/wfmash/main'

include { SEPARATE_GENOME_CONTIGS         } from '../../modules/local/separate_genome_contigs/main'
include { COLLECT_UNMAPPED_CONTIGS        } from '../../modules/local/collect_unmapped_contigs/main'
include { COLLECT_RESCUE_PAFS             } from '../../modules/local/collect_rescue_pafs/main'
include { COMBINE_PAF                     } from '../../modules/local/combine_paf/main'
include { SEPARATE_CHROMOSOME_COMMUNITIES } from '../../modules/local/separate_chromosome_communities/main'
include { COMBINE_FASTA                   } from '../../modules/local/combine_fasta/main'
include { EXTRACT_COMMUNITIES             } from '../../modules/local/extract_communities/main'
include { TABIX_BGZIP                     } from '../../modules/nf-core/tabix/bgzip/main'
include { SAMTOOLS_FAIDX                  } from '../../modules/nf-core/samtools/faidx/main.nf'

workflow REFERENCE_BASED_COMMUNITY {
    take:
    references_fasta // file: /path/to/references.fasta
    references_fai   // file: /path/to/references.fai
    genomes_fasta    // file: /path/to/sequences.fasta
    genomes_fai      // file: /path/to/sequences.fasta.fai
    genomes_gzi      // file: /path/to/sequences.fasta.gzi

    main:

    ch_versions = Channel.empty() // we collect all versions here

    // combine the reference and genomes fasta channels (explicit conversion to value channel using .first() was needed to fix a bug occured when reusing them in processes below)
    ch_ref_and_genomes = references_fasta.join(genomes_fasta).first() 

    SEPARATE_GENOME_CONTIGS(genomes_fai)
    ch_versions = ch_versions.mix(SEPARATE_GENOME_CONTIGS.out.versions)

    ch_wfmash_map = ch_ref_and_genomes.join(genomes_gzi).join(genomes_fai)
    ch_wfmash_map = ch_wfmash_map.combine(SEPARATE_GENOME_CONTIGS.out.txts.transpose(), by:0)
    ch_wfmash_map = ch_wfmash_map.map{meta, references_fasta, genomes_fasta, genomes_gzi, genomes_fai, genome_regions_txt -> [ [ id: genome_regions_txt.baseName ], references_fasta, genomes_fasta, genome_regions_txt, [], genomes_gzi, genomes_fai ]}
    WFMASH_MAP_REFERENCE_BASED_COMMUNITY(ch_wfmash_map)
    ch_versions = ch_versions.mix(WFMASH_MAP_REFERENCE_BASED_COMMUNITY.out.versions)

    ch_collect_unmapped_contigs = SEPARATE_GENOME_CONTIGS.out.txts.transpose().map{meta, genome_regions_txt -> [ [ id: genome_regions_txt.baseName ], genome_regions_txt ]}
    ch_collect_unmapped_contigs = ch_collect_unmapped_contigs.join(WFMASH_MAP_REFERENCE_BASED_COMMUNITY.out.paf)
    ch_collect_unmapped_contigs = ch_collect_unmapped_contigs.map{meta, genome_regions_txt, mappings_paf -> [ [ id: meta.id.split("\\.gz")[0] + ".gz" ], genome_regions_txt, mappings_paf ]}.groupTuple().collect()
    COLLECT_UNMAPPED_CONTIGS(ch_collect_unmapped_contigs)
    ch_versions = ch_versions.mix(COLLECT_UNMAPPED_CONTIGS.out.versions)

    ch_wfmash_unmapped_remap =  ch_ref_and_genomes.join(genomes_gzi).join(genomes_fai)
    ch_wfmash_unmapped_remap = ch_wfmash_unmapped_remap.combine(COLLECT_UNMAPPED_CONTIGS.out.unmapped_contigs.flatten().filter{file(it).size() > 0})
    ch_wfmash_unmapped_remap = ch_wfmash_unmapped_remap.map{meta, references_fasta, genomes_fasta, genomes_gzi, genomes_fai, genome_regions_txt -> [ [ id: genome_regions_txt.baseName ], references_fasta, genomes_fasta, genome_regions_txt, [], genomes_gzi, genomes_fai ]}
    WFMASH_UNMAPPED_REMAP_REFERENCE_BASED_COMMUNITY(ch_wfmash_unmapped_remap)
    ch_versions = ch_versions.mix(WFMASH_UNMAPPED_REMAP_REFERENCE_BASED_COMMUNITY.out.versions)

    ch_collect_rescue_pafs = WFMASH_UNMAPPED_REMAP_REFERENCE_BASED_COMMUNITY.out.paf.map{meta, mappings_paf -> [ [ id: meta.id.split("\\.gz")[0] + ".gz" ], mappings_paf ]}.groupTuple()
    COLLECT_RESCUE_PAFS(ch_collect_rescue_pafs)
    ch_versions = ch_versions.mix(COLLECT_RESCUE_PAFS.out.versions)

    ch_combine_paf = WFMASH_MAP_REFERENCE_BASED_COMMUNITY.out.paf.map{meta, mappings_paf -> [ [ id: meta.id.split("\\.gz")[0] + ".gz" ], mappings_paf ]}.groupTuple()
    ch_combine_paf = ch_combine_paf.mix(COLLECT_RESCUE_PAFS.out.rescue_pafs.map{ meta, rescue_pafs -> 
        def non_empty_rescue_pafs = rescue_pafs.findAll{rescue_paf ->
            file(rescue_paf).size() > 0 
        }
        return [meta, non_empty_rescue_pafs] 
    }).groupTuple().map{meta, pafs -> [ meta, pafs.flatten() ]}
    COMBINE_PAF(ch_combine_paf)
    ch_versions = ch_versions.mix(COMBINE_PAF.out.versions)

    ch_separate_chromosome_communities = COMBINE_PAF.out.paf.join(references_fai)
    SEPARATE_CHROMOSOME_COMMUNITIES(ch_separate_chromosome_communities)
    ch_versions = ch_versions.mix(SEPARATE_CHROMOSOME_COMMUNITIES.out.versions)

    COMBINE_FASTA(ch_ref_and_genomes)
    ch_versions = ch_versions.mix(COMBINE_FASTA.out.versions)

    ch_txt_communities = COMBINE_FASTA.out.fasta_gz.combine(SEPARATE_CHROMOSOME_COMMUNITIES.out.communities.flatten().filter{file(it).size() > 0})
    ch_txt_communities = ch_txt_communities.map{meta, fasta, community -> [ [ id: community.baseName.split("//.")[-1] ], fasta, community ]}
    EXTRACT_COMMUNITIES(ch_txt_communities)
    ch_versions = ch_versions.mix(EXTRACT_COMMUNITIES.out.versions)

    TABIX_BGZIP(EXTRACT_COMMUNITIES.out.community_fasta)
    ch_versions = ch_versions.mix(TABIX_BGZIP.out.versions)

    SAMTOOLS_FAIDX(TABIX_BGZIP.out.output, [[],[]])
    ch_versions = ch_versions.mix(SAMTOOLS_FAIDX.out.versions)

    emit:
    fasta_gz = TABIX_BGZIP.out.output  // channel: [ val(meta), [ fasta.gz ] ]
    gzi = SAMTOOLS_FAIDX.out.gzi       // channel: [ val(meta), [ fasta.gz.gzi ] ]
    fai = SAMTOOLS_FAIDX.out.fai       // channel: [ val(meta), [ fasta.gz.fai ] ]
    versions = ch_versions             // channel: [ versions.yml ]
}
