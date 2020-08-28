<#
.SYNOPSIS
    Update the Configuration Region and run to create Configuration Items and Baselines for Feature Updates.
.DESCRIPTION
    See SYNOPSIS
.PARAMETER SiteCode
    ConfigMgr Site Code
.PARAMETER ProviderMachineName
    ConfigMgr SMS Provider Server.
.PARAMETER LogPath
    A UNC network share that Everyone has write permissions to to copy logs to.    
.PARAMETER FUFilesGUID
    The custom GUID that will be used for "%Windir%\System32\update\run". This GUID needs to match what is used in FU Files App.
.PARAMETER FuTempDir
    The local path to store the scripts for the Feature Update to use. 
    Default is "C:\~FeatureUpdateTemp"
.PARAMETER SetupDiagVersion 
    This should match the version of SetupDiag that you download from MS. ,
    https://docs.microsoft.com/en-us/windows/deployment/upgrade/setupdiag,
    SetupDiag.exe should be placed in the .\Scripts folder before running this script.,
    Default is Looks up the version on SetupDiag.exe
.PARAMETER ScriptsPath
    Local path on client where scripts will be stored
    Default is Path = "C:\~FeatureUpdateTemp\Scripts"
.PARAMETER SetupConfigINIScriptPath 
    Path to SetupConfigINI Script. Default is "$($PSScriptRoot)\ComplianceScripts\New-SetupConfigINI.ps1",
.PARAMETER OSVersionInvScriptPath 
    Path to OSVersionInv Script. Default is "$($PSScriptRoot)\ComplianceScripts\New-WMIRegistryClass-OSVersionHistory.ps1",
.PARAMETER SetupDiagInvScriptPath 
    Path to SetupDiagInv Script. Default is "$($PSScriptRoot)\ComplianceScripts\New-WMIRegistryClass-SetupDiag.ps1",
.PARAMETER SetupDiagDiscoveryScriptPath 
    Path to SetupDiagDiscovery Script. Default is "$($PSScriptRoot)\ComplianceScripts\SetupDiagCI_Dicovery.ps1",
.PARAMETER SetupDiagRemediationScriptPath 
    Path to SetupDiagRemediation Script. Default is "$($PSScriptRoot)\ComplianceScripts\SetupDiagCI_Remediation.ps1",
.PARAMETER NoLoggedOnUserDiscoveryScriptPath 
    Path to NoLoggedOnUserDiscovery Script. Default is "$($PSScriptRoot)\ComplianceScripts\NoLoggedOnUserCI_Discovery.ps1",
.PARAMETER NoLoggedOnUserRemediationScriptPath 
    Path to NoLoggedOnUserRemediation Script. Default is "$($PSScriptRoot)\ComplianceScripts\NoLoggedOnUserCI_Remediation.ps1"

.NOTES
    Version:          1.0
    Author:           Adam Gross - @AdamGrossTX
    GitHub:           https://www.github.com/AdamGrossTX
    WebSite:          https://www.asquaredozen.com
    Creation Date:    08/28/2020
    Release Notes:
        1.0 Initial Script
#>

[cmdletbinding()]
Param (
    [string]$SiteCode = "CRT",
    [string]$ProviderMachineName = "cprthq-ccm01",
    [string]$LogPath = "\\CM01\FeatureUpdateLogs$\FailedLogs",
    [string]$FUFilesGUID = "43434a91-5e86-4871-923b-4b4d44b52992",
    [string]$SetupDiagVersion = (Get-Item -Path "$($PSScriptRoot)\..\Scripts\SetupDiag.exe").VersionInfo.FileVersionRaw.ToString(),
    #Unless you change the default script names or paths, you don't need to edit these.
    [string]$FuTempDir = "C:\~FeatureUpdateTemp",
    [System.IO.FileInfo]$ScriptsPath = "C:\~FeatureUpdateTemp\Scripts",
    [string]$SetupConfigINIScriptPath = "$($PSScriptRoot)\ComplianceScripts\New-SetupConfigINI.ps1",
    [string]$OSVersionInvScriptPath = "$($PSScriptRoot)\ComplianceScripts\New-WMIRegistryClass-OSVersionHistory.ps1",
    [string]$SetupDiagInvScriptPath = "$($PSScriptRoot)\ComplianceScripts\New-WMIRegistryClass-SetupDiag.ps1",
    [string]$SetupDiagDiscoveryScriptPath = "$($PSScriptRoot)\ComplianceScripts\SetupDiagCI_Dicovery.ps1",
    [string]$SetupDiagRemediationScriptPath = "$($PSScriptRoot)\ComplianceScripts\SetupDiagCI_Remediation.ps1",
    [string]$NoLoggedOnUserDiscoveryScriptPath = "$($PSScriptRoot)\ComplianceScripts\NoLoggedOnUserCI_Discovery.ps1",
    [string]$NoLoggedOnUserRemediationScriptPath = "$($PSScriptRoot)\ComplianceScripts\NoLoggedOnUserCI_Remediation.ps1"
)


