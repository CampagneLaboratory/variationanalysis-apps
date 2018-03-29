#!/bin/bash
# prepare-sbi-training-set 0.0.1

main() {

    mkdir -p /input/indexed_genome
    mkdir -p /input/alignment
    mkdir -p /input/vcf
    mkdir -p /output/sbi
    mkdir -p /output/vcf

    for i in "${!Genome[@]}"; do
        echo "Downloading genome file '${Genome_name[$i]}'"
        dx download "${Genome[$i]}" -o /input/indexed_genome/${Genome_name[$i]}
    done

    for i in "${!Goby_Alignment[@]}"; do
        echo "Downloading goby alignment file '${Goby_Alignment_name[$i]}'"
        dx download "${Goby_Alignment[$i]}" -o /input/alignment/${Goby_Alignment_name[$i]}
    done

    echo "Downloading true labels VCF file '${True_Genotypes_name}'"
    dx download "${True_Genotypes}" -o /input/vcf/${True_Genotypes_name}

    dx-docker pull artifacts/variationanalysis-app:${Image_Version} &>/dev/null

    # configure
    genome_basename=`basename /input/indexed_genome/*.bases | cut -d. -f1`
    echo "export SBI_GENOME=/input/indexed_genome/${genome_basename}" >> /input/configure.sh
    alignment_basename=`basename /input/alignment/*.entries | cut -d. -f1`
    echo "export GOBY_ALIGNMENT=/input/alignment/${alignment_basename}" >> /input/configure.sh
    echo "export GOBY_NUM_SLICES=1" >> /input/configure.sh
    # adjust num threads to match number of cores -1:
    cpus=`grep physical  /proc/cpuinfo |grep id|wc -l`
    cpus=`echo $(( cpus / 3 * 2  ))`
    basename="${alignment_basename}"
    echo "export SBI_NUM_THREADS=${cpus}" >> /input/configure.sh
    echo "export INCLUDE_INDELS='true'" >> /input/configure.sh
    echo "export REALIGN_AROUND_INDELS='false'" >> /input/configure.sh
    echo "export REF_SAMPLING_RATE='0.01'" >> /input/configure.sh
    echo "export OUTPUT_PREFIX=${basename}" >> /input/configure.sh
    echo "export DATASET=${basename}" >> /input/configure.sh
    echo "export GOBY_NUM_SLICES='50'" >> /input/configure.sh
    echo "export DO_CONCAT='true'" >> /input/configure.sh
    echo "export VARMAP_CHR_PREFIX='${Varmap_Prefix_Adjustment}'" >> /input/configure.sh


    if [ "${Varmap_Prefix_Adjustment}" == "-chr" ]; then
        CHR=" "
    else
        CHR="chr"
    fi
    echo $CHR
    echo "export CHR='${CHR}'" >> /input/configure.sh

    cat /input/configure.sh

    # Run generate-genotype-sets-0.02.sh
    dx-docker run \
        -v /input/:/input \
        -v /output/sbi:/output/sbi \
        artifacts/variationanalysis-app:${Image_Version} \
        bash -c "source ~/.bashrc; source /input/configure.sh; cd /output/sbi; generate-genotype-sets-0.02.sh 20g \"/input/alignment/${alignment_basename}\" \"/input/vcf/${True_Genotypes_name}\" \"/input/indexed_genome/${genome_basename}\"  2>&1 | tee parallel-genotype-sbi.log"

    ls -lrt /output/sbi

    # Arrange dataset in output directory and upload:
    mkdir -p $HOME/out/SBI
    mv /output/sbi/${basename}*-train.sbi* $HOME/out/SBI/ || true
    mv /output/sbi/${basename}*-validation.sbi* $HOME/out/SBI/ || true
    mv /output/sbi/${basename}*-test.sbi* $HOME/out/SBI/  || true
    ls -lrt $HOME/out/SBI/

    dx-upload-all-outputs --parallel
}
