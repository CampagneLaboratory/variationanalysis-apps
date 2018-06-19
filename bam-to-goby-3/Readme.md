<!-- dx-header -->
# BAM to Goby Converter (DNAnexus Platform App)

Convert alignment from BAM to Goby format

This is the source code for an app that runs on the DNAnexus Platform.
For more information about how to run or modify it, see
https://wiki.dnanexus.com/.
<!-- /dx-header -->

**What does this app do?**

Convert a BAM alignment into an equivalent [Goby](http://campagnelab.org/software/goby/) alignment.

**How does this app work?**

Using the _parallel-bam-to-goby_ script from [variation analysis](https://github.com/CampagneLaboratory/variationanalysis), this app converts an alignment from BAM format to Goby format.
The app run inside a Docker image for an improve reproducibility of the results.

**What data are required for this app to run?**

* An alignment in BAM format and its index.
* A genome in the FASTA format. This must be the genome that the alignment was made against.

**What does this app output?**
* An alignment in the Goby format.
