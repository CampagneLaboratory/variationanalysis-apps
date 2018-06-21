<!-- dx-header -->
# Parallel GATK realigner with filters (DNAnexus Platform App)

This is the source code for an app that runs on the DNAnexus Platform.
For more information about how to run or modify it, see
https://wiki.dnanexus.com/.
<!-- /dx-header -->

**What does this app do?**

Realign BAM alignment with HaplotypeCaller.

**How does this app work?**

This app first (optionally) cleans and reorders the BAM alignment with [picard](https://broadinstitute.github.io/picard/) to match the reference, and then using the _parallel-gatk-realign_ script from [Variation Analysis](https://github.com/CampagneLaboratory/variationanalysis), it realings the BAM with [HaplotypeCaller](https://software.broadinstitute.org/gatk/documentation/tooldocs/3.8-0/org_broadinstitute_gatk_tools_walkers_haplotypecaller_HaplotypeCaller.php) from GATK.  
The app runs inside a Docker image for an improved reproducibility of the results.

**What data are required for this app to run?**

* A coordinate-sorted BAM alignment and its index.
* A Genome in FASTA format compressed with bgzip.
* The distribution of the GATK software used to run HaplotypeCaller in a zipped archive. (we request it because we cannot redistribute GATK as per its license.)
* (Optional) Extra arguments for GATK 4.

**What does this app output?**
* BAM alignment, realigned with HaplotypeCaller, and its index.