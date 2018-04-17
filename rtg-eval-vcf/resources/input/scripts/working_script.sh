#!/usr/bin/env bash

. /in/scripts/common.sh

function buildBaselineConfidents {

    OUTPUT_DIR=$1

    # add "chr prefix:"
    gzip -c -d ${BASELINE_VCF} |awk '{if($0 !~ /^#/) print "chr"$0; else print $0}' > ${OUTPUT_DIR}/baseline-confident-chr.vcf
    cd ${OUTPUT_DIR}
    bgzip -f baseline-confident-chr.vcf
    tabix -f baseline-confident-chr.vcf.gz
    export BASELINE_STANDARD_VCF_GZ="${OUTPUT_DIR}/baseline-confident-chr.vcf.gz"
      
    echo "Formatting baseline VCF for SNPs and indels"

    # remove non-SNPs:
    gzip -c -d  ${BASELINE_STANDARD_VCF_GZ} |awk '{if($0 !~ /^#/) { if (length($4)==1 && length($5)==1) print $0;}  else {print $0}}' >${OUTPUT_DIR}/baseline-confident-chr-snps.vcf
    bgzip -f baseline-confident-chr-snps.vcf
    tabix -f baseline-confident-chr-snps.vcf.gz
    export BASELINE_STANDARD_VCF_SNP_GZ="${OUTPUT_DIR}/baseline-confident-chr-snps.vcf.gz"

    # keep only indels:
    gzip -c -d  ${BASELINE_STANDARD_VCF_GZ} |awk '{if($0 !~ /^#/) { if (length($4)!=1 || length($5)!=1) print $0;}  else {print $0}}' >${OUTPUT_DIR}/baseline-confident-chr-indels.vcf
    bgzip -f baseline-confident-chr-indels.vcf
    tabix -f baseline-confident-chr-indels.vcf.gz
    export BASELINE_STANDARD_VCF_INDEL_GZ="${OUTPUT_DIR}/baseline-confident-chr-indels.vcf.gz"

 
    if [ -z "${BASELINE_REGIONS+set}" ]; then

        gzip -c -d  ${BASELINE_REGIONS} |awk '{print "chr"$1"\t"$2"\t"$3}' >${OUTPUT_DIR}/baseline-confident-regions-chr.bed
        cd ${OUTPUT_DIR}/
        bgzip -f baseline-confident-regions-chr.bed
        tabix -f baseline-confident-regions-chr.bed.gz

        export BASELINE_CONFIDENT_REGIONS_BED_GZ="${OUTPUT_DIR}/baseline-confident-regions-chr.bed.gz"
    fi
}

function execute {
    set -x
    cd ${RTG_TEMPLATE_PATH}
    tar -zxvf ${RTG_TEMPLATE_ARCHIVE}
    rm ${RTG_TEMPLATE_ARCHIVE}
    export RTG_TEMPLATE_DIR=`find ${RTG_TEMPLATE_PATH}/* -type d`
    export BASELINE_STANDARD_DIR=/out/output-tmp
    mkdir -p $BASELINE_STANDARD_DIR
    buildBaselineConfidents $BASELINE_STANDARD_DIR
    EVAL_BED_REGION_OPTION=""
    if [ -z "${BASELINE_CONFIDENT_REGIONS_BED_GZ+set}" ]; then
        EVAL_BED_REGION_OPTION="--evaluation-regions=${BASELINE_CONFIDENT_REGIONS_BED_GZ}"
    fi


    RTG_SNPS_OUTPUT_FOLDER=/out/output-snps
    #mkdir -p /out/output-snps
    rm -rf ${RTG_SNPS_OUTPUT_FOLDER} || true
    gzip -c -d ${VCF_INPUT} |awk '{if($0 !~ /^#/) { if (length($4)==1 && length($5)==1) print $0;}  else {print $0}}'  >${VCF_INPUT_BASENAME}-snps.vcf
    bgzip -f ${VCF_INPUT_BASENAME}-snps.vcf
    tabix -f ${VCF_INPUT_BASENAME}-snps.vcf.gz
    
    rtg vcfeval --baseline=${BASELINE_STANDARD_VCF_SNP_GZ}  \
            -c ${VCF_INPUT_BASENAME}-snps.vcf.gz -o ${RTG_SNPS_OUTPUT_FOLDER} --template=${RTG_TEMPLATE_DIR} ${EVAL_BED_REGION_OPTION} \
            --bed-regions=${BED_OBSERVED_REGIONS_INPUT} \
            --vcf-score-field=P  --sort-order=descending

    #TODO --vcf-score-field=P  --sort-order=descending options to expose


    dieUponError "Failed to run rtg vcfeval for SNPs."

    cp ${VCF_INPUT_BASENAME}-snps.vcf.gz  ${RTG_SNPS_OUTPUT_FOLDER}/

    RTG_INDELS_OUTPUT_FOLDER=/out/output-indels
    rm -rf ${RTG_INDELS_OUTPUT_FOLDER} || true
    gzip -c -d ${VCF_INPUT} |awk '{if($0 !~ /^#/) { if (length($4)!=1 || length($5)!=1) print $0;}  else {print $0}}'  >${VCF_INPUT_BASENAME}-indels.vcf
    bgzip -f ${VCF_INPUT_BASENAME}-indels.vcf
    tabix -f ${VCF_INPUT_BASENAME}-indels.vcf.gz

    rtg vcfeval --baseline=${GOLD_STANDARD_VCF_INDEL_GZ}  \
            -c ${VCF_INPUT_BASENAME}-indels.vcf.gz -o ${RTG_INDELS_OUTPUT_FOLDER} --template=${RTG_TEMPLATE} ${EVAL_BED_REGION_OPTION} \
                --bed-regions=${BED_OBSERVED_REGIONS_OUTPUT} \
                ${RTG_OPTIONS}
    dieUponError "Failed to run rtg vcfeval."

    cp ${VCF_INPUT_BASENAME}-indels.vcf.gz  ${RTG_INDELS_OUTPUT_FOLDER}/

    MODEL_STAMP="${VCF_INPUT_BASENAME}:${BASELINE_VCF_BASENAME}"
    #grep ${MODEL_TIME} model-conditions.txt >${RTG_OUTPUT_FOLDER}/model-conditions.txt
    #grep ${MODEL_TIME} predict-statistics.tsv   >${RTG_OUTPUT_FOLDER}/predict-statistics.tsv

    RTG_ROCPLOT_OPTIONS="--scores"
    rtg rocplot ${RTG_SNPS_OUTPUT_FOLDER}/snp_roc.tsv.gz -P --svg ${RTG_SNPS_OUTPUT_FOLDER}/SNP-PrecisionRecall.svg ${RTG_ROCPLOT_OPTIONS} --title="SNPs, model ${MODEL_STAMP}"
    dieUponError "Unable to generate SNP Precision Recall plot."

    rtg rocplot ${RTG_INDELS_OUTPUT_FOLDER}/non_snp_roc.tsv.gz -P --svg ${RTG_INDELS_OUTPUT_FOLDER}/INDEL-PrecisionRecall.svg ${RTG_ROCPLOT_OPTIONS} --title="INDELs, model ${MODEL_STAMP}"
    dieUponError "Unable to generate indel Precision Recall plot."
}
