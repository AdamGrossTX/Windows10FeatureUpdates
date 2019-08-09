
<#
.SYNOPSIS
   WMI Class Creation and Population Script
.DESCRIPTION
   Use to create a custom WMI Class from a list of registry keys
.PARAMETER NameSpace
    WMI Namespace where new class will be created
.PARAMETER ClassName
    New WMI class name. Be sure to use a unique class since an existing class will be overwitten.
.PARAMETER ClassPropertyList
    An array of value names to be used as class properties.
.PARAMETER RegistryKeyList
    A list of registry key paths that will be collected to be stored into a new instance of the class.
.NOTES
  Version:        1.0
  Author:         Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:  08/09/2019
  Purpose/Change: Initial script development
  
.EXAMPLE
    Custom-WMIClass -NameSpace "root\cimv2" -ClassName "CM_SetupDiag" -ClassPropertyList @( "FailureData","FailureDetails","HostOSVersion","LastSetupOperation","LastSetupPhase","ProfileGuid","ProfileName","Remediation","RollbackElapsedTime","RollbackEndTime","RollbackStartTime","SetupDiagVersion","TargetOSVersion","UpgradeElapsedTime","UpgradeEndTime","UpgradeStartTime","UpgradeStartTime","DeviceDescription","HardwareId","InfName","DriverVersion","RecoveryStartTime","InstallAttempts") -RegistryKeyList @("HKLM:System\Setup\MoSetup\Tracking","HKLM:System\Setup\MoSetup\Volatile\SetupDiag")
#>
Param (
   [string]$NameSpace = "root\cimv2",
   [string]$ClassName = "CM_SetupDiag",
   [string[]]$ClassPropertyList = @(
      "FailureData",
      "FailureDetails",
      "HostOSVersion",
      "LastSetupOperation",
      "LastSetupPhase",
      "ProfileGuid",
      "ProfileName",
      "Remediation",
      "RollbackElapsedTime",
      "RollbackEndTime",
      "RollbackStartTime",
      "SetupDiagVersion",
      "TargetOSVersion",
      "UpgradeElapsedTime",
      "UpgradeEndTime",
      "UpgradeStartTime",
      "UpgradeStartTime",
      "DeviceDescription",
      "HardwareId",
      "InfName",
      "DriverVersion",
      "RecoveryStartTime",
      "InstallAttempts"
   ),
   [string[]]$RegistryKeyList = @(
      "HKLM:System\Setup\MoSetup\Tracking",
      "HKLM:System\Setup\MoSetup\Volatile\SetupDiag"
   )
)

$Main = {
   $ScriptRanDate = Get-Date
   $ScriptRan = [System.Management.ManagementDateTimeConverter]::ToDmtfDateTime($ScriptRanDate)
   $KeyProperty = "DateCollected"
   
   New-CustWMIClass -NameSpace $NameSpace -Class $ClassName -PropertyList $ClassPropertyList -KeyProperty $KeyProperty -RemoveExisting
   $RegProperties = Get-RegistryProperties -RegistryKeys $RegistryKeyList
   $RegProperties[$KeyProperty] = $ScriptRan
   
   $NewInstance = Set-CustWMIClass -NameSpace $NameSpace -Class $ClassName -Values $RegProperties
   Return $NewInstance
}

Function Remove-CustWMIClass {
Param (
   [String]$NameSpace,
   [String]$Class
)
   Try {
      Write-Verbose "Create a new empty '$Class' to populate later" | Out-Null
      Remove-WMIObject -Namespace $NameSpace -class $Class -ErrorAction SilentlyContinue
   }
   Catch {
      Throw $Error[0]
   }
}

Function New-CustWMIClass {
Param (
   [String]$NameSpace,
   [String]$Class,
   [string[]]$PropertyList,
   [string]$KeyProperty,
   [Switch]$RemoveExisting
)
   Try {
      If($RemoveExisting.IsPresent) {
         Remove-CustWMIClass -NameSpace $NameSpace -Class $Class
      } 

      If (Get-CimClass -ClassName $Class -Namespace $NameSpace -ErrorAction SilentlyContinue) {
         Write-Verbose "WMI Class $Class Already Exists" | Out-Null
      }    
      Else {
         Write-Verbose "Create WMI Class '$Class'" | Out-Null
         $NewClass = New-Object System.Management.ManagementClass ($NameSpace, [String]::Empty, $Null); 
         $NewClass['__CLASS'] = $Class

         ForEach($Prop in $PropertyList) {
            $NewClass.Properties.Add($Prop, [System.Management.CimType]::String, $false)
         }
         $NewClass.Properties.Add($KeyProperty, [System.Management.CimType]::String, $false)
         $NewClass.Properties[$KeyProperty].Qualifiers.Add("Key",$True)

         $NewClass.Put() | Out-Null
      }
      Write-Verbose "End of trying to create an empty $Class to populate later" | Out-Null
   }
   Catch {
      Throw $Error[0]
   }
}
 
Function Set-CustWMIClass {
Param (
   [String]$NameSpace,
   [String]$Class,
   [System.Collections.Specialized.OrderedDictionary]$Values
)
   Try {
      $NewInstance = New-CimInstance -Namespace $NameSpace -ClassName $Class -Arguments $Values
   }
   Catch {
      Throw $Error[0]
   }
   Return $NewInstance
}

Function Get-RegistryProperties {
   Param (
      [string[]]$RegistryKeys
   )
   Try {
      [System.Collections.Specialized.OrderedDictionary]$PropertyList = [ordered]@{}
      ForEach($Key in $RegistryKeys) {
         $RegKey = Get-Item -Path "$($Key)" -ErrorAction SilentlyContinue
         If($RegKey) {
            ForEach ($Prop in $RegKey.Property) {
               $PropertyList[$Prop] = Get-ItemPropertyValue -Path $Key -Name $Prop
            }
         }
      }
   }
   Catch {
      Throw $Error[0]
   }
   Return $PropertyList
}

&$Main