# Running nf-core/rnaseq on Azure via Tower

This repo serves as a simple guide with which to get both the minimal and full-sized tests for the nf-core/rnaseq pipeline up and running on the Microsoft Azure Cloud platform via Nextflow Tower.

## Prerequisites

1. Access to [Tower Cloud](https://cloud.tower.nf/) / Tower Enterprise
2. [Nextflow Tower CLI](https://github.com/seqeralabs/tower-cli#1-installation)
3. [`azcopy` utility](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10)
4. [`jq`](https://stedolan.github.io/jq/)

## Using the Tower CLI

Most Tower entities such as Pipelines, Compute Environments etc can be exported in JSON format via the Tower CLI. This is very useful for creating infrastructure as code to store the exact configuration options used to create these entities and to share and track changes over time. We will use the Tower CLI to create entities within the Tower UI directly from the command-line.

Please make sure you have installed and configured the Tower CLI properly. You can check this via the `tw info` command:

```console
$ tw info

    Details
    -------------------------+----------------------
     Tower API endpoint      | https://api.tower.nf 
     Tower API version       | 1.12.0               
     Tower version           | 22.2.0-newton        
     CLI version             | 0.6.0 (a1bf815)      
     CLI minimum API version | 1.9                  
     Authenticated user      | joebloggs            

    System health status
    ---------------------------------------+----
     Remote API server connection check    | OK 
     Tower API version check               | OK 
     Authentication API credential's token | OK 
```

### Compute Environments

Example JSON files for a couple of Compute Environments have been included in the [`json/compute-envs`](json/compute-envs) directory for you to import directly into Tower (see [usage docs](https://github.com/seqeralabs/tower-cli/blob/master/USAGE.md#importingexporting-a-compute-environment))

Using [azure_batch_ce_east_us_d16_v3.json](json/compute-envs/azure_batch_ce_east_us_d16_v3.json) as an example please change the following entries in the file to suit your requirements:

1. `workDir`
2. `region`

```bash
WORKSPACE=<TOWER_ORGANISATION>/<TOWER_WORKSPACE>
COMPUTE_ENV=azure_batch_ce_east_us_d16_v3

tw \
    compute-envs \
    import \
    --workspace=$WORKSPACE \
    --name=$COMPUTE_ENV \
    --wait='AVAILABLE' \
    ./json/compute-envs/$COMPUTE_ENV.json
```

This Compute Environment has been set-up to provision 20 `Standard_D16_v3` VMs by default but these options can be changed if required. The `--wait=AVAILABLE` option instructs the Tower CLI to exit after the Compute Environment has been created which is useful for downstream automation.

Similarly, you can easily create a Compute Environment for 20 `Standard_D32_v3` VMs using [azure_batch_ce_east_us_d32_v3.json](json/compute-envs/azure_batch_ce_east_us_d32_v3.json) by changing `COMPUTE_ENV=azure_batch_ce_east_us_d32_v3` in the example above.

### Pipelines

Example JSON files for a selection of Pipelines have been included in the [`json/pipelines`](json/pipelines) directory for you to import directly into Tower (see [usage docs](https://github.com/seqeralabs/tower-cli/blob/master/USAGE.md#importingexporting-a-pipeline))

Using [nf_core_rnaseq_test.json](json/pipelines/nf_core_rnaseq_test.json) as an example:

```bash
WORKSPACE=<TOWER_ORGANISATION>/<TOWER_WORKSPACE>
COMPUTE_ENV=azure_batch_ce_east_us_d16_v3
PIPELINE=nf_core_rnaseq_test

tw \
    pipelines \
    import \
    --workspace=$WORKSPACE \
    --name=$PIPELINE \
    --compute-env=$COMPUTE_ENV \
    ./json/pipelines/$PIPELINE.json
```

This Pipeline has been set-up to use the `test` profile that is available for use with all nf-core pipelines. This instructs the pipeline to download a tiny, minimal dataset to check that it functions in an infrastructure independent manner (see [test data docs](https://nf-co.re/docs/contributing/adding_pipelines#running-with-test-data)). It is always a good idea to run the `test` profile before running the pipeline on actual data. From the commands above, you can also see that the previously created `azure_batch_ce_east_us_d16_v3` Compute Environment will be used to submit the jobs from this Pipeline to Azure Batch.

Most nf-core pipelines also have a `test_full` profile that defines a much larger and realistic dataset with which to test the pipeline. More information regarding the full-sized dataset used by the nf-core/rnaseq pipeline can be found in the [nf-core/testdatasets repo](https://github.com/nf-core/test-datasets/tree/rnaseq#full-test-dataset-origin).

Similarly, can easily create a Pipeline to run the `test_full` profile using [nf_core_rnaseq_full_test.json](json/pipelines/nf_core_rnaseq_full_test.json) by changing `PIPELINE=nf_core_rnaseq_full_test` in the example above. You will need to add this to run the full-sized tests later in the guide.

### Launcing Pipelines

Now that we have created a Compute Environment and associated this to a Pipeline we can launch it via the Tower CLI. The `--outdir` parameter is mandatory when running the nf-core/rnaseq pipeline so we will define it here on the CLI. The value of `WORK_DIR` can be the same value you set for `workDir` when creating the [Compute Environment](#compute-environments).

```bash
WORKSPACE=<TOWER_ORGANISATION>/<TOWER_WORKSPACE>
PIPELINE=nf_core_rnaseq_test
WORK_DIR=<WORK_DIRECTORY>

tw \
    launch \
    --workspace=$WORKSPACE \
    --params-file=<(echo -e "outdir: ${WORK_DIR}/$PIPELINE") \
    $PIPELINE
```

The Pipeline will become visible for monitoring in the Runs page in the Tower UI almost instantly.

## Running full-sized tests

The previous sections highlight how to run the nf-core/rnaseq pipeline on the minimal `test` profile provided with the pipeline. We will now try to run a full-sized and more realistic test on Azure Batch. Before we can run the full-sized tests we need to copy across any reference genome data and input FastQ files to Azure blob storage from S3.

### Genome files

nf-core pipelines make use of a resource called [AWS iGenomes](https://ewels.github.io/AWS-iGenomes/) to automatically download reference genomes by standard identifiers e.g. `GRCh37` (see [nf-core docs](https://nf-co.re/docs/usage/reference_genomes#illumina-igenomes)).

It is recommended to copy across any reference files required for the full-sized tests from S3 to Azure blob storage because this can be a common cause of failure. We have written a small, executable, bash script called [`s3_igenomes_to_az.sh`](bin/s3_igenomes_to_az.sh) that uses the `azcopy` tool to copy across the human GRCh37 genome files required for the full-sized nf-core/rnaseq tests. The script can be easily extended to download other AWS iGenomes if required.

### FastQ files

The FastQ files required for the full-sized tests of the nf-core/rnaseq pipeline are hosted in an S3 bucket. The full paths can be found in [this samplesheet](https://github.com/nf-core/rnaseq/blob/89bf536ce4faa98b4d50a8ec0a0343780bc62e0a/conf/test_full.config#L18). We will use `azcopy` to transfer the files directly from S3 to Azure blob storage. You will need to change the value of the `AZURE_PATH` variable below to reflect where you would like to copy the FastQ files into your account.

```bash
S3_PATH='https://s3.eu-west-1.amazonaws.com/nf-core-awsmegatests/rnaseq/input_data/*'
AZURE_PATH='https://<AZURE_STORAGE_ACCOUNT>.blob.core.windows.net/<DIRECTORY_PATH>/input_data/'

azcopy \
    copy \
    --recursive=true \
    $S3_PATH \
    $AZURE_PATH
```

### Adding a Dataset

Once the input data for the nf-core/rnaseq pipeline has been copied to your Azure blob storage replace the `<AZURE_PATH>` placeholders in [`nf_core_rnaseq_samplesheet_full_azure.csv`](assets/nf_core_rnaseq_samplesheet_full_azure.csv) to reflect their location. The input samplesheet for the pipeline can then be added as a Dataset to Tower with which to launch the pipeline (see [docs](https://help.tower.nf/datasets/overview/)). The command below will dump the internal Tower id for the Dataset to a file (i.e. `$DATASET.dataset-id.txt`) which we can use later when launcing the Pipeline.

```bash
WORKSPACE=<TOWER_ORGANISATION>/<TOWER_WORKSPACE>
DATASET=nf_core_rnaseq_samplesheet_full_azure

tw \
    -o json \
    datasets \
    add \
    --workspace=$WORKSPACE \
    --name=$DATASET \
    --description='Samplesheet containing links to full-sized data required to test the nf-core/rnaseq pipeline from end-to-end' \
    --header \
    ./assets/$DATASET.csv | \
    jq -r .datasetId > $DATASET.dataset-id.txt
```

### Launch the pipeline

To launch the full-sized tests we need to change a couple of parameters:
1. `--input` (mandatory): 
2. `--outdir` (mandatory): The value of `WORK_DIR` can be the same value you set for `workDir` when creating the [Compute Environment](#compute-environments).
3. `--igenomes_base`: Change this to the base directory you specified when copying across the reference files from S3 to Azure blob storage in the [Genome files section](#genome-files)

```bash
WORKSPACE=<TOWER_ORGANISATION>/<TOWER_WORKSPACE>
PIPELINE=nf_core_rnaseq_full_test
WORK_DIR=<WORK_DIRECTORY>
DATASET=nf_core_rnaseq_samplesheet_full_azure
DATASET_ID=`cat $DATASET.dataset-id.txt`
DATASET_URL=`tw -o json datasets url --id=$DATASET_ID --workspace=$WORKSPACE | jq -r .datasetUrl`

tw \
    launch \
    --workspace=$WORKSPACE \
    --params-file=<(echo -e "input: $DATASET_URL\noutdir: ${WORK_DIR}/$PIPELINE\nigenomes_base: '<IGENOMES_BASE_PATH>'") \
    $PIPELINE
```

The Pipeline will become visible for monitoring in the Runs page in the Tower UI almost instantly.

