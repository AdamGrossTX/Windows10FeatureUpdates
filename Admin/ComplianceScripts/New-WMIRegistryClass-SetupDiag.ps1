<#
.SYNOPSIS
   Create and populate WMI Class with SetupDiag registry keys
.DESCRIPTION
   Use to create a custom WMI Class from a list of registry keys
.PARAMETER NameSpace
    WMI Namespace where new class will be created
.PARAMETER ClassName
    New WMI class name. Be sure to use a unique class since an existing class will be overwitten.
.PARAMETER CombineKeys
    Set this to True to merge all registry keys into a single WMI instance. Set to False to create new instances for each registry key
.PARAMETER RegistryKeyList
    A list of registry key paths that will be collected to be stored into a new instance of the class.
.PARAMETER ClassPropertyList
    An array of value names to be used as class properties.
.NOTES
  Version:        1.0
  Author:         Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:  08/09/2019
  Purpose/Change: Initial script development
  
#>

Param (
    [string]$NameSpace = "root\cimv2",
    [string]$ClassName = "CM_SetupDiag",
    [string[]]$RegistryKeyList = @(
      "HKLM:System\Setup\MoSetup\Tracking",
      "HKLM:System\Setup\MoSetup\Volatile\SetupDiag"
   ),
   [Switch]$CombineKeys=$True,
   [hashtable]$ClassPropertyList = @{
    "CustomSetupDiagResult" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "DateTime" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('key','read')
    }
    "FailureData" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "FailureDetails" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "HostOSVersion" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "LastSetupOperation" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "LastSetupOperationElapsed" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "LastSetupOperationEndTime" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "LastSetupOperationStartTime" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "LastSetupPhase" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "LastSetupPhaseElapsed" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "LastSetupPhaseEndTime" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "LastSetupPhaseStartTime" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "OperationCompletedSuccessfully" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "PhaseCompletedSuccessfully" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "ProfileGuid" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "ProfileName" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "Remediation" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "RollbackElapsedTime" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "RollbackEndTime" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "RollbackStartTime" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "SetupDiagVersion" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "TargetOSVersion" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "UpgradeElapsedTime" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "UpgradeEndTime" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "UpgradeStartTime" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "DeviceDescription" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "HardwareId" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "InfName" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "DriverVersion" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "RecoveryStartTime" = @{
        "type" = [System.Management.CimType]::String
        "qualifiers" = @('read')
    }
    "InstallAttempts" = @{
        "type" = [System.Management.CimType]::UInt32
        "qualifiers" = @('read')
    }
    "FailureCount" = @{
        "type" = [System.Management.CimType]::UInt32
        "qualifiers" = @('read')
    }
   }
)

$Main = {
   Try {
    New-CustWMIClass -NameSpace $NameSpace -Class $ClassName -PropertyList $ClassPropertyList -RemoveExisting | Out-Null
    If($CombineKeys.IsPresent) {
        $RegProperties = Get-RegistryProperties -RegistryKey $RegistryKeyList
        Set-CustWMIClass -NameSpace $NameSpace -Class $ClassName -Values $RegProperties -PropertyList $ClassPropertyList | Out-Null
    }
    Else {
        ForEach ($Key in $RegistryKeyList) {
            $RegKeys = Get-Item -Path $Key -ErrorAction SilentlyContinue
            ForEach ($RegKey in $RegKeys) {
                $RegProperties = Get-RegistryProperties -RegistryKey $RegKey
                $RegProperties["KeyName"] = $RegKey.PSChildName
                Set-CustWMIClass -NameSpace $NameSpace -Class $ClassName -Values $RegProperties -PropertyList $ClassPropertyList | Out-Null
            }
        }
    }
    Return $True
   }
   Catch {
      Return $_
   }
}

Function Remove-CustWMIInstance {
[cmdletbinding()]
Param (
    [String]$Namespace,
    [String]$Class
)
    Try {
        $ExistingClass = Get-CIMClass -Namespace $NameSpace -ClassName $Class -ErrorAction SilentlyContinue
        If($ExistingClass) {
            ([wmiclass]"$($Namespace):$($Class)").Delete()
        }
    }
    Catch {
        Throw $_
    }
}

Function New-CustWMIClass {
[cmdletbinding()]
Param (
   [String]$NameSpace,
   [String]$Class,
   $PropertyList,
   [Switch]$RemoveExisting
)
   Try {
      If($RemoveExisting.IsPresent) {
         Remove-CustWMIInstance -NameSpace $NameSpace -Class $Class
      } 

      If (Get-CimClass -ClassName $Class -Namespace $NameSpace -ErrorAction SilentlyContinue) {
         Write-Verbose "WMI Class $Class Already Exists" | Out-Null
      }    
      Else {
         Write-Verbose "Create WMI Class '$Class'" | Out-Null
         $NewClass = New-Object System.Management.ManagementClass($NameSpace, [String]::Empty, $Null); 
         $NewClass['__CLASS'] = $Class
         $NewClass.Qualifiers.Add("Static", $true)
        
         ForEach($key in $PropertyList.keys) {
            $NewClass.Properties.Add($key, $PropertyList[$key].Type, $false)
            ForEach($Qualifier in $PropertyList[$Key].Qualifiers) {
                $NewClass.Properties[$key].Qualifiers.Add("$($Qualifier)", $true)
            }
        }
         $NewClass.Put() | Out-Null
      }
      Write-Verbose "End of trying to create an empty $Class to populate later" | Out-Null
   }
   Catch {
      Throw $_
   }
}
 
Function Set-CustWMIClass {
[cmdletbinding()]
Param (
   [String]$NameSpace,
   [String]$Class,
   [System.Collections.Specialized.OrderedDictionary]$Values,
   $PropertyList
)
   Try {
      $ValueList = @{} 
      ForEach ($Key in $PropertyList.Keys) {
         If($Values[$key]) {
            If($Values[$key] -is [int32]) {
               $ValueList[$Key] = ([uint32]$Values[$key])
            } 
            ElseIf($Values[$key] -is [int64]) {
               $ValueList[$Key] = ([uint64]$Values[$key])
            } 
            Else {
               $ValueList[$Key] = $Values[$key]
            }
         }
      }
      $NewInstance = New-CimInstance -Namespace $NameSpace -ClassName $Class -Arguments $ValueList -ErrorAction Continue
      Return $NewInstance
   }
   Catch {
      Throw $_
   }
}

Function Get-RegistryProperties {
[cmdletbinding()]
Param (
    $RegistryKey
)
Try {
    [System.Collections.Specialized.OrderedDictionary]$PropertyList = [ordered]@{}
    If($RegistryKey -is [string[]]) {
        ForEach($Key in $RegistryKey) {
            $RegKey = Get-Item -Path "$($Key)" -ErrorAction SilentlyContinue
            If($RegKey) {
                ForEach ($Prop in $RegKey.Property) {
                    $PropertyList[$Prop] = Get-ItemPropertyValue -Path $Key -Name $Prop
                }
            }
        }
    }
    Else {
        ForEach ($Prop in $RegistryKey.Property) {
            $PropertyList[$Prop] = $RegistryKey | Get-ItemPropertyValue -Name $Prop -ErrorAction SilentlyContinue
        }
    }
    Return $PropertyList
}
Catch {
    Throw $_
}
}

& $Main