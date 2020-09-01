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
.PARAMETER FUTempPath
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
    [string]$SiteCode = "PS1",
    [string]$ProviderMachineName = "CM01.ASD.NET",    
    [string]$ApplicationFolderName = "FUApplication",
    [string]$ContentLocation = "\\CM01.ASD.NET\Media\$($ApplicationFolderName)",
    [string]$NetworkLogPath = "\\CM01.ASD.NET\FeatureUpdateLogs",
    
    #Unless you change the default script names or paths, you don't need to edit these.
    [string]$FUFilesGUID = (New-Guid).Guid.ToString(),
    [string]$PublisherName = "A Square Dozen",
    [string]$ApplicationName = "Feature Update - Client Content",
    [string]$FUTempPath = "C:\~FeatureUpdateTemp",
    [string]$LogPath = "C:\Windows\CCM\Logs",
    [string]$LogPrefix = "FeatureUpdate",
    [string]$OutputPathRoot = "$($PSScriptRoot)\$($ApplicationFolderName)",

    [System.IO.FileInfo]$ScriptsPath = "$($FUTempPath)\Scripts",
    [string]$SetupConfigINIScriptPath = "$($PSScriptRoot)\Templates\New-SetupConfigINI.ps1",
    [string]$OSVersionInvScriptPath = "$($PSScriptRoot)\Templates\New-WMIRegistryClass-OSVersionHistory.ps1",
    [string]$SetupDiagInvScriptPath = "$($PSScriptRoot)\Templates\New-WMIRegistryClass-SetupDiag.ps1",
    [string]$SetupDiagDiscoveryScriptPath = "$($PSScriptRoot)\Templates\SetupDiagCI_Dicovery.ps1",
    [string]$SetupDiagRemediationScriptPath = "$($PSScriptRoot)\Templates\SetupDiagCI_Remediation.ps1",
    [string]$NoLoggedOnUserDiscoveryScriptPath = "$($PSScriptRoot)\Templates\NoLoggedOnUserCI_Discovery.ps1",
    [string]$NoLoggedOnUserRemediationScriptPath = "$($PSScriptRoot)\Templates\NoLoggedOnUserCI_Remediation.ps1",
    [string]$CopyFeatureUpdateFilesScriptPath = "$($PSScriptRoot)\Templates\Copy-FeatureUpdateFiles.ps1",
    [string]$ProcessFeatureUpdateLogsScriptPath = "$($PSScriptRoot)\Templates\Process-FeatureUpdateLogs.ps1",
    [string]$ProcessSetupDiagScriptPath = "$($PSScriptRoot)\Templates\Process-SetupDiag.ps1",

    #cmdFiles
    [string]$SetupCompleteTemplatePath = "$($PSScriptRoot)\Templates\SetupComplete.cmd",
    [string]$failureTemplatePath = "$($PSScriptRoot)\Templates\failure.cmd",
    [string]$precommitTemplatePath = "$($PSScriptRoot)\Templates\precommit.cmd",
    [string]$preinstallTemplatePath = "$($PSScriptRoot)\Templates\preinstall.cmd",
    [string]$postuninstallTemplatePath = "$($PSScriptRoot)\Templates\postuninstall.cmd",
    [string]$successTemplatePath = "$($PSScriptRoot)\Templates\success.cmd",

    [string]$SetupCompleteScript = "Process-FeatureUpdateLogs.ps1",
    [string]$failureScript = "Process-FeatureUpdateLogs.ps1",
    [string]$precommitScript = $null,
    [string]$preinstallScript = $null,
    #Windows 10 2004 and later only
    [string]$postuninstallScript = "Process-FeatureUpdateLogs.ps1",
    #Windows 10 2004 and later only
    [string]$successScript = "Process-FeatureUpdateLogs.ps1"
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

