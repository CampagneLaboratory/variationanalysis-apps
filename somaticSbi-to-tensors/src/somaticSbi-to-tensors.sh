#!/bin/bash
# somaticSbi-to-tensors 0.0.1
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

    echo "Value of SomaticSBI: '${SomaticSBI[@]}'"

     #download inputs in $HOME/in
    dx-download-all-inputs --parallel
    ls -ltrR  ${HOME}/in
    mkdir -p ${HOME}/in/SBI
    mkdir -p ${HOME}/in/TSV
    find ${HOME}/in/SomaticSBI -name \*.sbi\* |xargs -I {} mv {} ${HOME}/in/SBI/
    find ${HOME}/in/Annotation -name \*.tsv   |xargs -I {} mv {} ${HOME}/in/TSV

    ls -ltrR  ${HOME}/in

    SBI_basename=`basename ${HOME}/in/SBI/*.sbi .sbi`
    echo "SBI basename: '$SBI_basename'"
    ANNOTATION_basename=`basename ${HOME}/in/*.tsv .tsv`
    echo "ANNOTATION basename: '$ANNOTATION_basename'"

    echo "Downloading the docker image..."
    dx-docker pull artifacts/variationanalysis-app:latest &>/dev/null

    mkdir -p $HOME/out/VEC
    dx-docker run \
        -v ${HOME}/in:${HOME}/in \
        -v ${HOME}/out/:${HOME}/out/ \
        artifacts/variationanalysis-app:latest \
        bash -c "source ~/.bashrc; combine-with-gold-standard.sh 2g -a \"/${HOME}/in/TSV/${ANNOTATION_basename}.tsv -i \"/${HOME}/in/SBI/${SBI_basename}.sbi\" -o  \"/${HOME}/in/SBI/${SBI_basename}-annotated.sbi\" --sampling-fraction ${SamplingRate} "

    dx-docker run \
        -v ${HOME}/in:${HOME}/in \
        -v ${HOME}/out/:${HOME}/out/ \
        artifacts/variationanalysis-app:latest \
        bash -c "source ~/.bashrc; export-somatic-tensors.sh 2g --feature-mapper ${FeatureMapper} -i \"/${HOME}/in/SBI/${SBI_basename}-annotated.sbi\" -o \"${HOME}/out/${SBI_basename}\" --label-smoothing-epsilon ${LabelSmoothingEpsilon} --ploidy ${Ploidy} --genomic-context-length ${GenomicContextLength} --export-input input --export-output isBaseMutated --export-output somaticFrequency --sample-name \"${GermlineSampleName}\" --sample-name \"${TumorSampleName}\" --sample-type germline --sample-type tumor --sample-index 0 --sample-index 1"

    mkdir -p ${HOME}/out/Tensors
    mv ${HOME}/out/${SBI_basename}*.vec*  ${HOME}/out/Tensors
    dx-upload-all-outputs --parallel


}
