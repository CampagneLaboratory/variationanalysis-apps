#!/usr/bin/env bash

. /in/scripts/common.sh

function buildBaselineConfidents {

    OUTPUT_DIR=$1
    rm -rf $OUTPUT_DIR || true
    mkdir -p $OUTPUT_DIR

    splitVCF ${OUTPUT_DIR} ${BASELINE_VCF_BASENAME} ${BASELINE_VCF}
    export BASELINE_STANDARD_VCF_GZ="${OUTPUT_DIR}/${BASELINE_VCF_BASENAME}.vcf.gz"
    export BASELINE_STANDARD_VCF_SNP_GZ="${OUTPUT_DIR}/${BASELINE_VCF_BASENAME}-snps.vcf.gz"
    export BASELINE_STANDARD_VCF_INDEL_GZ="${OUTPUT_DIR}/${BASELINE_VCF_BASENAME}-indels.vcf.gz"

    if [ ! -z "${BASELINE_REGIONS}" ]; then
        gzip -c -d  ${BASELINE_REGIONS} |awk '{print $1"\t"$2"\t"$3}' >${OUTPUT_DIR}/baseline-confident-regions-chr.bed
        cd ${OUTPUT_DIR}/
        bgzip -f baseline-confident-regions-chr.bed
        tabix -f baseline-confident-regions-chr.bed.gz
        export BASELINE_CONFIDENT_REGIONS_BED_GZ="${OUTPUT_DIR}/baseline-confident-regions-chr.bed.gz"
    fi
}

function splitInputVCF {
    OUTPUT_DIR=${HOME}/output-vcf-tmp/
    rm -rf ${OUTPUT_DIR} || true
    mkdir -p ${OUTPUT_DIR}
    splitVCF ${OUTPUT_DIR} ${VCF_INPUT_BASENAME} ${VCF_INPUT}
    export VCF_INPUT_SNPS=${OUTPUT_DIR}/${OUTPUT_BASENAME}-snps.vcf.gz
    export VCF_INPUT_INDELS=${OUTPUT_DIR}/${OUTPUT_BASENAME}-indels.vcf.gz
    export VCF_INPUT_GZ=${OUTPUT_DIR}/${OUTPUT_BASENAME}.vcf.gz
}

function splitVCF {

    OUTPUT_DIR=$1
    OUTPUT_BASENAME=$2
    VCF_TO_SPLIT=$3

    gzip -c -d ${VCF_TO_SPLIT} |awk '{if($0 !~ /^#/) print $0; else print $0}' > ${OUTPUT_DIR}/${OUTPUT_BASENAME}.vcf
    cd ${OUTPUT_DIR}
    bgzip -f ${OUTPUT_BASENAME}.vcf
    tabix -f ${OUTPUT_BASENAME}.vcf.gz

    # remove non-SNPs:
    gzip -c -d  ${BASELINE_STANDARD_VCF_GZ} |awk '{if($0 !~ /^#/) { if (length($4)==1 && length($5)==1) print $0;}  else {print $0}}' >${OUTPUT_DIR}/${OUTPUT_BASENAME}-snps.vcf
    bgzip -f ${OUTPUT_BASENAME}-snps.vcf
    tabix -f ${OUTPUT_BASENAME}-snps.vcf.gz

    # keep only indels:
    gzip -c -d  ${BASELINE_STANDARD_VCF_GZ} |awk '{if($0 !~ /^#/) { if (length($4)!=1 || length($5)!=1) print $0;}  else {print $0}}' >${OUTPUT_DIR}/${OUTPUT_BASENAME}-indels.vcf
    bgzip -f ${OUTPUT_BASENAME}-indels.vcf
    tabix -f ${OUTPUT_BASENAME}-indels.vcf.gz
}

