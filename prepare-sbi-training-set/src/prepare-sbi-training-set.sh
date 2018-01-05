#!/bin/bash
# prepare-sbi-training-set 0.0.1

main() {

    # Fill in your application code here.
    #
    # To report any recognized errors in the correct format in
    # $HOME/job_error.json and exit this script, you can use the
    # dx-jobutil-report-error utility as follows:
    #
    #   dx-jobutil-report-error "My error message"
    #
    # Note however that this entire bash script is executed with -e
    # when running in the cloud, so any line which returns a nonzero
    # exit code will prematurely exit the script; if no error was
    # reported in the job_error.json file, then the failure reason
    # will be AppInternalError with a generic error message.
     # create the data directories to mount into the Docker container
    mkdir -p /input/indexed_genome
    mkdir -p /input/alignment
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

    dx-docker pull artifacts/variationanalysis-app:latest

    # configure
    genome_basename=`basename /input/indexed_genome/*.bases | cut -d. -f1`
    echo "export SBI_GENOME=/input/indexed_genome/${genome_basename}" >> /input/configure.sh
    alignment_basename=`basename /input/alignment/*.entries | cut -d. -f1`
    echo "export GOBY_ALIGNMENT=/input/alignment/${alignment_basename}" >> /input/configure.sh
    echo "export GOBY_NUM_SLICES=1" >> /input/configure.sh
    # adjust num threads to match number of cores -1:
    cpus=`grep physical  /proc/cpuinfo |grep id|wc -l`
    echo "export SBI_NUM_THREADS=${cpus}" >> /input/configure.sh
    echo "export INCLUDE_INDELS='true'" >> /input/configure.sh
    echo "export REALIGN_AROUND_INDELS='false'" >> /input/configure.sh
    echo "export REF_SAMPLING_RATE='1.0'" >> /input/configure.sh
    echo "export OUTPUT_BASENAME=${alignment_basename}" >> /input/configure.sh
    echo "export DO_CONCAT='true'" >> /input/configure.sh
    cat /input/configure.sh

    dx-docker run \
        -v /input/:/input \
        -v /output/sbi:/output/sbi \
        artifacts/variationanalysis-app:latest \
        bash -c "source ~/.bashrc; source /input/configure.sh; cd /output/sbi; parallel-genotype-sbi.sh 10g \"/input/alignment/${alignment_basename}\" 2>&1 | tee parallel-genotype-sbi.log"

    ls -lrt /output/sbi
    mkdir -p /output/randomized-sbi

    cat >/input/scripts/randomize.sh <<EOL
     #!/bin/bash
     randomize.sh 10g -i /output/sbi/${alignment_basename}-pre-train.sbi -o /output/randomized-sbi/${alignment_basename}-train
     randomize.sh 10g -i /output/sbi/${alignment_basename}-pre-validation.sbi -o /output/randomized-sbi/${alignment_basename}-validation
     cp ${alignment_basename}-test.sbi* /output/randomized-sbi/
EOL
    dx-docker run \
        -v /input/:/input \
        -v /output/:/output \
        artifacts/variationanalysis-app:latest \
        bash -c "source ~/.bashrc; cd /output/randomized-sbi; /input/scripts/randomize.sh "

    mkdir -p $HOME/out/SBI
    mv /output/randomized-sbi/*.sbi* $HOME/out/SBI/
    ls -lrt $HOME/out/SBI/

    dx-upload-all-outputs
}
