#!/bin/bash
# parallel-gatk-realigner 0.0.1
# Generated by dx-app-wizard.
#
# Basic execution pattern: Your app will run on a single machine from
# beginning to end.
#
# Your job's input variables (if any) will be loaded as environment
# variables before this script runs.  Any array inputs will be loaded
# as bash arrays.
#
# Any code outside of main() (or any entry point you may add) is
# ALWAYS executed, followed by running the entry point itself.
#
# See https://wiki.dnanexus.com/Developer-Portal for tutorials on how
# to modify this file.

main() {

    mkdir -p /input/scripts/
    mkdir -p /input/Sorted_Bam
    mkdir -p /input/FASTA_Genome
    mkdir -p /out/Realigned_Bam

    echo "Downloading GATK distribution '${GATK_distribution_name}'"
    dx download "${GATK_distribution}" -o /input/GATK/${GATK_distribution_name}
    if [ -s /input/GATK/gatk-4*.zip ]; then
        unzip /input/GATK/gatk-4*.zip
        GATK_DISTRIBUTION=/input/GATK/gatk-4*
        GATK_4=TRUE
    fi
    if [ -s /input/GATK/GenomeAnalysis*.tar.bz2 ]; then
        bunzip2 /input/GATK/GenomeAnalysis*.tar.bz2
        tar -xvf /input/GATK/GenomeAnalysis*.tar
        GATK_DISTRIBUTION=/input/GATK/GenomeAnalysis*
        GATK_3=TRUE
    fi

    #download the sorted bam
    echo "Downloading sorted BAM file '${Sorted_Bam_name}'"
    dx download "${Sorted_Bam}" -o /input/Sorted_Bam/${Sorted_Bam_name}

    echo "Downloading sorted BAM file '${Sorted_Bam_Index_name}'"
    dx download "${Sorted_Bam_Index}" -o /input/Sorted_Bam/${Sorted_Bam_Index_name}

    #download the gzipped genome
    echo "Downloading genome file '${Genome_name}'"
    dx download "${Genome}" -o /input/FASTA_Genome/${Genome_name}
    #unzip
    (cd /input/FASTA_Genome; gunzip ${Genome_name})

    echo "Downloading the docker image..."
    dx-docker pull artifacts/variationanalysis-app:latest &>/dev/null

    #index the genome with samtools and create the dictionary
    genome_name=`basename /input/FASTA_Genome/*.fa* | cut -d. -f1`
    genome_basename=`basename /input/FASTA_Genome/*.fa*`

    cat >/input/scripts/index.sh <<EOL
    #!/bin/bash
    set -x
    ls -lrt  /input/FASTA_Genome/
    cd /input/FASTA_Genome
    samtools faidx /input/FASTA_Genome/*.fa*
    ls -lrt  /input/FASTA_Genome/
    java -jar /root/picard/picard.jar CreateSequenceDictionary R= /input/FASTA_Genome/${genome_basename} O= /input/FASTA_Genome/${genome_name}.dict
EOL
    chmod u+x /input/scripts/index.sh

    #index
    dx-docker run \
        -v /input/:/input \
        artifacts/variationanalysis-app:latest \
        bash -c "source ~/.bashrc; cd /input/FASTA_Genome; /input/scripts/index.sh"

    bam_basename=`basename /input/Sorted_Bam/*.bam | cut -d. -f1`
    cpus=`grep physical  /proc/cpuinfo |grep id|wc -l`

    dx-docker run \
        -v /input/:/input \
        -v /out/:/out \
        artifacts/variationanalysis-app:latest \
        bash -c "source ~/.bashrc; cd /out/Realigned_Bam && sleep 5 && parallel-gatk-realign.sh ${GATK_DISTRIBUTION} 12g ${cpus} /input/FASTA_Genome/${genome_basename} /input/Sorted_Bam/${bam_basename}.bam /out/Realigned_Bam/${bam_basename}-realigned.bam \"${GATK_Arguments}\""


    mkdir -p $HOME/out/Realigned_Bam
    mkdir -p $HOME/out/Realigned_Bam_Index
    mv /out/Realigned_Bam/*-realigned.bam $HOME/out/Realigned_Bam/
    mv /out/Realigned_Bam/*-realigned.bam.bai $HOME/out/Realigned_Bam_Index/
    ls -lrt $HOME/out/Realigned_Bam/
    dx-upload-all-outputs

}
