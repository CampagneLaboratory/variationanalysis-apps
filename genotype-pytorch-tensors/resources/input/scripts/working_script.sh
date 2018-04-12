#!/usr/bin/env bash

. /in/scripts/common.sh
. /in/scripts/merge.sh


function clone {
    git clone https://github.com/CampagneLaboratory/GenotypeTensors.git ${HOME}/GenotypeTensors
    export PATH="${HOME}/GenotypeTensors/bin:${PATH}"
}

function execute {

    set -x
    mkdir -p /out/sbi
    mkdir -p /out/sbi-vec
    mkdir -p /out/vec-vec
    mkdir -p /out/vec-vcf

    clone
    export PATH="${HOME}/GenotypeTensors/bin:${PATH}"
    #generate SBI
    cd /out/sbi

    # memory is expressed in MB, /1000 to transform in Gb and assign ito goby
    goby_mem=`echo $(( MEMORY_IN_MB / 1000 ))`
    if [ "$goby_mem" -lt 6 ]; then
        goby_mem=10
    fi
    
    #10g are used inside parallel-genotype-sbi.sh, adding extra 2g 
    MEM_FOR_EACH_PARALLEL_EXECUTION_IN_GB=12
    parallel_executions=`echo $(( MEMORY_IN_MB / 1000 / MEM_FOR_EACH_PARALLEL_EXECUTION_IN_GB ))`
    if [ "$parallel_executions" -lt 1 ]; then
        parallel_executions=1
    fi
    if [ "$parallel_executions" -gt "$CORES" ]; then
        parallel_executions=$CORES
    fi
    export SBI_NUM_THREADS=${parallel_executions}

    parallel-genotype-sbi.sh "${goby_mem}g" "${GOBY_ALIGNMENT}" 2>&1 | tee parallel-genotype-sbi.log
    ls -lrt /out/sbi/

    #3g are required for each parallel execution
    MEM_FOR_EACH_PARALLEL_EXECUTION_IN_GB=3
    parallel_executions=`echo $(( MEMORY_IN_MB / 1000 / MEM_FOR_EACH_PARALLEL_EXECUTION_IN_GB - 1 ))`
    if [ "$parallel_executions" -lt 1 ]; then
        parallel_executions=1
    fi
    if [ "$parallel_executions" -gt "$CORES" ]; then
        parallel_executions=$CORES
    fi
    export SBI_NUM_THREADS=${parallel_executions}

    cd ${MODEL_ARCHIVE_PATH}
    tar -zxvf ${MODEL_ARCHIVE_FILE}
    rm ${MODEL_ARCHIVE_FILE}
    export MODEL_PATH=`find ${MODEL_ARCHIVE_PATH}/* -name  Model_* -type d`
    #MODEL_PATH="${MODEL_ARCHIVE_PATH}/${MODEL_DIR}"
    DOMAIN_PROPERTIES="${MODEL_PATH}/models/domain.properties"
    CHECKPOINT_PROPERTIES="${MODEL_PATH}/models/checkpoint.properties"

    # read params form the domain.properties
    IndelSequenceLength=`cat ${DOMAIN_PROPERTIES} | grep indelSequenceLength | cut -d= -f2`
    FeatureMapper=`cat ${DOMAIN_PROPERTIES} | grep input.featureMapper= | cut -d= -f2`
    LabelSmoothingEpsilon=`cat ${DOMAIN_PROPERTIES} | grep labelSmoothing.epsilon | cut -d= -f2`
    Ploidy=`cat ${DOMAIN_PROPERTIES} | grep genotypes.ploidy | cut -d= -f2`
    GenomicContextLength=`cat ${DOMAIN_PROPERTIES} | grep stats.genomicContextSize.max | cut -d= -f2`
    ExtraGenotypes=`cat ${DOMAIN_PROPERTIES} | grep extraGenotypes | cut -d= -f2`

    # set the default checkpoint if the user didn't set it in the interface
    if [[ -z "$CHECKPOINT_KEY" ]]; then
        CHECKPOINT_KEY=`cat ${CHECKPOINT_PROPERTIES} | grep default.checkpoint | cut -d= -f2`
    fi

    cd /out/sbi-vec
    for file in /out/sbi/out-part*.sbi; do
        SBI_basename=`basename /out/sbi/$file .sbi`
        echo "SBI basename: '$SBI_basename'"
        if [ ! -f /out/sbi/${SBI_basename}.sbip ]; then
          echo "${SBI_basename}.sbip not found!"
        fi
        OUTPUT_VEC="${DATASET_BASENAME}_${DATASET_NAME}_${CHECKPOINT_KEY}_${SBI_basename}_predicted"

        if [ -z "${MINI_BATCH_SIZE+set}" ]; then
            MINI_BATCH_SIZE="2048"
            echo "MINI_BATCH_SIZE set to ${MINI_BATCH_SIZE}. Change the variable to switch the mini-batch-size."
        fi

        echo "cd /out/sbi-vec \
        && export-genotype-tensors.sh 2g --indel-sequence-length ${IndelSequenceLength} --feature-mapper ${FeatureMapper} \
        -i \"/out/sbi/${SBI_basename}.sbi\" -o /out/sbi-vec/${SBI_basename}-${DATASET_NAME} --label-smoothing-epsilon ${LabelSmoothingEpsilon} \
        --ploidy ${Ploidy} --genomic-context-length ${GenomicContextLength} --export-input input --export-output softmaxGenotype \
        --export-output metaData --extra-genotypes ${ExtraGenotypes} --sample-name \"${SAMPLE_NAME}\"  --sample-type germline \
        && cd /out/vec-vec && predict-genotypes-pytorch.sh 1g \"${MODEL_PATH}\" \"${MODEL_NAME}\" ${OUTPUT_VEC} /out/sbi-vec/${SBI_basename} \
        && cd /out/vec-vcf && predict-genotypes.sh 2g -m ${MODEL_PATH}/models -l ${MODEL_NAME}  --no-cache --mini-batch-size ${MINI_BATCH_SIZE} \
        --vec-path \"/out/vec-vec/${OUTPUT_VEC}.vec\" -f --format VCF --checkpoint-key ${CHECKPOINT_KEY} \
        -i \"/out/sbi/${SBI_basename}.sbi\" \
        && rm -f \"/out/sbi/${SBI_basename}.sbi\" && rm -f \"/out/vec-vec/${OUTPUT_VEC}.*\" && rm -f \"/out/sbi-vec/${SBI_basename}-*\" " >> /out/sbi-vec/commands.txt

    done
    cat /out/sbi-vec/commands.txt
    parallel --bar --eta -j${SBI_NUM_THREADS} --plus  --progress :::: /out/sbi-vec/commands.txt

    #merge the VCFs
    mkdir -p /out/vcf
    cd /out/vec-vcf
    cat models-${MODEL_NAME}-${CHECKPOINT_KEY}-*.vcf | vcf-sort > /out/vcf/sorted-${MODEL}-${MODEL_LABEL}.vcf
    cd /out/vcf/
    bgzip -f sorted-${MODEL}-${MODEL_LABEL}.vcf
    tabix -f sorted-${MODEL}-${MODEL_LABEL}.vcf.gz
    rm -f /out/vec-vcf/models-${MODEL_NAME}-${CHECKPOINT_KEY}-*.vcf

    #merge the BEDs
    cd /out/vec-vcf
    cat *-observed-regions.bed | sort -k1,1 -k2,2n | mergeBed > /out/vcf/model-bestscore-observed-regions.bed
    rm -f /out/vec-vcf/*
    cd /out/vcf/

    bgzip -f model-bestscore-observed-regions.bed
    tabix -f model-bestscore-observed-regions.bed.gz
}