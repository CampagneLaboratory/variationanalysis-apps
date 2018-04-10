#!/usr/bin/env bash

. /in/scripts/common.sh
. /in/scripts/merge.sh


function clone {
    git clone https://github.com/CampagneLaboratory/GenotypeTensors.git ${HOME}/GenotypeTensors
    export PATH="${HOME}/GenotypeTensors/bin:${PATH}"
}

function execute {
    mkdir -p /out/sbi
    mkdir -p /out/sbi-vec
    mkdir -p /out/vec-vec

    #clone
    export PATH="${HOME}/GenotypeTensors/bin:${PATH}"
    #generate SBI
    cd /out/sbi
    #parallel-genotype-sbi.sh 10g "${GOBY_ALIGNMENT}" 2>&1 | tee parallel-genotype-sbi.log


    cd ${MODEL_ARCHIVE_PATH}
    tar -zxvf ${MODEL_ARCHIVE_FILE}
    #rm ${MODEL_ARCHIVE_FILE}
    MODEL_DIR=`find ${MODEL_ARCHIVE_PATH} -name  Model_* -type d`
    MODEL_PATH="${MODEL_ARCHIVE_PATH}/${MODEL_DIR}"
    DOMAIN_PROPERTIES="${MODEL_PATH}/models/domain.properties"
    CHECKPOINT_PROPERTIES="${MODEL_PATH}/models/checkpoint.properties"

    #generate VECs (read params form the model/domain.properties

    IndelSequenceLength=`cat ${DOMAIN_PROPERTIES} | grep indelSequenceLength | cut -d= -f2`
    FeatureMapper=`cat ${DOMAIN_PROPERTIES} | grep input.featureMapper= | cut -d= -f2`
    LabelSmoothingEpsilon=`cat ${DOMAIN_PROPERTIES} | grep labelSmoothing.epsilon | cut -d= -f2`
    Ploidy=`cat ${DOMAIN_PROPERTIES} | grep genotypes.ploidy | cut -d= -f2`
    GenomicContextLength=`cat ${DOMAIN_PROPERTIES} | grep stats.genomicContextSize.max | cut -d= -f2`
    ExtraGenotypes=`cat ${DOMAIN_PROPERTIES} | grep extraGenotypes | cut -d= -f2`
    CHECKPOINT_KEY=`cat ${CHECKPOINT_PROPERTIES} | grep default.checkpoint | cut -d= -f2`

    cd /out/sbi-vec
    for file in /out/sbi/out-part*.sbi; do
        SBI_basename=`basename /out/sbi/$file .sbi`
        echo "SBI basename: '$SBI_basename'"
        if [ ! -f /out/sbi/${SBI_basename}.sbip ]; then
          echo "${SBI_basename}.sbip not found!"
        fi
        echo "cd /out/sbi-vec && export-genotype-tensors.sh 2g --indel-sequence-length ${IndelSequenceLength} --feature-mapper ${FeatureMapper} \
        -i \"/out/sbi/${SBI_basename}.sbi\" -o /out/sbi-vec/${SBI_basename}-${DATASET_NAME} --label-smoothing-epsilon ${LabelSmoothingEpsilon} \
        --ploidy ${Ploidy} --genomic-context-length ${GenomicContextLength} --export-input input --export-output softmaxGenotype \
        --export-output metaData --extra-genotypes ${ExtraGenotypes} --sample-name \"${SAMPLE_NAME}\"  --sample-type germline \
        && cd /out/vec-vec && predict-genotypes-pytorch.sh 10g \"${MODEL_PATH}\ \"${MODEL_NAME}\" /out/sbi-vec/${SBI_basename}-${DATASET_NAME}" >> /out/sbi-vec/commands.txt

     done
    cat /out/sbi-vec/commands.txt
    parallel --bar --eta -j${SBI_NUM_THREADS} --plus  --progress :::: /out/sbi-vec/commands.txt
    
    cat ${MODEL}-${MODEL_NAME}-*.vcf | vcf-sort >sorted-${MODEL}-${MODEL_LABEL}.vcf
    bgzip -f sorted-${MODEL}-${MODEL_LABEL}.vcf
    tabix -f sorted-${MODEL}-${MODEL_LABEL}.vcf.gz


    #cd /output/vcf
    #predict-genotypes-many.sh 10g /input/model/ \"${Model_Name}\" /input/sbi/*.sbi
    #/in/scripts/merge.sh
}