Function New-FUCmdFile {
    [cmdletbinding()]
    Param(
        [string]$TemplateSource,
        [string]$CommandName,
        [string]$LogPath = $script:LogPath,
        [string]$LogPrefix = $script:LogPrefix,
        [string]$ScriptsPath = $script:ScriptsPath,
        [string]$ScriptNameAndParams,
        [string]$OutputFolder,
        [string]$OutputRoot = $script:OutputPathRoot

    )
    try {
        set-location c:
        If(Test-Path $TemplateSource -ErrorAction SilentlyContinue) {
            $NewOutputFolder = Join-Path -Path $OutputRoot -ChildPath $OutputFolder
            Write-Host " + Generating $($CommandName).cmd in $($NewOutputFolder)" -ForegroundColor Cyan -NoNewline
            New-Item -Path $NewOutputFolder -ItemType Directory -Force | Out-Null
            $TemplateContent = Get-Content -Path $TemplateSource -Raw
            If($TemplateContent) {
                $NewContent = $TemplateContent.Replace("%%CommandName%%",$CommandName).Replace("%%LogPath%%",$LogPath).Replace("%%LogPrefix%%",$LogPrefix).Replace("%%ScriptsPath%%",$ScriptsPath).Replace("%%ScriptNameAndParams%%",$ScriptNameAndParams)
                $NewContent | Out-File -FilePath (Join-Path -Path $NewOutputFolder -ChildPath "$($CommandName).cmd") -Force -Encoding Default
                Write-Host $Script:tick -ForegroundColor green
                }
            Else {
                "The template $($TemplateSource) for $($CommandName).cmd could not be found. Exiting."
            }
        }
        Else {
            Throw "The template $($TemplateSource) for $($CommandName).cmd could not be found. Exiting."
        }
    }
    catch {
        throw $_
    }
}

#endregion

