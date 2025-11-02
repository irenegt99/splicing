# splicing
Is an actualization of https://github.com/frattalab/splicing: Splicing done with MAJIQ tool version 3
**work in progress**.

*BEWARE*

Actively developing how this pipeline works - now it runs in 2 steps:

1. build
2. psi
And add annonation to the diferents events with just running a Rscript.

# Installation majiq v3

After going through several different installation methods for majiq, I found that the easiest/most reliable seems to be installing
majiq in a conda environment named "majiq". Therefore, this pipeline assumes that you have a named conda environment called "majiq", which has majiq installed in it. As of August 19 2025 - This pipeline is using `majiq v3`

https://biociphers.bitbucket.io/majiq-docs/getting-started-guide/installing.html

Transcriptome assembly will merge the bams and then 2 different transcriptome assembly tools, scallop2, and stringtie2 - and then extract the novel exons that match to significant junctions called by MAJIQ

Buyer beware, mileage may vary. 

Feel free to email/pop up any issues on the repo


# Needed files
1. Aligned, sorted, and indexed BAM files of RNA-seq. You will need .bam and .bai files for all your samples.
2. GFF3 and GTF of your species of interest
3. A formatted sample sheet, see examples and explanation below
# Get started
## Necessary R packages
If you're just going to run the build + psi workflows you will need

data.table
tidyverse
optparse
glue

Alternatively, there is an environment provided with the necessary packages

After you've installed the necessary software, snakemake, R libraries, MAJIQ itself, you will need to do 3 things to get this pipeline going

1. Set up a sample sheet
2. Edit the config/comparisons.yaml
3. Edit the config/config.yaml

## Making a sample sheet

See example data for the formating of sample sheets.
The following columns are mandatory:
sample_name,
group,
exclude_sample_downstream_analysis

exclude_sample_downstream_analysis should be present, if you want to exclude a sample it should be a 1, otherwise you can leave it blank

After these 3 critical columns, you can include as many additional columns as you like

Here is an example sample sheet where we have a het, hom, and wt of a mutant

| sample_name | group | exclude_sample_downstream_analysis | litter |
|-------------|-------|------------------------------------|--------|
| M323K_HOM_1 | mut   |                                    | one    |
| M323K_HOM_2 | mut   |                                    | two    |
| M323K_HOM_3 | mut   |                                    | three  |
| M323K_HOM_4 | mut   |                                    | four   |
| M323K_HOM_5 | mut   |                                    | five   |
| M323K_WT_1  | wt    |                                    | one    |
| M323K_WT_2  | wt    |                                    | two    |
| M323K_WT_3  | wt    |                                    | three  |

My bams are named like this:

`M323K_mut_1_unique_rg_fixed.bam`

with all bams sharing the `_unique_rg_fixed` suffix, but I don't include that in the `sample_name`.

I have three groups which I put in the group column, and then I don't have any reason to exclude any of the samples so I leave that blank as well.

*Please* use syntactic names for `sample_name` and `group` (no spaces, don't start with a number, use underscores and not hyphens) I'm not totally sure if that leads to errors, but I would guess it will.

After that, I've included a column saying which litter the mice came from, but I could include as many additional columns as I like.

*PLEASE USE SYNATIC NAMES*

That means NO hyphens and NO periods. 

`M323K_HOM_2` - GOOD
`M323K.HOM.2` - BAD


| sample_name | group | exclude_sample_downstream_analysis | litter |
|-------------|-------|------------------------------------|--------|
| M323K_MUT_1 | mutt   |                                    | 1.2    | - NO
| M323K_MUT_2 | mut   |                                    | two_2    | - YES

## Setting up your comparisons

To compare groups, we need to go int the config/comparisons.yaml and edit it

Here's an example from the sample sheet above:

```
knockdownexperiment:
  column_name:
    - group
  wt:
    - wt
  hom:
    - MUT
litterComparison:
  column_name:
    - litter
  firstLitters:
    - one
    - two
  secondLitters:
    - three
    - four
    - five
```

Make sure there is a space between the "-" and the value when you're creating the YAML or it won't be a properly formatted YAML list and the pipeline won't work.

## Making the config

# Final outputs
Underneath the folder in

`majiq_top_level: /SAN/vyplab/alb_projects/data/linked_bams_f210i_brain/majiq/`
```
majiq
├── builder
│   ├── sg.zarr
├── annotations
│   ├── sg.zarr
├── sj
│   ├── wt_sample1.sj
│   ├── wt_sample2.sj
│   ├── mut_sample1.sj
│   └── mut_sample2.sj
├── delta_psi
│   ├── wt_mut.deltapsi.tsv
│   └── wt_mut.dpsicov
├── run_name_majiqConfig.tsv
├── psi_single
│   ├── wt_sample1.psicov
│   ├── wt_sample1.voila
│   ├── wt_sample2.psicov
│   ├── wt_sample2.voila
│   ├── mut_sample1.psicov
│   ├── mut_sample1.voila
│   ├── mut_sample2.psicov
│   ├── mut_sample2.voila
└── psi
    ├── wt.psi.tsv
    ├── wt.psi.psicov
    ├── mut.psi.tsv
    └── mut.psi.psicov
```
## Submitting on SGE

1. Build step
`source submit.sh build run_name`
2. PSI step
`source submit.sh psi run_name`

with whatever run name you'd like

## Submitting on Slurm

1. Build step
`source submit_slurm.sh build run_name`
2. PSI step
`source submit_slurm.sh psi run_name`
with whatever run name you'd like
## Running without a cluster

If you don't have a cluster, you can run straight with snakemake
`snakemake -s workflows/build.smk`
`snakemake -s workflows/psi.smk`

# Add annonation to the diferents events (annotated, ambig_gene, novel_acceptor, novel_donor, novel_combo, novel exon_skip)
`Rscript add_junction_annotations_command_line.R   -d  /majiq/deltapsi/wt_mut.deltapsi.tsv     -o  /majiq/deltapsi/wt_mut_annotated_cmd    -g reference gtf (same that in the config file)`

## Annotation of splicing events
Annotation is done with a function grabbed directly from source code here:
https://github.com/dzhang32/dasper/

Please cite Dasper, Snakemake, and of course MAJIQ if you use this pipeline.
