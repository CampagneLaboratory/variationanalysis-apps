#!/bin/bash
# extract-chromosomes-3 0.0.1
# Generated by dx-app-wizard.
#
# Basic execution pattern: Your app will run on a single machine from
# beginning to end.
#
# Your job's input variables (if any) will be loaded as environment
# variables before this script runs.  Any array inputs will be loaded
# as bash arrays.
#
# Any code outside of main() (or any entry point you may add) is
# ALWAYS executed, followed by running the entry point itself.
#
# See https://wiki.dnanexus.com/Developer-Portal for tutorials on how
# to modify this file.

main() {

    echo "Start to Download docker image in background..."
    dx-docker pull artifacts/variationanalysis-app:latest &>/dev/null &

    mkdir -p /input/Sorted_Bam
    mkdir -p /out/Filtered_BAM

    echo "Value of Chromosome_List: '${Chromosome_List}'"

    #download the sorted bam
    echo "Downloading sorted BAM file '${Sorted_Bam_name}'"
    dx download "${Sorted_Bam}" -o /input/Sorted_Bam/${Sorted_Bam_name}

    echo "Downloading sorted BAM file '${Sorted_Bam_Index_name}'"
    dx download "${Sorted_Bam_Index}" -o /input/Sorted_Bam/${Sorted_Bam_Index_name}

    echo "Make sure Downloading the docker image has finished..."
    dx-docker pull artifacts/variationanalysis-app:latest

    cpus=`grep physical  /proc/cpuinfo |grep id|wc -l`

    dx-docker run \
        -v /input/:/input \
        -v /out/:/out \
        artifacts/variationanalysis-app:latest \
        bash -c "source ~/.bashrc; cd /out/; extract-chromosomes.sh ${cpus} /input/Sorted_Bam/${Sorted_Bam_name} \"${Chromosome_List}\""


    mkdir -p $HOME/out
    mkdir -p $HOME/out/Filtered_BAM
    mkdir -p $HOME/out/Filtered_BAM_Index
    mv /out/*-subset.bam     $HOME/out/Filtered_BAM
    mv /out/*-subset.bam.bai $HOME/out/Filtered_BAM_Index

    echo "Files to publish"
    ls -lrt $HOME/out
    dx-upload-all-outputs --parallel

}
