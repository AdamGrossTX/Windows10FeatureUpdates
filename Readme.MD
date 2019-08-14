
# Windows 10 Feature Updates Scripts

Use these scripts to manage Feature Update deployments and leverage all of the pre and post script functionality available.

Each file has comments/examples.

1. Create a new Application in SCCM and a Deployment Type.
2. The Content for the DT will be everything in this Repo (except this readme file and Update-SetupConfigCI.ps1)
3. The cmdlines for the new application DT are:

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

4. Create a new SCCM Configuration Item and BaseLine using the Update-SetupConfigCI.ps1 script contents
5. Be sure to set Remediate=$True for the Remediation script in the CI.
6. Deploy the CI and Application to your target devices, install/run the app and CI, then launch your Feature Update.
7. Create another CI to run the Custom-WMIClass.ps1 contents. Then the new CM_SetupDiag class into your SCCM Client Settings Hardware Inventory per https://docs.microsoft.com/en-us/sccm/core/clients/manage/inventory/extend-hardware-inventory#BKMK_Add

# Blog Post Coming...