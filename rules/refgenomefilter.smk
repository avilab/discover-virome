
## Align sequences to reference genome
rule bwa_mem:
    input:
        config["ref_genome"],
        ["output/{sample}_unmaskedgood_{n}.fa"]
    output:
        "output/bwa_mem/{sample}_mapped_{n}.bam"
    log:
        "logs/{sample}_bwa_mem_{n}.log"
    threads: 8
    conda:
      "../envs/bwa-sam-bed.yml"
    shell:
        "(bwa mem -L 100,100 -k 15 -t {threads} {input} | "
        "samtools view -Sb - > {output}) 2> {log}"

## Extract unmapped reads
rule unmapped_reads:
    input: rules.bwa_mem.output
    output:
      bam = "output/{sample}_refgenome_unmapped_{n}.bam",
      fq = "output/{sample}_refgenome_unmapped_{n}.fq",
      fa = "output/{sample}_refgenome_unmapped_{n}.fa"
    conda:
      "../envs/bwa-sam-bed.yml"
    shell:
      """
        samtools view -b -f 4 {input} > {output.bam}
        bedtools bamtofastq -i {output.bam} -fq {output.fq}
        cat {output.fq} | sed -n '1~4s/^@/>/p;2~4p' > {output.fa}
      """

## Subset repeatmasker masked reads using unmapped ids
rule unmapped_masked:
    input: rules.unmapped_reads.output.fa, rules.repeatmasker_good.output.masked_filt
    output:
      "output/{sample}_refgenome_unmapped_{n}_masked.fa"
    conda:
      "../envs/biopython.yml"
    script:
      "../scripts/unmapped_masked_ids.py"

## MegaBlast against reference genome to remove host sequences
rule megablast_ref_genome:
    input:
      db = config["ref_genome"],
      query = rules.unmapped_masked.output
    output:
      out = "output/blast/{sample}_megablast_{n}.xml"
    params:
      task = "megablast",
      perc_identity = config["megablast_ref_genome"]["perc_identity"],
      evalue = config["megablast_ref_genome"]["evalue"],
      word_size = config["megablast_ref_genome"]["word_size"],
      num_descriptions = config["megablast_ref_genome"]["num_descriptions"],
      num_alignments = config["megablast_ref_genome"]["num_alignments"],
      show_gis = True,
      num_threads = 8,
      outfmt = 5
    conda:
      "../envs/biopython.yml"
    script:
      "../scripts/blast.py"

## Filter megablast records for the cutoff value
rule parse_megablast:
    input:
      rules.megablast_ref_genome.output.out,
      rules.unmapped_masked.output
    output:
      "output/{sample}_refgenome_filtered_{n}_known-host.xml",
      "output/{sample}_refgenome_filtered_{n}_unmapped.fa"
    params:
      e_cutoff = 1e-10
    conda:
      "../envs/biopython.yml"
    script:
      "../scripts/parse_blast.py"
