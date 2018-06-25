<!-- dx-header -->
# Eval predictions with RTG (DNAnexus Platform App)


This is the source code for an app that runs on the DNAnexus Platform.
For more information about how to run or modify it, see
https://wiki.dnanexus.com/.
<!-- /dx-header -->

**What does this app do?**

Performs variant comparison at the haplotype level. It determines whether the genotypes asserted in the VCFs under comparison result in the same genomic sequence when applied to the reference genome.  

**How does this app work?**
 
The app first splits the input calls and baseline variants into SNPs and Indels and index them with [tabix](https://github.com/samtools/htslib). \
Then, [RTG vcfeval](https://github.com/RealTimeGenomics/rtg-tools) is executed on both Indels and SNPs with their respective baselines to perform variant comparison. Finally, Indel and SNP Precision Recall plots are generated from the ROC files with [rtg rocplot](https://github.com/RealTimeGenomics/rtg-tools).\
The app runs inside a Docker image for an improved reproducibility of the results.
 
**What data are required for this app to run?**
 
* The genotype calls, in VCF format.
* The regions where calls are made, in Bed format.
* The RTG template of the reference genome the variants are called against, in SDF format.
* The baseline variants, in VCF format.
* (Optional) The baseline regions, in Bed format.
* Additional variants to intersect with the baseline variants, in VCF format.
* Additional options for RTG vcfeval.      
* The version of the Docker image to use. Default is set to the version that was tested with the app. 
  * **WARNING**:  We discourage to use `latest` as version because runs at different times may give different results if the image changes 

**What does this app output?**
 
 * The results of the rtg evalvcf execution.
 * A summary file of the results.
 * Plot of ROC curves from vcfeval ROC data files.