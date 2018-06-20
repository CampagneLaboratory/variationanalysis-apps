<!-- dx-header -->
# Convert Genotype .sbi to Tensors (DNAnexus Platform App)

This is the source code for an app that runs on the DNAnexus Platform.
For more information about how to run or modify it, see
https://wiki.dnanexus.com/.
<!-- /dx-header -->

**What does this app do?**

Converts Genotype in the Sequence Base Information format (extension .sbi) to Tensors.

**How does this app work?**

Using the _export-genotype-tensors_ script from [Variation Analysis](https://github.com/CampagneLaboratory/variationanalysis), this app converts Genotypes in the .sbi format to tensors in .vec/.vecp format.
The app run inside a Docker image for an improved reproducibility of the results.

**What data are required for this app to run?**

* Datasets in the .sbi/.sbip format. Several datasets may be provided, which will produce distinct .vec/,vecp files. Note that the .sbi must already be annotated with true genotypes.
* A mapper to use to produce the mapped input output tensors. Mappers are available in the Variation Analysis project.
* The name of the sample to store in the .vecp file.
* The organism ploidy (2 for humans, more for some plants).
* The length of genomic context to use around site, in mapped features.
* The value of epsilon for label smoothing. Zero (default) is no smoothing.
* The number of additional genotypes to consider in addition to ploidy. Default is 2.
* The length of the indel sequence. Default is 7.

**What does this app output?**
* Mapped input/output tensors in .vec/.vecp format. A single domain.descriptor is exported for all .vec files, describing how the feature/output mapping was done.
