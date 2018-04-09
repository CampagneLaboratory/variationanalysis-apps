#!/usr/bin/env bash

. /in/scripts/common.sh
. /in/scripts/merge.sh


function clone {
    git clone https://github.com/CampagneLaboratory/GenotypeTensors.git /GenotypeTensors
}

function execute {
    mkdir -p /out/sbi
    mkdir -p /out/sbi-vec
    mkdir -p /out/vec-vec

    #generate SBI
    cd /out/sbi
    parallel-genotype-sbi.sh 10g "${GOBY_ALIGNMENT}" 2>&1 | tee parallel-genotype-sbi.log


    #cd ${MODEL_PATH}
    #tar -zxvf Model_*.tar.gz;
    #rm Model_*.tar.gz

    #generate VECs (read params form the model/domain.properties
    MODEL_PATH=`ls -1 ${MODEL_PATH}/Model_YNCRX_pytorch`
    IndelSequenceLength=`cat domain.properties | grep indelSequenceLength | cut -d= -f2`
    FeatureMapper=`cat domain.properties | grep input.featureMapper= | cut -d= -f2`
    LabelSmoothingEpsilon=`cat domain.properties | grep labelSmoothing.epsilon | cut -d= -f2`
    Ploidy=`cat domain.properties | grep genotypes.ploidy | cut -d= -f2`
    GenomicContextLength=`cat domain.properties | grep stats.genomicContextSize.max | cut -d= -f2`
    ExtraGenotypes=`cat domain.properties | grep extraGenotypes | cut -d= -f2`
    for file in /out/sbi/out-part*.sbi; do
        SBI_basename=`basename /out/sbi/$file .sbi`
        echo "SBI basename: '$SBI_basename'"
        if [ ! -f /out/sbi/${SBI_basename}.sbip ]; then
          echo "${SBI_basename}.sbip not found!"
        fi

        cd /out/sbi-vec
        echo "export-genotype-tensors.sh 2g --indel-sequence-length ${IndelSequenceLength} --feature-mapper ${FeatureMapper} \
        -i \"/out/sbi/${SBI_basename}.sbi\" -o /out/sbi-vec/${SBI_basename} --label-smoothing-epsilon ${LabelSmoothingEpsilon} \
        --ploidy ${Ploidy} --genomic-context-length ${GenomicContextLength} --export-input input --export-output softmaxGenotype \
        --export-output metaData --extra-genotypes ${ExtraGenotypes} --sample-name \"${SBI_basename}-${DATASET_NAME}\"  --sample-type germline" >> commands.txt

        #it should return:
        #/out/VEC/${SBI_basename}*.vec*
        #/out/VEC/domain.properties
        #/out/VEC/config.properties
        #exit 0
     done
    cat commands.txt
    parallel --bar --eta -j${SBI_NUM_THREADS} --plus  --progress :::: commands.txt
    rm commands.txt

    cd /out/vec-vec
    predict-genotypes-pytorch-many.sh 10g ${MODEL_PATH} "${MODEL_NAME}" /out/sbi-vec/*-${DATASET_NAME}.vec
    #cd /output/vcf
    #predict-genotypes-many.sh 10g /input/model/ \"${Model_Name}\" /input/sbi/*.sbi
    #/in/scripts/merge.sh
}