import pandas as pd
import os
import subprocess
import yaml

configfile: "config/config.yaml"

include: "../rules/helpers.py"

#reading in the samples and dropping the samples to be excluded in order to get a list of sample names

samples = pd.read_csv(config['sampleCSVpath'])
samples2 = samples.loc[samples.exclude_sample_downstream_analysis != 1]
SAMPLE_NAMES = list(set(samples2['sample_name'] + config['bam_suffix']))
SAMPLE_NAMES_NOPERIODS = list(set(samples2['sample_name']))
SJ_NAMES  = list(set(samples2['sample_name']))
print(SAMPLE_NAMES)
GROUPS = list(set(samples2['group']))

BASES, CONTRASTS = return_bases_and_contrasts()
MAJIQ_DIR = get_output_dir(config['project_top_level'], config['majiq_top_level'])
CONTRAST_PAIRS = return_comparison_pairs()

rule allAnnotations:
    input:
        [os.path.join(MAJIQ_DIR,"psi_voila_tsv_single", f"{s}_parsed.csv") for s in SAMPLE_NAMES],
        [os.path.join(MAJIQ_DIR,"psi_voila_tsv", f"{g}_parsed.csv") for g in GROUPS],
        [os.path.join(MAJIQ_DIR,"delta_psi_voila_tsv", f"{b}-{c}_parsed_psi.tsv") for b,c in CONTRAST_PAIRS],
        [os.path.join(MAJIQ_DIR,"delta_psi_voila_tsv", f"{b}-{c}_annotated_junctions.csv") for b,c in CONTRAST_PAIRS],
        [os.path.join(MAJIQ_DIR,"delta_psi_voila_tsv", f"{b}-{c}_annotated.junctions.bed") for b,c in CONTRAST_PAIRS]
        

# include: "../rules/majiq_modulizer.smk"
include: "../rules/majiq_parse_deltas.smk"
include: "../rules/majiq_annotate_junctions.smk"
