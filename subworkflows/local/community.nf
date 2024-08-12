//
// Run the Community pipeline
//

include { WFMASH as WFMASH_MAP_COMMUNITY  } from '../../modules/nf-core/wfmash/main'
include { TABIX_BGZIP                     } from '../../modules/nf-core/tabix/bgzip/main'
include { SAMTOOLS_FAIDX                  } from '../../modules/nf-core/samtools/faidx/main.nf'

include { PAF2NET             } from '../../modules/local/paf2net/main'
include { NET2COMMUNITIES     } from '../../modules/local/net2communities/main'
include { EXTRACT_COMMUNITIES } from '../../modules/local/extract_communities/main'

include { SEPARATE_GENOME_REGIONS } from '../../modules/local/separate_genome_regions/main'
include { COMBINE_PAF             } from '../../modules/local/combine_paf/main'

workflow COMMUNITY {
    take:
    fasta // file: /path/to/sequences.fasta
    fai   // file: /path/to/sequences.fasta.fai
    gzi   // file: /path/to/sequences.fasta.gzi

    main:

    ch_versions = Channel.empty() // we collect all versions here
    ch_communities = Channel.empty()

    def query_self = true

    ch_wfmash_map = fasta.map{meta, fasta -> [ meta, fasta, [] ]}
    ch_wfmash_map = ch_wfmash_map.join(gzi).join(fai)

    SEPARATE_GENOME_REGIONS(fai)
    WFMASH_MAP_COMMUNITY(ch_wfmash_map.first(), // converting ch_wfmash_map to val cause we're using wfmash v0.10.4 interface with v0.14.0 (updated interface should have query-list in the first input tuple)
                        query_self,
                        SEPARATE_GENOME_REGIONS.out.regions_txt.flatMap())
    ch_versions = ch_versions.mix(WFMASH_MAP_COMMUNITY.out.versions)
    COMBINE_PAF(WFMASH_MAP_COMMUNITY.out.paf.groupTuple())

    PAF2NET(COMBINE_PAF.out.paf)
    ch_versions = ch_versions.mix(PAF2NET.out.versions)

    NET2COMMUNITIES(PAF2NET.out.txts)
    ch_versions = ch_versions.mix(NET2COMMUNITIES.out.versions)

    ch_txt_communities = fasta.combine(NET2COMMUNITIES.out.communities.flatten())
    ch_txt_communities = ch_txt_communities.map{meta, fasta, community -> [ [ id: community.baseName.split("//.")[-1] ], fasta, community ]}

    EXTRACT_COMMUNITIES(ch_txt_communities)
    ch_versions = ch_versions.mix(EXTRACT_COMMUNITIES.out.versions)

    TABIX_BGZIP(EXTRACT_COMMUNITIES.out.community_fasta)
    ch_versions = ch_versions.mix(TABIX_BGZIP.out.versions)

    SAMTOOLS_FAIDX(TABIX_BGZIP.out.output, [[],[]])
    ch_versions = ch_versions.mix(SAMTOOLS_FAIDX.out.versions)

    emit:
    fasta_gz = TABIX_BGZIP.out.output         // channel: [ val(meta), [ fasta.gz ] ]
    gzi = SAMTOOLS_FAIDX.out.gzi
    fai = SAMTOOLS_FAIDX.out.fai
    versions = ch_versions   // channel: [ versions.yml ]
}
