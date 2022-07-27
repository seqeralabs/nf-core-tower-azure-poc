#!/bin/bash

###################################################
## GLOBAL VARIABLES
###################################################

## TODO: Change these variables as required

WORKSPACE='<TOWER_ORGANISATION>/<TOWER_WORKSPACE>'
WORK_DIR='az://<AZURE_BUCKET>'

COMPUTE_ENVS_DIR=./compute-envs
COMPUTE_ENVS=( azure_batch_ce_east_us_d16_v3 azure_batch_ce_east_us_d32_v3 )

PIPELINES_DIR=./pipelines
PIPELINES=( hello-world nf-core-rnaseq-test nf-core-rnaseq-full-test nf-core-chipseq-test nf-core-scrnaseq-test nf-core-smrnaseq-test )

###################################################
## Import Compute Environment into Tower workspace
###################################################

# for i in "${COMPUTE_ENVS[@]}"
# do
#     if [ -f "$COMPUTE_ENVS_DIR/$i.json" ]; then
#         tw compute-envs import --workspace=$WORKSPACE --name=$i --wait='AVAILABLE' "$COMPUTE_ENVS_DIR/$i.json"
#     fi
# done

###################################################
## Export Compute Environment from Tower workspace
###################################################

# for i in "${COMPUTE_ENVS[@]}"
# do
#     tw compute-envs export --workspace=$WORKSPACE --name=$i > "$COMPUTE_ENVS_DIR/$i.json"
# done

###################################################
## Import Pipeline(s) into a Tower Workspace
###################################################

# for i in "${PIPELINES[@]}"
# do
#     if [ -f "$PIPELINES_DIR/$i.json" ]; then

#         ## Set default Compute Environment
#         COMPUTE_ENV='azure_batch_ce_east_us_d16_v3'
#         tw pipelines import --workspace=$WORKSPACE --name=$i --compute-env=$COMPUTE_ENV "$PIPELINES_DIR/$i.json"
#     fi
# done

###################################################
## Export Pipeline(s) from a Tower Workspace
###################################################

# for i in "${PIPELINES[@]}"
# do
#     tw pipelines export --workspace=$WORKSPACE --name=$i > "$PIPELINES_DIR/$i.json"
# done

###################################################
## Delete Pipeline(s) from a Tower Workspace
###################################################

# for i in "${PIPELINES[@]}"
# do
#     tw pipelines delete --workspace=$WORKSPACE --name=$i
# done

###################################################
## Launch Pipeline(s) in a Tower Workspace
###################################################

# for i in "${PIPELINES[@]}"
# do
#     tw launch --workspace=$WORKSPACE --params-file=<(echo -e "outdir: ${WORK_DIR}/$i") $i
# done

###################################################
###################################################