
## Align sequences to reference genome
rule bwa_map_refgenome:
    input:
        config["ref_genome"],
        [rules.repeatmasker_good.output.original_filt]
    output:
        "refgenomefilter/{sample}_mapped_{n}.bam"
    log:
        "logs/{sample}_bwa_map_refgenome_{n}.log"
    threads: 8
    conda:
      "../envs/bwa-sam-bed.yml"
    shell:
        "(bwa mem -L 100,100 -k 15 -t {threads} {input} | "
        "samtools view -Sb - > {output}) 2> {log}"

## Extract unmapped reads
rule refgenome_unmapped:
    input: rules.bwa_map_refgenome.output
    output:
      bam = "refgenomefilter/{sample}_refgenome_unmapped_{n}.bam",
      fq = "refgenomefilter/{sample}_refgenome_unmapped_{n}.fq",
      fa = "refgenomefilter/{sample}_refgenome_unmapped_{n}.fa"
    conda:
      "../envs/bwa-sam-bed.yml"
    shell:
      """
        samtools view -b -f 4 {input} > {output.bam}
        bedtools bamtofastq -i {output.bam} -fq {output.fq}
        cat {output.fq} | sed -n '1~4s/^@/>/p;2~4p' > {output.fa}
      """

## Subset repeatmasker masked reads using unmapped ids
rule refgenome_unmapped_masked:
    input: rules.refgenome_unmapped.output.fa, rules.repeatmasker_good.output.masked_filt
    output:
      "refgenomefilter/{sample}_refgenome_unmapped_{n}_masked.fa"
    conda:
      "../envs/biopython.yml"
    script:
      "../scripts/unmapped_masked_ids.py"

## MegaBlast against reference genome to remove host sequences
rule megablast_refgenome:
    input:
      db = config["ref_genome"],
      query = rules.refgenome_unmapped_masked.output
    output:
      out = "refgenomefilter/{sample}_megablast_{n}.tsv"
    params:
      task = "megablast",
      perc_identity = config["megablast_ref_genome"]["perc_identity"],
      evalue = config["megablast_ref_genome"]["evalue"],
      word_size = config["megablast_ref_genome"]["word_size"],
      max_hsps = config["blastn_virus"]["max_hsps"],
      show_gis = True,
      num_threads = 8,
      outfmt = "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore"
    conda:
      "../envs/biopython.yml"
    script:
      "../scripts/blast.py"

## Filter megablast records for the cutoff value
rule parse_megablast:
    input:
      rules.megablast_refgenome.output.out,
      rules.refgenome_unmapped_masked.output
    output:
      known_host = "refgenomefilter/{sample}_refgenome_filtered_{n}_known-host.xml",
      unmapped = "refgenomefilter/{sample}_refgenome_filtered_{n}_unmapped.fa"
    params:
      e_cutoff = 1e-10
    conda:
      "../envs/biopython.yml"
    script:
      "../scripts/parse_blast.py"
