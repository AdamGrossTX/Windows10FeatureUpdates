# Windows 10 Feature Updates Scripts

Use these scripts to manage Feature Update deployments using Windows 10 Servicing (instead of Task Sequences) and leverage all of the pre and post script functionality available.

Each file has comments/examples. I've included an Application and a Configuration Baseline that you can import to get you started. These files are under the ~SourceFiles folder.

Using the included Baseline and/or Application follow these steps:

### Application
1. Add the following folders/files from this repo to your source files share:
    - Scripts (including all files)
    - Update (including all files)
    - Copy-FeatureUpdateFiles.ps1
    - Process-Content.ps1
1. Import the included ~SourceFiles\Feature Update Scripts - Application.zip
1. Change the content source for the Deployment Type to point to the new content created in step 

### Configuration Baseline
1. Import the Configuration Baseline
1. Edit the Feature Update - SetupConfig.ini CI detection and remediation scripts to include the correct log path and line items you need for your environment. A copy of this script is included in the repo Update-SetupConfigCI.ps1.
1. Set Remediate=$True for the Remediation script in the CI.

### Deployment 
1. Deploy the application and baselines to test machines then install a Feature Update.

### Custom WMI Inventory Class 
1. Create another CI to run the Custom-WMIClass.ps1 contents. 
1. Import the new CM_SetupDiag class into your SCCM Client Settings Hardware Inventory per https://docs.microsoft.com/en-us/sccm/core/clients/manage/inventory/extend-hardware-inventory#BKMK_Add


### Blog Post
I Will be posting a blog series to go with these scripts shortly. Please check there http://www.asquaredozen.com for updates. I will go into more detail about the scripts and processes for manually building everything.

