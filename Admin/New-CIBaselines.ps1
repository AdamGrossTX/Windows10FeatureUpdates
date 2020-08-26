
Param(
    [string]$SiteCode = "PS1",
    [string]$ProviderMachineName = "CM01.asd.net",
    $BaselineName = "Feature Update Inventory",
    $CIList = (
        @{
            ScriptPath = "e:\Media\FeatureUpdateScripts\Admin\New-WMIRegistryClass-OSVersionHistory.ps1"
            CIName = "OS Version Inventory"
            Description = "Inventories Windows Setup History"
        },
        @{
            ScriptPath = "e:\Media\FeatureUpdateScripts\Admin\New-WMIRegistryClass-SetupDiag.ps1"
            CIName = "SetupDiag Inventory"
            Description = "Inventories SetupDiag History"
        }
    )
)

$Main = {
    ConnectTo-CMProvider -SiteCode $SiteCode -ProviderMachineName $ProviderMachineName
    $NewCIs = ForEach($CI in $CIList) {
        New-FUCI @CI
    }
    $Baseline = New-CMBaseline -Name $BaselineName
    ForEach($NewCI in $NewCIs) {
        Set-CMBaseline -Id $Baseline.CI_ID -AddOSConfigurationItem $NewCI.CI_ID
    }
}

Function ConnectTo-CMProvider {
    Param(
        [string]$SiteCode,
        [string]$ProviderMachineName
    )
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

Function New-FUCI {
    [cmdletbinding()]
    Param(
        [string]$ScriptPath,
        [string]$CIName,
        [string]$Description
    )
    Try {
    $CI = New-CMConfigurationItem -Name $CIName -Description $Description -Category .\ConfigurationItem -CreationType WindowsOS
    $ScriptText = Get-Content -Path $ScriptPath
    $NewRule = @{
        DiscoveryScriptLanguage = "PowerShell"
        DataType = "String"
        Name = $CIName
        DiscoveryScriptText = "$($ScriptText | Out-String)"
        Is64Bit = $true
        RuleName = "Script Returns True"
        ValueRule = $true
        ExpectedValue = "True"
        ExpressionOperator = "IsEquals"
        NoncomplianceSeverity = "Critical"
    }
    $CI | Add-CMComplianceSettingScript @NewRule | Out-Null
    Return $CI
    }
    Catch {
        Throw $_
    }
}



& $Main
