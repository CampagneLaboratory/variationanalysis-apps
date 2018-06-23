<!-- dx-header -->
# Convert Somatic .sbi to Tensors (DNAnexus Platform App)
        
This is the source code for an app that runs on the DNAnexus Platform.
For more information about how to run or modify it, see
https://wiki.dnanexus.com/.
<!-- /dx-header -->

**What does this app do?**
Convert Somatic Sequence Base Information (extension .sbi) to Tensors.
 
**How does this app work?**
 
Using the _export-somatic-tensors_ script from [Variation Analysis](https://github.com/CampagneLaboratory/variationanalysis), this app exports Somatic Information in .sbi format to Tensors in .vec/.vecp format.

The app runs inside a Docker image for an improved reproducibility of the results.
 
**What data are required for this app to run?**
 
* Somatic Sequence Base Information.
* Annotation in TSV format (chromosome [TAB] position [TAB] toBase [TAB] somaticFrequency).
* Mapper to use to produce the mapped input output tensors. Mappers are available in the Variation Analysis project.
* Name of the germline sample to store in the .vecp file.
* Name of the tumor sample to store in the .vecp file.   
* The Sampling Rate.
* The organism ploidy (2 for humans, more for some plants).
* Length of genomic context to use around site, in mapped features. Default is 29.
* Value of epsilon for label smoothing. Zero (default) is no smoothing.
* 

**What does this app output?**
 
* Mapped input/output tensors in .vec/.vecp format.
* A single domain.descriptor is exported for all .vec files, describing how the feature/output mapping was done.

