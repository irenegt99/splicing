import pandas as pd
import os
import yaml

configfile: "config/config.yaml"
include: "../rules/helpers.py"

# read samples
samples = pd.read_csv(config['sampleCSVpath'])
samples2 = samples.loc[samples.exclude_sample_downstream_analysis != 1]

SAMPLE_NAMES = list(set(samples2['sample_name']))
BAM_SUFFIX = config['bam_suffix']
MAJIQ_DIR = get_output_dir(config['project_top_level'], config['majiq_top_level'])

# paths
ANNOTATION_DB = os.path.join(MAJIQ_DIR, "annotations", "sg.zarr")
CONFIG_TSV = os.path.join(MAJIQ_DIR, config['run_name'] + "_majiqConfig.tsv")
SJ_DIR = os.path.join(MAJIQ_DIR, "sj")
BUILDER_DB = os.path.join(MAJIQ_DIR, "builder", "sg.zarr")


# 1. Create groups.tsv with  SJ
rule create_majiq_config_file:
    input:
        config['sampleCSVpath']
    output:
        CONFIG_TSV
    run:
        df = pd.read_csv(input[0])
        df = df.loc[df.exclude_sample_downstream_analysis != 1]

        with open(output[0], "w") as f:
            f.write("group\tprefix\tsj\n")
            for _, row in df.iterrows():
                sj_path = os.path.join(SJ_DIR, row['sample_name'] + ".sj") + "/"
                f.write(f"{row['group']}\t{row['sample_name']}\t{sj_path}\n")


# 2. Convert GFF3 into anotations base
rule majiq_gff3:
    input:
        gff3 = config['gff3'],
        fasta = config['fasta']
    output:
        directory(ANNOTATION_DB) 
    params:
        outdir = lambda wildcards, output: os.path.dirname(output[0])
    shell:
        """
        mkdir -p {params.outdir}
        {config[majiq_path]} gff3 \
            --license /SAN/vyplab/transcriptomic_mad_ms_tdp43/licence/majiq_license_academic_official.lic \
            {input.gff3} \
            {output}
        """


# 3. Convert BAM to SJ per sample
rule majiq_sj:
    input:
        bam = os.path.join(config['bam_dir'], "{sample}" + BAM_SUFFIX),
        annotation = ANNOTATION_DB
    output:
        directory(os.path.join(SJ_DIR, "{sample}.sj"))
    threads: 2
    resources:
        mem_mb = 32000
    params:
        outdir = SJ_DIR
    shell:
        """
        mkdir -p {params.outdir}
        {config[majiq_path]} sj --license /SAN/vyplab/transcriptomic_mad_ms_tdp43/licence/majiq_license_academic_official.lic {input.bam} {input.annotation} {output}
        """



# 4. Run majiq build with the SJs and config.tsv
rule majiq_build:
    input:
        annotation = ANNOTATION_DB,
        config_tsv = CONFIG_TSV
    output:
        directory(BUILDER_DB)
    threads: 4
    shell:
        """
        mkdir -p $(dirname {output})
        {config[majiq_path]} build \
          --license /SAN/vyplab/transcriptomic_mad_ms_tdp43/licence/majiq_license_academic_official.lic \
          {input.annotation} \
          {output} \
          --groups-tsv {input.config_tsv}
        """