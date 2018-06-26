<!-- dx-header -->
# Goby Indexed Genome Builder (DNAnexus Platform App)

This is the source code for an app that runs on the DNAnexus Platform.
For more information about how to run or modify it, see
https://wiki.dnanexus.com/.
<!-- /dx-header -->

**What does this app do?**

Build a [Goby](http://campagnelab.org/software/goby/) Indexed Genome from a FASTA Reference Genome.

**How does this app work?**

Using Goby, this app converts an Indexed Genome from FASTA format to Goby format.
The app runs inside a Docker image for an improved reproducibility of the results.

**What data are required for this app to run?**

* A genome in the FASTA format, compressed with bgzip.
* The version of the Docker image to use. Default is set to the version that was tested with the app. 
  * **WARNING**:  We discourage to use `latest` as version because runs at different times may give different results if the image changes 


**What does this app output?**
* Goby Indexed Genome.
