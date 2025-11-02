import pandas as pd
import os
import yaml

configfile: "config/config.yaml"
include: "../rules/helpers.py"

# read samples
samples = pd.read_csv(config['sampleCSVpath'])
samples2 = samples.loc[samples.exclude_sample_downstream_analysis != 1]

SAMPLE_NAMES = list(set(samples2['sample_name']))
MAJIQ_DIR = get_output_dir(config['project_top_level'], config['majiq_top_level'])

# pathways
ANNOTATION_DB = os.path.join(MAJIQ_DIR, "annotations", "sg.zarr")
CONFIG_TSV = os.path.join(MAJIQ_DIR, config['run_name'] + "_majiqConfig.tsv")
SJ_FILES = expand(os.path.join(MAJIQ_DIR, "sj", "{sample}.sj"), sample=SAMPLE_NAMES)
BUILDER_DB = os.path.join(MAJIQ_DIR, "builder", "sg.zarr")


# principal rule
rule allBuild:
    input:
        CONFIG_TSV,
        ANNOTATION_DB,
        SJ_FILES,
        BUILDER_DB


# include majiq rules
include: "../rules/majiq_build.smk"
