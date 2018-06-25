<!-- dx-header -->
# Extract chromosomes (DNAnexus Platform App)

This is the source code for an app that runs on the DNAnexus Platform.
For more information about how to run or modify it, see
https://wiki.dnanexus.com/.
<!-- /dx-header -->

**What does this app do?**

Extract Chromosomes from BAM alignments

**How does this app work?**

Using the _extract-chromosomes_ script from [Variation Analysis](https://github.com/CampagneLaboratory/variationanalysis), this app creates a BAM alignment with a subset of the chromosomes available in the input BAM.
The app runs inside a Docker image for an improved reproducibility of the results.

**What data are required for this app to run?**

* An alignment in BAM format and its index.
* Space-separated list of chromosomes to extract. E.g. chr16 chr19 chr21.
* The version of the Docker image to use. Default is set to the version that was tested with the app. 
  * **WARNING**:  We discourage to use `latest` as version because runs at different times may give different results if the image changes 

**What does this app output?**
* A filtered BAM alignment and its index containing only the chromosomes specified in the list.
