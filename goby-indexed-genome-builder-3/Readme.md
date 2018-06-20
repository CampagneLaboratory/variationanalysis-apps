<!-- dx-header -->
# Goby Indexed Genome Builder (DNAnexus Platform App)

This is the source code for an app that runs on the DNAnexus Platform.
For more information about how to run or modify it, see
https://wiki.dnanexus.com/.
<!-- /dx-header -->

**What does this app do?**

Build a [Goby](http://campagnelab.org/software/goby/) Indexed Genome from a FASTA reference genome.

**How does this app work?**

Using Goby, this app converts an Indexed Genome from FASTA format to Goby format.
The app run inside a Docker image for an improved reproducibility of the results.

**What data are required for this app to run?**

* A genome in the FASTA format, compressed with gzip.

**What does this app output?**
* Goby indexed genome.
