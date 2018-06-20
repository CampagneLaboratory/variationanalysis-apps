<!-- dx-header -->
# Genotype Tensors (DNAnexus Platform App)

This is the source code for an app that runs on the DNAnexus Platform.
For more information about how to run or modify it, see
https://wiki.dnanexus.com/.
<!-- /dx-header -->

**What does this app do?**

Load the vectorized genotype information from a [Goby](http://campagnelab.org/software/goby/) alignment and write them in the VEC format.

**How does this app work?**

Using the _export-genotype-tensors_ script from [Variation Analysis](https://github.com/CampagneLaboratory/variationanalysis), this app loads the vectorized genotype information from a Goby alignment and generates genotype calls in the VEC format. Most of the computation is executed in parallel with GNU parallel.
The app run inside a Docker image for an improved reproducibility of the results.

**What data are required for this app to run?**

* An alignment in the [Goby](http://campagnelab.org/software/goby/) format.
* The genome that the reads were mapped against, indexed with Goby.
* A Model as a .tar.gz archive, containing the files inside the model directory.
* The name of the model (included in the model archive) to use for genotype calling.
* (Optional) The checkpoint key of the model (included in the model archive) to use for genotype calling. E.g. if the model file is pytorch_YNCRX_best.t7, the checkpoint key is YNCRX.
* Number of slices of the alignment to compute in parallel. Default is 100.
* Options for SBI generation. -n is the lowest number of variations bases at the site to write the site to the SBI. -t is the lowest number of distinct read indices to write the site..
* Name of the sample to store in the .vec properties file.

**What does this app output?**
* The genotype calls, in VCF format. 
* The regions where calls are made, in Bed format.