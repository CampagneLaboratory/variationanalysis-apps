<!-- dx-header -->
# Prepare SBI training set (DNAnexus Platform App)

This is the source code for an app that runs on the DNAnexus Platform.
For more information about how to run or modify it, see
https://wiki.dnanexus.com/.
<!-- /dx-header -->

**What does this app do?**

Use parallel genotype calls to generate the training set in Sequence Base Information format (extension .sbi).

**How does this app work?**

Using the _generate-genotype-sets-0.02_ script from [Variation Analysis](https://github.com/CampagneLaboratory/variationanalysis), it makes parallel genotype calls to generate Sequence Base Information's sets that can be used to train DL callers.
The app runs inside a Docker image for an improved reproducibility of the results.

**What data are required for this app to run?**

* One or several alignments in the [Goby](http://campagnelab.org/software/goby/) format.
* The genome that the reads were mapped against, indexed with Goby.
* True Genotypes in VCF format.
* (Optional) An optional chromosome prefix adjustment. Use -chr to remove chr from the start of reference id in the VCF. Use +chr to add chr at the start of reference id in the VCF. Use when the alignment and VCF disagree on the chromsome prefix.
* Options provided to goby when exporting the sbi files. -n controls how many bases need to be different from the reference for the base to be output. -t indicates how many distinct read indices need to be observed at a site for this site to be output.
* (Optional) Fraction of input reads to load. A number between 0 and 1, where 1 indicate to keep all reads.
* The version of the Docker image to use. Default is set to the version that was tested with the app. 
  * **WARNING**:  We discourage to use `latest` as version because runs at different times may give different results if the image changes 
              
**What does this app output?**
* Training, validation and test set in .sbi format. Used to train DL callers. 