function execute {
    set -x
    mkdir -p /out/Summaries || true
    mkdir -p /out/Recall_Plots || true
    mkdir -p /out/Evaluation_Archive || true

    cd ${RTG_TEMPLATE_PATH}
    tar -zxvf ${RTG_TEMPLATE_ARCHIVE}
    rm ${RTG_TEMPLATE_ARCHIVE}
    export RTG_TEMPLATE_DIR=`find ${RTG_TEMPLATE_PATH}/* -type d`
    export BASELINE_STANDARD_DIR=${HOME}/${VCF_INPUT_BASENAME}/
    buildBaselineConfidents $BASELINE_STANDARD_DIR

    EVAL_BED_REGION_OPTION=""
    if [ -e "${BASELINE_CONFIDENT_REGIONS_BED_GZ}" ]; then
        EVAL_BED_REGION_OPTION="--evaluation-regions=${BASELINE_CONFIDENT_REGIONS_BED_GZ}"
    fi

    splitInputVCF

    RTG_SNPS_OUTPUT_FOLDER=${HOME}/${VCF_INPUT_BASENAME}/snps
    rm -rf ${RTG_SNPS_OUTPUT_FOLDER} || true
    rtg vcfeval --baseline=${BASELINE_STANDARD_VCF_SNP_GZ}  \
            -c ${VCF_INPUT_SNPS} -o ${RTG_SNPS_OUTPUT_FOLDER} --template=${RTG_TEMPLATE_DIR} ${EVAL_BED_REGION_OPTION} \
            --bed-regions=${BED_OBSERVED_REGIONS_INPUT} ${RTG_OPTIONS}

    cp ${VCF_INPUT_SNPS}  ${RTG_SNPS_OUTPUT_FOLDER}/
    RTG_INDELS_OUTPUT_FOLDER=${HOME}/${VCF_INPUT_BASENAME}/indels
    rm -rf ${RTG_INDELS_OUTPUT_FOLDER} || true
    rtg vcfeval --baseline=${BASELINE_STANDARD_VCF_INDEL_GZ}  \
            -c ${VCF_INPUT_INDELS} -o ${RTG_INDELS_OUTPUT_FOLDER} --template=${RTG_TEMPLATE_DIR} ${EVAL_BED_REGION_OPTION} \
                --bed-regions=${BED_OBSERVED_REGIONS_INPUT} ${RTG_OPTIONS}

    cp ${VCF_INPUT_INDELS}  ${RTG_INDELS_OUTPUT_FOLDER}/

    MODEL_STAMP="${VCF_INPUT_BASENAME}:${BASELINE_VCF_BASENAME}"

    RTG_ROCPLOT_OPTIONS="--scores"
    rtg rocplot ${RTG_SNPS_OUTPUT_FOLDER}/snp_roc.tsv.gz -P --svg ${RTG_SNPS_OUTPUT_FOLDER}/SNP-PrecisionRecall.svg ${RTG_ROCPLOT_OPTIONS} --title="SNPs, model ${MODEL_STAMP}"
    rtg rocplot ${RTG_INDELS_OUTPUT_FOLDER}/non_snp_roc.tsv.gz -P --svg ${RTG_INDELS_OUTPUT_FOLDER}/INDEL-PrecisionRecall.svg ${RTG_ROCPLOT_OPTIONS} --title="INDELs, model ${MODEL_STAMP}"

    cp ${RTG_SNPS_OUTPUT_FOLDER}/SNP-PrecisionRecall.svg /out/Recall_Plots/
    cp ${RTG_INDELS_OUTPUT_FOLDER}/INDEL-PrecisionRecall.svg /out/Recall_Plots/
    cp ${RTG_SNPS_OUTPUT_FOLDER}/summary.txt /out/Summaries/SNP-summary.txt
    cp ${RTG_INDELS_OUTPUT_FOLDER}/summary.txt /out/Summaries/INDEL-summary.txt
    tar -zcvf $VCF_INPUT_BASENAME-eval.tar.gz ${HOME}/${VCF_INPUT_BASENAME}/
    cp $VCF_INPUT_BASENAME-eval.tar.gz /out/Evaluation_Archive/
}
