
# Windows 10 Feature Updates Scripts

Use these scripts to manage Feature Update deployments and leverage all of the pre and post script functionality available.

Each file has comments/examples.

1. Go to https://docs.microsoft.com/en-us/windows/deployment/upgrade/setupdiag and download the latest copy of SetupDiag. Everything is build on version 1.5.0.0 currently. Add setupdiag.exe to the Scripts folder included in the download content. Replace the ADD_SETUPDIAG_HERE.MD file.
2. Create a new Application in SCCM and a Deployment Type.
3. The Content for the DT will be everything in this Repo (except this readme file and Update-SetupConfigCI.ps1)
4. The cmdlines for the new application DT are:

### Install
```
Powershell.exe -ExecutionPolicy ByPass -File Copy-FUFiles.PS1
````
### Repair
```
Powershell.exe -ExecutionPolicy ByPass -File Copy-FUFiles.PS1
```
### Uninstall
```
Powershell.exe -ExecutionPolicy ByPass -File Copy-FUFiles.PS1 -RemoveOnly
```

5. Create a new SCCM Configuration Item and BaseLine using the Update-SetupConfigCI.ps1 script contents
6. Be sure to set Remediate=$True for the Remediation script in the CI.
7. Deploy the CI and Application to your target devices, install/run the app and CI, then launch your Feature Update.

# Blog Post Coming...
