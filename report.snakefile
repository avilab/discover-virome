
__author__ = "Taavi Päll"
__copyright__ = "Copyright 2018, Avilab"
__email__ = "taavi.pall@ut.ee"
__license__ = "MIT"

include: "rules/common.smk"

rule all:
  input: expand("reports/{sample}_taxonomy_report.html", sample = sample_ids)

include: "rules/taxonomy.smk"