Try {
    $script:tick = [char]0x221a
    $SetupDiagPath = "$($PSScriptRoot)\Content\Scripts\SetupDiag.exe"
    If(Test-Path -Path $SetupDiagPath -ErrorAction SilentlyContinue) {
        [string]$SetupDiagVersion = (Get-Item -Path $SetupDiagPath).VersionInfo.FileVersionRaw.ToString()
    }
    Else {
        Throw "SetupDiag is missing from $SetupDiagPath. Please download the latest setupdiag and copy to $SetupDiagPath."
    }
    
    ###############################################
    #Do Not Edit Below Here
    ###############################################

    #region CMD Config
    $SetupCompleteConfig = @{
        TemplateSource = $SetupCompleteTemplatePath
        CommandName = "SetupComplete"
        ScriptNameAndParams = $SetupCompleteScript
        OutputFolder = "Scripts"
    }

    $FailureConfig = @{
        TemplateSource = $failureTemplatePath
        CommandName = "failure"
        ScriptNameAndParams = $failureScript
        OutputFolder = "Update"
    }

    $PreCommitConfig = @{
        TemplateSource = $precommitTemplatePath
        CommandName = "precommit"
        ScriptNameAndParams = $precommitScript
        OutputFolder = "Update"
    }

    $PreInstallConfig = @{
        TemplateSource = $preinstallTemplatePath
        CommandName = "preinstall"
        ScriptNameAndParams = $preinstallScript
        OutputFolder = "Update"
    }

    #Windows 10 2004 and above
    $PostUninstallInstallConfig = @{
        TemplateSource = $postuninstallTemplatePath
        CommandName = "postuninstall"
        ScriptNameAndParams = $postuninstallScript
        OutputFolder = "Update"
    }

    #Windows 10 2004 and above
    $SuccessConfig = @{
        TemplateSource = $successTemplatePath
        CommandName = "success"
        ScriptNameAndParams = $successScript
        OutputFolder = "Update"
    }
    #endregion

    #region CMD Creation
    Write-Host "Creating Application Content in $($OutputPathRoot)" -ForegroundColor Cyan
    $NewAppPath = New-Item -Path $OutputPathRoot -ItemType Directory -Force
    New-FUCmdFile @FailureConfig
    New-FUCmdFile @SetupCompleteConfig
    New-FUCmdFile @PreCommitConfig
    New-FUCmdFile @PreInstallConfig
    New-FUCmdFile @PostUninstallInstallConfig
    New-FUCmdFile @SuccessConfig

    $ProcessLogsContent = Get-Content -Path $ProcessFeatureUpdateLogsScriptPath -raw -ErrorAction SilentlyContinue
    If($ProcessLogsContent) {
        $NewProcessLogsContent = $ProcessLogsContent.Replace('[string]$NetworkLogPath',"[string]`$NetworkLogPath = `"$($NetworkLogPath)`"").Replace('[string]$LocalFileRoot',"[string]`$LocalFileRoot = `"$($FUTempPath)`"").Replace('[string]$TranscriptPath',"[string]`$TranscriptPath = `"$($LogPath)\FeatureUpdate-CopyFiles.log`"")
        $NewProcessLogsContent | Out-File "$($OutputPathRoot)\Scripts\Process-FeatureUpdateLogs.ps1" -Encoding ascii
    }
    Else {
        Throw "Could not find $($ProcessFeatureUpdateLogsScriptPath). Exiting."
    }

    $ProcessSetupDiagContent = Get-Content -Path $ProcessSetupDiagScriptPath -raw -ErrorAction SilentlyContinue
    If($ProcessSetupDiagContent) {
        $NewProcessSetupDiagContent = $ProcessSetupDiagContent.Replace('[string]$LocalLogRoot',"[string]`$LocalLogRoot = `"$($FUTempPath)\Logs`"").Replace('[string]$TranscriptPath',"[string]`$TranscriptPath = `"$($LogPath)\FeatureUpdate-ProcessSetupDiag.log`"")
        $NewProcessSetupDiagContent | Out-File "$($OutputPathRoot)\Scripts\Process-SetupDiag.ps1" -Encoding ascii
    }
    Else {
        Throw "Could not find $($ProcessSetupDiagScriptPath). Exiting."
    }

    Copy-Item -Path "$($PSScriptRoot)\Content\*" -Destination $NewAppPath -Recurse -Exclude "ADD_SETUPDIAG_HERE.md" -Force
    Copy-Item -Path "$($NewAppPath)" -Destination $ContentLocation -Force -Recurse

    Write-Host "Content created!" -ForegroundColor Cyan -NoNewline
    Write-Host $Script:tick -ForegroundColor green
    #endregion

    #region Connect To ConfigMgr
    Write-Host "Creating Feature Update Configuration Items and Baselines" -ForegroundColor Cyan
    Write-Host "########################################################" -ForegroundColor Cyan
    Write-Host " + Connecting to CMProvider.. " -ForegroundColor Cyan -NoNewline
    ConnectTo-CMProvider -SiteCode $SiteCode -ProviderMachineName $ProviderMachineName
    Write-Host $Script:tick -ForegroundColor green
    #endregion

    #region Application Config
    $Application = @{
        Name = $ApplicationName
        Description = "Files required to manage Feature Updates"
        Publisher = $PublisherName
        SoftwareVersion = "1.0"
        AutoInstall = $true
    }

    $ApplicationDeploymentType = @{
        ContentLocation = $ContentLocation
        DeploymentTypeName = "Copy Feature Update Files to Client"
        InstallCommand = "Powershell.exe -ExecutionPolicy ByPass -File Copy-FeatureUpdateFiles.ps1 -GUID `"$($FUFilesGUID)`""
        LogonRequirementType = [Microsoft.ConfigurationManagement.Cmdlets.AppMan.Commands.LogonRequirementType]::WhetherOrNotUserLoggedOn
        UninstallCommand = "Powershell.exe -ExecutionPolicy ByPass -File Copy-FeatureUpdateFiles.ps1 -RemoveOnly"
        UserInteractionMode = [Microsoft.ConfigurationManagement.ApplicationManagement.UserInteractionMode]::Hidden
        InstallationBehaviorType = [Microsoft.ConfigurationManagement.Cmdlets.AppMan.Commands.InstallationBehaviorType]::InstallForSystem
        RebootBehavior = [Microsoft.ConfigurationManagement.Cmdlets.AppMan.Commands.RebootBehavior]::BasedOnExitCode
        Comment = $null
    }

    #Test for new ConfigMgr build that supports the RepairCommand
    $SupportsRepair = Get-Command -Name Add-CMScriptDeploymentType | Where-Object {$_.Parameters.Keys -eq "RepairCommand"}
    If($SupportsRepair) {
        $ApplicationDeploymentType["RepairCommand"] = "Powershell.exe -ExecutionPolicy ByPass -File Copy-FeatureUpdateFiles.ps1 -GUID `"$($FUFilesGUID)`""
    }

    $GUIDFolderDetectionClause = @{
        DirectoryName = $FUFilesGUID
        Path = "%Windir%\System32\update\run"
        Existence = $True
        Is64Bit = $true
    }
    $ScriptsFolderDetectionClause = @{
        DirectoryName = "Scripts"
        Path = $FUTempPath
        Existence = $True
        Is64Bit = $true
    }
    $SetupDiagDetectionClause = @{
        FileName = "SetupDiag.exe"
        Path = (Join-Path -Path $FUTempPath -ChildPath "Scripts").ToString()
        PropertyType = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.FileFolderProperty]::Version
        ExpressionOperator = [Microsoft.ConfigurationManagement.Cmdlets.Dcm.Commands.RuleExpressionOperator]::GreaterEquals
        ExpectedValue = $SetupDiagVersion
        Value = $true
        Is64Bit = $true
    }
    #endregion

    #region Application Creation
    $ExistingApp = Get-CMApplication -Name $Application.Name -ErrorAction SilentlyContinue
    If($ExistingApp) {
        Throw "The application $($Application.Name) already exists. Exiting."
    }

    Write-Host " + Creating new Application $($Application.Name.ToString())." -ForegroundColor Cyan -NoNewline
    $NewApplication = New-CMApplication @Application
    $cla1 = New-CMDetectionClauseDirectory @GUIDFolderDetectionClause
    $cla2 = New-CMDetectionClauseDirectory @ScriptsFolderDetectionClause
    $cla3 = New-CMDetectionClauseFile @SetupDiagDetectionClause
    #$logic1=$cla1.Setting.LogicalName
    $logic2=$cla2.Setting.LogicalName
    $logic3=$cla3.Setting.LogicalName
    $AppDeploymentType = $NewApplication | Add-CMScriptDeploymentType @ApplicationDeploymentType -AddDetectionClause ($cla1,$cla2,$cla3) -DetectionClauseConnector @{LogicalName=$logic2;Connector="and"},@{LogicalName=$logic3;Connector="and"}
    Write-Host $Script:tick -ForegroundColor green
    #endregion
    
    #region CI Config

    #region SetupConfigINI CI
    $SetupConfigINICI = @{
        Name = "Feature Update - SetupConfig.ini"
        Description = "Updates SetupConfig.ini"
        Category = ".\ConfigurationItem"
        CreationType = "WindowsOS"
    }
    $SetupConfigINICISettings = @{
        ExpressionOperator = [Microsoft.ConfigurationManagement.Cmdlets.Dcm.Commands.RuleExpressionOperator]::IsEquals
        DiscoveryScriptText = ((Get-Content -Path $SetupConfigINIScriptPath).Replace('[bool]$Remediate','[bool]$Remediate = $false').Replace('[string]$NetworkLogPath',"[string]`$LogPath = `"$($NetworkLogPath)`"").Replace('[string]$FUTempPath',"[string]`$FUTempPath = `"$($FUTempPath)`"") | Out-string)
        DiscoveryScriptLanguage = "PowerShell"
        RemediationScriptText = ((Get-Content -Path $SetupConfigINIScriptPath).Replace('[bool]$Remediate','[bool]$Remediate = $true').Replace('[string]$NetworkLogPath',"[string]`$LogPath = `"$($NetworkLogPath)`"").Replace('[string]$FUTempPath',"[string]`$FUTempPath = `"$($FUTempPath)`"") | Out-string)
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
        Name = "Feature Update - OS Version Inventory"
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
        ExpressionOperator = [Microsoft.ConfigurationManagement.Cmdlets.Dcm.Commands.RuleExpressionOperator]::IsEquals
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
        ExpressionOperator = [Microsoft.ConfigurationManagement.Cmdlets.Dcm.Commands.RuleExpressionOperator]::IsEquals
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
        ExpressionOperator = [Microsoft.ConfigurationManagement.Cmdlets.Dcm.Commands.RuleExpressionOperator]::IsEquals
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
        ExpressionOperator = [Microsoft.ConfigurationManagement.Cmdlets.Dcm.Commands.RuleExpressionOperator]::IsEquals
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
        ExpressionOperator = [Microsoft.ConfigurationManagement.Cmdlets.Dcm.Commands.RuleExpressionOperator]::IsEquals
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

    #region CI Creation

    $CIFolderPath = "$($SiteCode):\ConfigurationItem\Feature Updates"
    $BaselineFolderPath = "$($SiteCode):\ConfigurationBaseline\Feature Updates"
    New-Item -Path $CIFolderPath -Force -ErrorAction SilentlyContinue
    New-Item -Path $BaselineFolderPath -Force -ErrorAction SilentlyContinue

    Write-Host " + Creating $($SetupConfigINICI.Name) Configuration Item.. " -ForegroundColor Cyan -NoNewline
    $NewSetupConfigINICI = New-CMConfigurationItem @SetupConfigINICI
    $NewSetupConfigINICI = $NewSetupConfigINICI | Add-CMComplianceSettingScript @SetupConfigINICISettings
    $NewSetupConfigINICI | Move-CMObject -FolderPath $CIFolderPath
    Write-Host $Script:tick -ForegroundColor green

    Write-Host " + Creating $($OSVersionHistoryInventoryCI.Name) Configuration Item.. " -ForegroundColor Cyan -NoNewline
    $NewOSVersionHistoryInventoryCI = New-CMConfigurationItem @OSVersionHistoryInventoryCI
    $NewOSVersionHistoryInventoryCI = $NewOSVersionHistoryInventoryCI | Add-CMComplianceSettingScript @OSVersionHistoryInventoryCISettings
    $NewOSVersionHistoryInventoryCI | Move-CMObject -FolderPath $CIFolderPath
    Write-Host $Script:tick -ForegroundColor green

    Write-Host " + Creating $($SetupDiagInventoryCI.Name) Configuration Item.. " -ForegroundColor Cyan -NoNewline
    $NewSetupDiagInventoryCI = New-CMConfigurationItem @SetupDiagInventoryCI
    $NewSetupDiagInventoryCI = $NewSetupDiagInventoryCI | Add-CMComplianceSettingScript @SetupDiagInventoryCISettings
    $NewSetupDiagInventoryCI | Move-CMObject -FolderPath $CIFolderPath
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
    $NewSetupDiagVersionCI | Move-CMObject -FolderPath $CIFolderPath
    Write-Host $Script:tick -ForegroundColor green

    Write-Host " + Creating $($SetupDiagResultsCI.Name) Configuration Item.. " -ForegroundColor Cyan -NoNewline
    $NewSetupDiagResultsCI = New-CMConfigurationItem @SetupDiagResultsCI
    $NewSetupDiagResultsCI = $NewSetupDiagResultsCI | Add-CMComplianceSettingScript @SetupDiagResultsCISettings
    $NewSetupDiagResultsCI | Move-CMObject -FolderPath $CIFolderPath
    Write-Host $Script:tick -ForegroundColor green

    Write-Host " + Creating $($NoLoggedOnUserCI.Name) Configuration Item.. " -ForegroundColor Cyan -NoNewline
    $NewNoLoggedOnUserCI = New-CMConfigurationItem @NoLoggedOnUserCI
    $NewNoLoggedOnUserCI = $NewNoLoggedOnUserCI | Add-CMComplianceSettingScript @NoLoggedOnUserCISettings
    $NewNoLoggedOnUserCI | Move-CMObject -FolderPath $CIFolderPath
    Write-Host $Script:tick -ForegroundColor green

    Write-Host " + Creating $($FUFilesCI.Name) Configuration Item.. " -ForegroundColor Cyan -NoNewline
    $FUFilesCI = New-CMConfigurationItem @FUFilesCI
    $FUFilesCI = $FUFilesCI | Add-CMComplianceSettingFile @FUFilesCIUpdateFilesExistsSettings
    $FUFilesCI = $FUFilesCI | Add-CMComplianceSettingFile @FUFilesCIScriptsExistsSettings
    $FUFilesCI | Move-CMObject -FolderPath $CIFolderPath
    Write-Host $Script:tick -ForegroundColor green

    Write-Host " + Creating $($FUFilesBaseline.Name) Baseline.. " -ForegroundColor Cyan -NoNewline
    $FUFilesBaseline = New-CMBaseline @FUFilesBaseline
    $FUFilesBaseline | Set-CMBaseline -AddOSConfigurationItem ($NewSetupDiagVersionCI.CI_ID,$NewSetupConfigINICI.CI_ID,$FUFilesCI.CI_ID)
    $FUFilesBaseline | Move-CMObject -FolderPath $BaselineFolderPath
    Write-Host $Script:tick -ForegroundColor green

    Write-Host " + Creating $($NoLoggedOnUserBaseline.Name) Baseline.. " -ForegroundColor Cyan -NoNewline
    $NewNoLoggedOnUserBaseline = New-CMBaseline @NoLoggedOnUserBaseline
    $NewNoLoggedOnUserBaseline | Set-CMBaseline -AddOSConfigurationItem ($NewNoLoggedOnUserCI.CI_ID)
    $NewNoLoggedOnUserBaseline | Move-CMObject -FolderPath $BaselineFolderPath
    Write-Host $Script:tick -ForegroundColor green

    Write-Host " + Creating $($InventoryBaseline.Name) Baseline.. " -ForegroundColor Cyan -NoNewline
    $NewInventoryBaseline = New-CMBaseline @InventoryBaseline
    $NewInventoryBaseline | Set-CMBaseline -AddOSConfigurationItem ($NewSetupDiagInventoryCI.CI_ID,$NewSetupDiagResultsCI.CI_ID,$NewOSVersionHistoryInventoryCI.CI_ID)
    $NewInventoryBaseline | Move-CMObject -FolderPath $BaselineFolderPath
    Write-Host $Script:tick -ForegroundColor green

    Write-Host "########################################################" -ForegroundColor Cyan
    Write-Host " --NOTICE--" -ForegroundColor Yellow
    Write-Host " -- To complete this setup, add a Version detection Rule for SetupDiag.exe to the $($SetupDiagVersionCI.Name) CI." -ForegroundColor Yellow
    Write-Host "-------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "-- Rule Name:      SetupDiag.exe Version = $($SetupDiagVersion)" -ForegroundColor Cyan
    Write-Host "-- Rule Type:      Value" -ForegroundColor Cyan
    Write-Host "-- Property:       File Version" -ForegroundColor Cyan
    Write-Host "-- Type            Equals" -ForegroundColor Cyan
    Write-Host "-- Value:          $($SetupDiagVersion)" -ForegroundColor Cyan
    Write-Host "-- NonCompliance : Critical" -ForegroundColor Cyan
    Write-Host "-------------------------------------------------------------" -ForegroundColor Cyan
    #endregion
    Write-Host "-- Additional Actions Required --" -ForegroundColor Yellow
    Write-Host "-------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host " -- Import OSVersionHistory.MOF into Default Client Settings Hardware Inventory." -ForegroundColor Cyan
    Write-Host " -- Import SetupDiag.MOF into Default Client Settings Hardware Inventory." -ForegroundColor Cyan
    Write-Host " -- Distribute Content for the application $($ApplicationName)." -ForegroundColor Cyan
    Write-Host " -- Deploy the application $($ApplicationName) to all Windows 10 devices." -ForegroundColor Cyan
    Write-Host " -- Deploy the Configuration Baseline $($FUFilesBaseline.Name) to all Windows 10 devices." -ForegroundColor Cyan
    Write-Host " -- Deploy the Configuration Baseline $($NewNoLoggedOnUserBaseline.Name) to all Windows 10 devices." -ForegroundColor Cyan
    Write-Host " -- Deploy the Configuration Baseline $($NewInventoryBaseline.Name) to all Windows 10 devices." -ForegroundColor Cyan
    Write-Host " -- Create new Compliant collection for $($FUFilesBaseline.Name) Baseline Deployment." -ForegroundColor Cyan
    Write-Host " -- Create new Feature Update deployment collection using the $($FUFilesBaseline.Name) Baseline Deployment Compliant collection as the limiting collection." -ForegroundColor Cyan
    Write-Host " -- Use this new collection as your limiting collection for all Feature Update deployments." -ForegroundColor Cyan
    Write-Host " -- It will ensure that you don't deploy to devices without Feature Update files staged." -ForegroundColor Cyan
    Write-Host "########################################################" -ForegroundColor Cyan
    Write-Host " + Done! " -ForegroundColor Cyan -NoNewline
    Write-Host $Script:tick -ForegroundColor green
}
Catch {
    throw $_
}
    



        