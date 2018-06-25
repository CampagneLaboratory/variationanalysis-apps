<!-- dx-header -->
# Prepare SBI Unlabeled (DNAnexus Platform App)

This is the source code for an app that runs on the DNAnexus Platform.
For more information about how to run or modify it, see
https://wiki.dnanexus.com/.
<!-- /dx-header -->

**What does this app do?**

Generate the Sequence Base Information format (extension .sbi) unlabeled set from a [Goby](http://campagnelab.org/software/goby/) alignment.

**How does this app work?**

Using _generate-genotype-unlabeled_ script from [Variation Analysis](https://github.com/CampagneLaboratory/variationanalysis), the app creates an unlabeled set in the .sbi format that can be used to train DL callers.
The app runs inside a Docker image for an improved reproducibility of the results.

**What data are required for this app to run?**

* An alignment in the Goby format.
* The genome that the reads were mapped against, indexed with Goby.
* The version of the Docker image to use. Default is set to the version that was tested with the app. 
  * **WARNING**:  We discourage to use `latest` as version because runs at different times may give different results if the image changes 
           
**What does this app output?**

* Unlabeled set in .sbi format. Used to train DL callers.