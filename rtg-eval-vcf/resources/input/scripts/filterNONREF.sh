#!/usr/bin/env bash
set -x
VCF_GZ_TO_SPLIT=$1
OUTPUT_VCF=$2
#filter out:
# 1. headers like this: ##ALT=<ID=NON_REF,Description="Represents any possible alternative allele at this location">
# 2. all the NON_REF columns

gzip -c -d ${VCF_GZ_TO_SPLIT} | sed -e 's/,<NON_REF>//'| sed -e 's/<NON_REF>//'| awk '{if($0 !~ /^##.*NON_REF/) {if (substr($9,0,3)!="0/0" && substr($10,0,3)!="0/0") print $0;}}'  > $OUTPUT_VCF




