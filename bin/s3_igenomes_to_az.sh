#!/bin/bash

## Re-create and copy S3 paths from AWS iGenomes to Azure blob storage
## https://github.com/nf-core/rnaseq/blob/89bf536ce4faa98b4d50a8ec0a0343780bc62e0a/conf/igenomes.config#L14-L22

## TODO: Change this variable to your own Azure blob directory
AZURE_BLOB_DIR='https://<AZURE_STORAGE_ACCOUNT>.blob.core.windows.net/igenomes/'

## Create associative array mapping genome id to path stored in AWS iGenomes
declare -A IGENOMES
IGENOMES['GRCh37']=Homo_sapiens/Ensembl/GRCh37
#IGENOMES['GRCm38']=Mus_musculus/Ensembl/GRCm38
#IGENOMES['EB2']=Bacillus_subtilis_168/Ensembl/EB2  ## Small genome for testing purposes

# List of files on AWS iGenomes to transfer
GENOME_FILES=( 
    Sequence/WholeGenomeFasta/genome.fa 
    Sequence/BWAIndex/version0.6.0/*
    Sequence/Bowtie2Index/*
    Sequence/STARIndex/*
    Annotation/Genes/genes.gtf  
    Annotation/Genes/genes.bed 
)

for igenome in "${!IGENOMES[@]}"
do
    for j in "${GENOME_FILES[@]}"
    do
        igenomes_s3_path="https://s3.eu-west-1.amazonaws.com/ngi-igenomes/igenomes/${IGENOMES[$igenome]}/$j"
        igenomes_azure_path=`echo "${AZURE_BLOB_DIR}${IGENOMES[$igenome]}/$j" | sed 's/\*$//'`
        azcopy copy --recursive=true $igenomes_s3_path $igenomes_azure_path
    done
done