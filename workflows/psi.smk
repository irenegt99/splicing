import pandas as pd
import os
import yaml

configfile: "config/config.yaml"
include: "../rules/helpers.py"

samples = pd.read_csv(config['sampleCSVpath'])
samples2 = samples.loc[samples.exclude_sample_downstream_analysis != 1]
SAMPLE_NAMES_NOPERIODS = list(set(samples2['sample_name']))
GROUPS = list(set(samples2['group']))

BASES, CONTRASTS = return_bases_and_contrasts()
MAJIQ_DIR = get_output_dir(config['project_top_level'], config['majiq_top_level'])
CONTRAST_PAIRS = return_comparison_pairs()

rule psioutput:
    input:
        [os.path.join(MAJIQ_DIR, "deltapsi", f"{b}-{c}.tsv") for b, c in CONTRAST_PAIRS],
        expand(os.path.join(MAJIQ_DIR, "psi", "{group}.tsv"), group=GROUPS),
        expand(os.path.join(MAJIQ_DIR, "psi_single", "{sample}" + config['bam_suffix'] + ".tsv"), sample=SAMPLE_NAMES_NOPERIODS)


# incluir las reglas principales de MAJIQ PSI adaptadas a v3
include: "../rules/majiq_psi.smk"

