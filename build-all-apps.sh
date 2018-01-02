#!/usr/bin/env bash
./build-app.sh variation-analysis
./build-app.sh bam-to-goby
./build-app.sh goby-indexed-genome-builder
./build-app.sh parallel-gatk-realigner