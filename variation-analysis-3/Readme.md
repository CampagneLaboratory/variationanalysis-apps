<!-- dx-header -->
# Deep Learning Genotype Caller from the Campagne Lab. (DNAnexus Platform App)

This is the source code for an app that runs on the DNAnexus Platform.
For more information about how to run or modify it, see
https://wiki.dnanexus.com/.
<!-- /dx-header -->

**What does this app do?**

Discover sequence variants and predict genotype calls.

**How does this app work?**
 
Using the _parallel-genotype-sbi_ script from [Variation Analysis](https://github.com/CampagneLaboratory/variationanalysis), this app discovers sequence variants in the input alignment. The analysis is executed in parallel according to the number of slices assigned to each computation unit.
The _predict-genotypes-many_ script is executed to process the sequence variants and predict genotype calls (in VCF format).

The app runs inside a Docker image for an improved reproducibility of the results.
 
**What data are required for this app to run?**
 
* An alignment in the [Goby](http://campagnelab.org/software/goby/) format.
* The genome that the reads were mapped against, indexed with Goby.
* Model as a .tar.gz archive, containing the files inside the model directory.
* The name of the model (included in the model archive) to use for genotype calling. Default to "bestscore".
* Number of slices of the alignment to compute in parallel. Default to 100.
* The version of the Docker image to use. Default is set to the version that was tested with the app. 
  * **WARNING**:  We discourage to use `latest` as version because runs at different times may give different results if the image changes 


**What does this app output?**
 
* The genotype calls, in VCF format. 
* The regions where calls are made, in Bed format.
