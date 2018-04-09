#!/usr/bin/env bash

#params:
 #  $1 - folder with the sbis to merge.
function merge {
 cd $1
 cat *-observed-regions.bed | sort -k1,1 -k2,2n | mergeBed > model-bestscore-observed-regions.bed
 bgzip -f model-bestscore-observed-regions.bed
 tabix -f model-bestscore-observed-regions.bed.gz

}