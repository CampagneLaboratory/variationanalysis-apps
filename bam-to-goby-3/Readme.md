<!-- dx-header -->
# BAM to Goby Converter (DNAnexus Platform App)

This is the source code for an app that runs on the DNAnexus Platform.
For more information about how to run or modify it, see
https://wiki.dnanexus.com/.
<!-- /dx-header -->

**What does this app do?**

Convert a BAM alignment into an equivalent [Goby](http://campagnelab.org/software/goby/) alignment.

**How does this app work?**

Using the _parallel-bam-to-goby_ script from [Variation Analysis](https://github.com/CampagneLaboratory/variationanalysis), this app converts an alignment from BAM format to Goby format.
The app runs inside a Docker image for an improved reproducibility of the results.

**What data are required for this app to run?**

* An alignment in BAM format and its index.
* A genome in the FASTA format. This must be the genome that the alignment was made against.
* The version of the Docker image to use. Default is set to the version that was tested with the app. 
  * **WARNING**:  We discourage to use `latest` as version because runs at different times may give different results if the image changes 

**What does this app output?**
* An alignment in the Goby format.