#region Functions
Function ConnectTo-CMProvider {
    Param(
        [string]$SiteCode,
        [string]$ProviderMachineName
    )
    Try {
        if((Get-Module ConfigurationManager) -eq $null) {
            Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
        }

        # Connect to the site's drive if it is not already present
        if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
            New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName
        }

        # Set the current location to be the site code.
        Set-Location "$($SiteCode):\"
    }
    Catch {
        Throw $_
    }
}
#endregion

Try {
    ###############################################
    #Do Not Edit Below Here
    ###############################################
    $script:tick = [char]0x221a
    Write-Host "Creating Feature Update Configuration Items and Baselines" -ForegroundColor Cyan
    Write-Host "########################################################" -ForegroundColor Cyan
    Write-Host " + Connecting to CMProvider.. " -ForegroundColor Cyan -NoNewline
    ConnectTo-CMProvider -SiteCode $SiteCode -ProviderMachineName $ProviderMachineName
    Write-Host $Script:tick -ForegroundColor green
    

    #region CI Config

    #region SetupConfigINI CI
    $SetupConfigINICI = @{
        Name = "Feature Update - SetupConfig.ini"
        Description = "Updates SetupConfig.ini"
        Category = ".\ConfigurationItem"
        CreationType = "WindowsOS"
    }
    $SetupConfigINICISettings = @{
        ExpressionOperator = "IsEquals"
        DiscoveryScriptText = ((Get-Content -Path $SetupConfigINIScriptPath).Replace('[bool]$Remediate','[bool]$Remediate = $false').Replace('[string]$LogPath',"[string]`$LogPath = `"$($LogPath)`"").Replace('[string]$FuTempDir',"[string]`$FuTempDir = `"$($FUTempDir)`"") | Out-string)
        DiscoveryScriptLanguage = "PowerShell"
        RemediationScriptText = ((Get-Content -Path $SetupConfigINIScriptPath).Replace('[bool]$Remediate','[bool]$Remediate = $true').Replace('[string]$LogPath',"[string]`$LogPath = `"$($LogPath)`"").Replace('[string]$FuTempDir',"[string]`$FuTempDir = `"$($FUTempDir)`"") | Out-string)
        RemediationScriptLanguage = "PowerShell"
        DataType = "String"
        Name = "SetupConfig"
        Is64Bit = $true
        RuleName = "All Values Current"
        ValueRule = $true
        ExpectedValue = "Compliant"
        Remediate = $true
        NoncomplianceSeverity = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::Critical
        ReportNoncompliance = $true
    }
    #endregion

    #region OS Version History Inventory CI
    $OSVersionHistoryInventoryCI = @{
        Name = "OS Version Inventory"
        Description = "Inventories Windows Setup History"
        Category = ".\ConfigurationItem"
        CreationType = "WindowsOS"
    }
    $OSVersionHistoryInventoryCISettings = @{
        DiscoveryScriptText = (Get-Content -Path $OSVersionInvScriptPath | Out-string)
        DiscoveryScriptLanguage = "PowerShell"
        DataType = "String"
        Name = "OS Version History WMI Create Class and Inventory"
        Is64Bit = $true
        RuleName = "Script Returns True"
        ValueRule = $true
        ExpectedValue = "True"
        ExpressionOperator = "IsEquals"
        NoncomplianceSeverity = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::Critical
    }
    #endregion

    #region SetupDiag Inventory CI
    $SetupDiagInventoryCI = @{
        Name = "Feature Update - SetupDiag Inventory"
        Description = "Inventories SetupDiag Results Registry Key"
        Category = ".\ConfigurationItem"
        CreationType = "WindowsOS"
    }
    $SetupDiagInventoryCISettings = @{
        DiscoveryScriptText = (Get-Content -Path $SetupDiagInvScriptPath | Out-string)
        DiscoveryScriptLanguage = "PowerShell"
        DataType = "String"
        Name = "SetupDiag WMI Create Class and Inventory"
        Is64Bit = $true
        RuleName = "Script Returns True"
        ValueRule = $true
        ExpectedValue = "True"
        ExpressionOperator = "IsEquals"
        NoncomplianceSeverity = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::Critical
    }
    #endregion

    #region SetupDiag Results CI
    $SetupDiagResultsCI = @{
        Name = "Feature Update - SetupDiag Results"
        Description = "Checks to see if SetupDiag has ever run. If not, runs SetupDiag"
        Category = ".\ConfigurationItem"
        CreationType = "WindowsOS"
    }
    $SetupDiagResultsCISettings = @{
        ExpressionOperator = "IsEquals"
        DiscoveryScriptText = (Get-Content -Path $SetupDiagDiscoveryScriptPath | Out-string)
        DiscoveryScriptLanguage = "PowerShell"
        RemediationScriptText = (Get-Content -Path $SetupDiagRemediationScriptPath | Out-string)
        RemediationScriptLanguage = "PowerShell"
        DataType = "Boolean"
        Name = "SetupDiag Results Registry is Success or Failed"
        Is64Bit = $true
        RuleName = "SetupDiag Key Exists"
        ValueRule = $true
        ExpectedValue = $true
        Remediate = $true
        NoncomplianceSeverity = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::Critical
        ReportNoncompliance = $true
    }
    #endregion

    #region SetupDiag Version CI
    $SetupDiagVersionCI = @{
        Name = "Feature Update - SetupDiag Version"
        Description = "Ensures that SetupDiag is the Correct Version"
        Category = ".\ConfigurationItem"
        CreationType = "WindowsOS"
    }

    $SetupDiagVersionCISettings = @{
        FileName = "SetupDiag.exe"
        IncludeSubfolders = $True
        Path = "$($ScriptsPath)"
        Description = $null
        Name = "SetupDiag Version $($SetupDiagVersion) Exists"
        NoRule = $true
    }

    $SetupDiagVersionCIRule_Exists = @{
        Existence = "MustExist"
        RuleName = "SetupDiag.exe must exist"
        NoncomplianceSeverity = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::Critical
        RuleDescription = $null
    }

    $SetupDiagVersionCIRule_Version = @{
        PropertyType = "Version"
        ExpressionOperator = "SetEquals"
        ReportNoncompliance = $True
        RuleName = "SetupDiag.exe Version = $($SetupDiagVersion)"
        ExpectedValue = "$($SetupDiagVersion)"
        NoncomplianceSeverity = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::Critical
        RuleDescription = $null
    }
    #endregion

    #region NoLoggedOnUser CI
    $NoLoggedOnUserCI = @{
        Name = "Feature Update - No logged on interactive user - Failed"
        Description = "Detects and remediates devices where Feature Update returns error -2149842976"
        Category = ".\ConfigurationItem"
        CreationType = "WindowsOS"
    }

    $NoLoggedOnUserCISettings = @{
        ExpressionOperator = "IsEquals"
        DiscoveryScriptText = (Get-Content -Path $NoLoggedOnUserDiscoveryScriptPath | Out-string)
        DiscoveryScriptLanguage = "PowerShell"
        RemediationScriptText = (Get-Content -Path $NoLoggedOnUserRemediationScriptPath | Out-string)
        RemediationScriptLanguage = "PowerShell"
        DataType = "String"
        Name = "Failed Feature Update - No logged on interactive user"
        Is64Bit = $true
        RuleName = "Compliant"
        ValueRule = $true
        ExpectedValue = "Compliant"
        Remediate = $true
        NoncomplianceSeverity = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::Critical
        ReportNoncompliance = $true
    }
    #endregion

    #region FU Files CI
    $FUFilesCI = @{
        Name = "Feature Update - Feature Update Files"
        Description = "Ensures that all feature update scripts and files have been staged"
        Category = ".\ConfigurationItem"
        CreationType = "WindowsOS"
    }

    $FUFilesCIUpdateFilesExistsSettings = @{
        FileName = $FUFilesGUID
        IncludeSubfolders = $True
        Path = "%Windir%\System32\update\run"
        Description = $null
        Name = "%Windir%\System32\update\run\$($FUFilesGUID) exists"
        NoncomplianceSeverity = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::Critical
        RuleDescription = $null
        RuleName = "%Windir%\System32\update\run\$($FUFilesGUID) folder must exist"
        Existence = "MustExist"
        ExistentialRule = $true
    }

    $FUFilesCIScriptsExistsSettings = @{
        FileName = $ScriptsPath.Name
        IncludeSubfolders = $True
        Path = $ScriptsPath.Directory
        Description = $null
        Name = "$($ScriptsPath.Name) exists"
        NoncomplianceSeverity = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::Critical
        RuleDescription = $null
        RuleName = "$($ScriptsPath.Name) folder must exist"
        Existence = "MustExist"
        ExistentialRule = $true
    }

    #region Baselines
    $InventoryBaseline = @{
        Name = "Feature Update - Inventory OSVersionHistory and SetupDiag"
        Description = "Inventories SetupDiag and OS Version History"
    }

    $NoLoggedOnUserBaseline = @{
        Name = "Feature Update - No Logged On User Failure"
        Description = "Check for failed Feature Update due to no logged on user error."
    }

    $FUFilesBaseline = @{
        Name = "Feature Update - Scripts and Files Are Present"
        Description = "Updates SetupConfig.ini and ensures that required Feature Update scripts are present on the device."
    }
    #endregion

    #endregion

    #endregion


    ###############################################
    #region CI Creation

    Write-Host " + Creating $($SetupConfigINICI.Name) Configuration Item.. " -ForegroundColor Cyan -NoNewline
    $NewSetupConfigINICI = New-CMConfigurationItem @SetupConfigINICI
    $NewSetupConfigINICI = $NewSetupConfigINICI | Add-CMComplianceSettingScript @SetupConfigINICISettings
    Write-Host $Script:tick -ForegroundColor green

    Write-Host " + Creating $($OSVersionHistoryInventoryCI.Name) Configuration Item.. " -ForegroundColor Cyan -NoNewline
    $NewOSVersionHistoryInventoryCI = New-CMConfigurationItem @OSVersionHistoryInventoryCI
    $NewOSVersionHistoryInventoryCI = $NewOSVersionHistoryInventoryCI | Add-CMComplianceSettingScript @OSVersionHistoryInventoryCISettings
    Write-Host $Script:tick -ForegroundColor green

    Write-Host " + Creating $($SetupDiagInventoryCI.Name) Configuration Item.. " -ForegroundColor Cyan -NoNewline
    $NewSetupDiagInventoryCI = New-CMConfigurationItem @SetupDiagInventoryCI
    $NewSetupDiagInventoryCI = $NewSetupDiagInventoryCI | Add-CMComplianceSettingScript @SetupDiagInventoryCISettings
    Write-Host $Script:tick -ForegroundColor green

    Write-Host " + Creating $($SetupDiagVersionCI.Name) Configuration Item.. " -ForegroundColor Cyan -NoNewline
    $NewSetupDiagVersionCI = New-CMConfigurationItem @SetupDiagVersionCI
    $NewSetupDiagVersionCI = $NewSetupDiagVersionCI | Add-CMComplianceSettingFile @SetupDiagVersionCISettings
    $NewSetupDiagVersionCISettings = $NewSetupDiagVersionCI | Get-CMComplianceSetting -SettingName $SetupDiagVersionCISettings.Name
    $NewSetupDiagVersionCIRule_Exists = $NewSetupDiagVersionCISettings | New-CMComplianceRuleExistential @SetupDiagVersionCIRule_Exists
    $NewSetupDiagVersionCI = $NewSetupDiagVersionCI | Add-CMComplianceSettingRule -Rule $NewSetupDiagVersionCIRule_Exists
    #This Cmdlet is incomplete and doesn't support all of the PropertyTypes required to make this work.
    #$NewSetupDiagVerCISettingRule_version = $NewSetupDiagVersionCISettings | New-CMComplianceRuleFileFolderSimple @SetupDiagVersionCIRule_Version
    #$NewSetupDiagVersionCI = $NewSetupDiagVersionCI | Add-CMComplianceSettingRule -Rule $SetupDiagVerCISettingRule_version
    Write-Host $Script:tick -ForegroundColor green

    Write-Host " + Creating $($SetupDiagResultsCI.Name) Configuration Item.. " -ForegroundColor Cyan -NoNewline
    $NewSetupDiagResultsCI = New-CMConfigurationItem @SetupDiagResultsCI
    $NewSetupDiagResultsCI = $NewSetupDiagResultsCI | Add-CMComplianceSettingScript @SetupDiagResultsCISettings
    Write-Host $Script:tick -ForegroundColor green

    Write-Host " + Creating $($NoLoggedOnUserCI.Name) Configuration Item.. " -ForegroundColor Cyan -NoNewline
    $NewNoLoggedOnUserCI = New-CMConfigurationItem @NoLoggedOnUserCI
    $NewNoLoggedOnUserCI = $NewNoLoggedOnUserCI | Add-CMComplianceSettingScript @NoLoggedOnUserCISettings
    Write-Host $Script:tick -ForegroundColor green

    Write-Host " + Creating $($FUFilesCI.Name) Configuration Item.. " -ForegroundColor Cyan -NoNewline
    $FUFilesCI = New-CMConfigurationItem @FUFilesCI
    $FUFilesCI = $FUFilesCI | Add-CMComplianceSettingFile @FUFilesCIUpdateFilesExistsSettings
    $FUFilesCI = $FUFilesCI | Add-CMComplianceSettingFile @FUFilesCIScriptsExistsSettings
    Write-Host $Script:tick -ForegroundColor green

    Write-Host " + Creating $($FUFilesBaseline.Name) Baseline.. " -ForegroundColor Cyan -NoNewline
    $FUFilesBaseline = New-CMBaseline @FUFilesBaseline
    $FUFilesBaseline | Set-CMBaseline -AddOSConfigurationItem ($NewSetupDiagVersionCI.CI_ID,$NewSetupConfigINICI.CI_ID,$FUFilesCI.CI_ID)
    Write-Host $Script:tick -ForegroundColor green

    Write-Host " + Creating $($NoLoggedOnUserBaseline.Name) Baseline.. " -ForegroundColor Cyan -NoNewline
    $NewNoLoggedOnUserBaseline = New-CMBaseline @NoLoggedOnUserBaseline
    $NewNoLoggedOnUserBaseline | Set-CMBaseline -AddOSConfigurationItem ($NewNoLoggedOnUserCI.CI_ID)
    Write-Host $Script:tick -ForegroundColor green

    Write-Host " + Creating $($InventoryBaseline.Name) Baseline.. " -ForegroundColor Cyan -NoNewline
    $NewInventoryBaseline = New-CMBaseline @InventoryBaseline
    $NewInventoryBaseline | Set-CMBaseline -AddOSConfigurationItem ($NewSetupDiagInventoryCI.CI_ID,$NewSetupDiagResultsCI.CI_ID,$NewOSVersionHistoryInventoryCI.CI_ID)
    Write-Host $Script:tick -ForegroundColor green

    Write-Host " --NOTICE--" -ForegroundColor Yellow
    Write-Host " -- To complete this setup, add a Version detection Rule for SetupDiag.exe to the $($SetupDiagVersionCI.Name) CI." -ForegroundColor Yellow
    Write-Host "-------------------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "-- Rule Name:      SetupDiag.exe Version = $($SetupDiagVersion)" -ForegroundColor DarkCyan
    Write-Host "-- Rule Type:      Value" -ForegroundColor DarkCyan
    Write-Host "-- Property:       File Version" -ForegroundColor DarkCyan
    Write-Host "-- Type            Equals" -ForegroundColor DarkCyan
    Write-Host "-- Value:          $($SetupDiagVersion)" -ForegroundColor DarkCyan
    Write-Host "-- NonCompliance : Critical" -ForegroundColor DarkCyan
    Write-Host "-------------------------------------------------------------" -ForegroundColor DarkCyan

    Write-Host "########################################################" -ForegroundColor Cyan
    Write-Host " + Done! " -ForegroundColor Cyan -NoNewline
    Write-Host $Script:tick -ForegroundColor green
}
Catch {
    Throw $_
}

#endregion



