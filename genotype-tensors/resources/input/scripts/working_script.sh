#!/usr/bin/env bash

. /in/scripts/common.sh


function execute {
    mkdir -p /out/sbi
    cd /out/sbi
    parallel-genotype-sbi.sh 10g "${GOBY_ALIGNMENT}" 2>&1 | tee parallel-genotype-sbi.log
    cd ${MODEL_PATH}
    tar -zxvf Model_*.tar.gz;
    rm Model_*.tar.gz
    cd /output/vcf
    predict-genotypes-pytorch-many.sh 10g ${MODEL_PATH} "${MODEL_NAME}" /out/sbi/*.sbi
    /in/scripts/merge.sh
}