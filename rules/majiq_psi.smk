import pandas as pd
import os
import yaml

configfile: "config/config.yaml"
include: "helpers.py"

samples = pd.read_csv(config['sampleCSVpath'])
samples2 = samples.loc[samples.exclude_sample_downstream_analysis != 1]
SAMPLE_NAMES_NOPERIODS = list(set(samples2['sample_name']))
GROUPS = list(set(samples2['group']))

BASES, CONTRASTS = return_bases_and_contrasts()
MAJIQ_DIR = get_output_dir(config['project_top_level'], config['majiq_top_level'])

ANNOTATION_DB = os.path.join(MAJIQ_DIR, "builder", "sg.zarr")
CONTRAST_PAIRS = return_comparison_pairs()

rule allPSI:
    input:
        # comparaciones explícitas del YAML (7 en tu caso)
        [
            os.path.join(MAJIQ_DIR, "deltapsi", f"{b}-{c}.tsv")
            for b, c in CONTRAST_PAIRS
        ],
        # outputs por grupo
        expand(os.path.join(MAJIQ_DIR, "psi", "{group}.tsv"), group=GROUPS),
        # outputs por muestra
        expand(
            os.path.join(MAJIQ_DIR, "psi_single", "{sample}" + config['bam_suffix'] + ".tsv"),
            sample=SAMPLE_NAMES_NOPERIODS
        )


# PSI per grup
rule majiq_psi_group:
    input:
        annotation = ANNOTATION_DB,
        sjs = lambda wildcards: [os.path.join(MAJIQ_DIR, "sj", s + "/") for s in majiq_files_by_group(wildcards.group)]
    output:
        psicov = directory(os.path.join(MAJIQ_DIR, "psi", "{group}.psicov")),
        tsv = os.path.join(MAJIQ_DIR, "psi", "{group}.tsv")
    threads: 8
    params:
        majiq_path = config['majiq_path']
    shell:
        """
        mkdir -p $(dirname {output.psicov})
        {params.majiq_path} psi-coverage {input.annotation} {output.psicov} {input.sjs}
        {params.majiq_path} quantify {output.psicov} --splicegraph {input.annotation} --output-tsv {output.tsv} --overwrite
        """

# PSI per sample
rule majiq_single_psi:
    input:
        annotation = ANNOTATION_DB,
        sj = lambda wildcards: os.path.join(MAJIQ_DIR, "sj", wildcards.sample + ".sj/")
    output:
        psicov = directory(os.path.join(MAJIQ_DIR, "psi_single", "{sample}" + config['bam_suffix'] + ".psicov")),
        tsv = os.path.join(MAJIQ_DIR, "psi_single", "{sample}" + config['bam_suffix'] + ".tsv")
    threads: 4
    params:
        majiq_path = config['majiq_path']
    shell:
        """
        mkdir -p $(dirname {output.psicov})
        {params.majiq_path} psi-coverage {input.annotation} {output.psicov} {input.sj}
        {params.majiq_path} quantify {output.psicov} --splicegraph {input.annotation} --output-tsv {output.tsv} --overwrite
        """

# ΔPSI between grups
rule majiq_delta_psi:
    input:
        annotation = ANNOTATION_DB,
        psi1 = lambda wildcards: os.path.join(MAJIQ_DIR, "psi", wildcards.bse + ".psicov"),
        psi2 = lambda wildcards: os.path.join(MAJIQ_DIR, "psi", wildcards.contrast + ".psicov")
    output:
        voila = directory(os.path.join(MAJIQ_DIR, "deltapsi", "{bse}-{contrast}.dpsicov")),
        tsv = os.path.join(MAJIQ_DIR, "deltapsi", "{bse}-{contrast}.tsv")
    threads: 8
    params:
        majiq_path = config['majiq_path']
    shell:
        """
        mkdir -p $(dirname {output.tsv})
        {params.majiq_path} deltapsi --splicegraph {input.annotation} \
            --output-voila {output.voila} --output-tsv {output.tsv} \
            -psi1 {input.psi1} -psi2 {input.psi2}
        """