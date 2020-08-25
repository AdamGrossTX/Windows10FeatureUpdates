<#
.SYNOPSIS
  Use as a CI in SCCM or as a standalone script to detect and/or remediate compliance for SetupConfig.ini
.DESCRIPTION
  SetupConfig.ini is used by Windows 10 Feature Updates to pass in command line arguments just as if you were manually running
  Setup.exe with arguments https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-command-line-options
.PARAMETER ActualValue
    The incoming compliance value from the CI when run from SCCM. This is required for the CI remediation script to function.
    It is not referenced in the script anywhere but should not be removed unless you run this script standalone.
.PARAMETER AddSettings
    This is an ordered, nested dictionary. Each section will have a nested dictionary with name/value pairs.
    The top level dictionary represents the section header in your INI file
    The child level dictionary is all of the key/value pairs in your INI file.
    If a key doesn't have a value then it should be entered with a $null like NoReboot=$Null. The Output will just be a line with NoReboot instead of NoReboot=
.PARAMETER RemoveSettings
    This is an ordered, nested dictionary. Each section will have a nested dictionary with name/value pairs.
    Each item listed will be removed from the INI file. If you don't specify a value, then the entire entry or child dictionary will be removed
    The included example will only remove the BitLocker line from a
.PARAMETER SourceIniFile
    Full path to the INI file that will be edited by the script
.PARAMETER DestIniFile
    Full path to the INI file that will be output. If no value is specified, the SourceIniFile will be used.
.PARAMETER Remediate
    Set to $true to update the INI file. Set to $false or no value to report compliance only.
    When used in an SCCM CI, set Remediate=$True for the remediation script only.
.PARAMETER AlwaysReWrite
    Forces the INI file to be completely re-writted with the values given, instead of lines being edited.
    This can provide you will a clean file in case you feel that there has been some file corruption.

.PARAMETER FuTempDir
    The local path to store the scripts for the Feature Update to use

.PARAMETER LogPath
    The network share to copy logs on failure

.NOTES
  Version:        1.1
  Author:         Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:  08/08/2019
  Purpose/Change:
    1.0 Initial Script
    1.1 Updated to support Windows 10 2004 options

.EXAMPLE
    Since this will be called in SCCM, set all values in the Param section instead of passing in the command line args.

#>
[CmdletBinding()]
Param (
    [Parameter()]
    [string]
    $ActualValue, # The incoming compliance value from the CI.
    #This is an ordered, nested dictionary. Each section will have a nested dictionary with name/value pairs

    [Parameter()]
    [bool]$Remediate = $True,

    [Parameter()]
    [string]$SourceIniFile = "$($env:SystemDrive)\Users\Default\AppData\Local\Microsoft\Windows\WSUS\SetupConfig.ini",

    [Parameter()]
    [string]$FuTempDir = "C:\~FeatureUpdateTemp",

    [Parameter()]
    [string]$LogPath = "\\CM01\FeatureUpdateLogs$\FailedLogs",

    [Parameter()]
    [string]$DestIniFile = "$($env:SystemDrive)\Users\Default\AppData\Local\Microsoft\Windows\WSUS\SetupConfig.ini",

    [Parameter()]
    [switch]$AlwaysReWrite,

    #Any options listed in the docs as available for the TARGET OS can be used here
    #https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-command-line-options
    [Parameter()]
    [System.Collections.Specialized.OrderedDictionary]$AddSettings = [ordered]@{
        "SetupConfig" = [ordered]@{
            "BitLocker"             =   "AlwaysSuspend"; #{AlwaysSuspend | TryKeepActive | ForceKeepActive}
            "Compat"                =   "IgnoreWarning"; #{IgnoreWarning | ScanOnly}
            "Priority"              =   "Normal" #{High | Normal | Low}
            "DynamicUpdate"         =   "Enable" #{Enable | Disable | NoDrivers | NoLCU | NoDriversNoLCU}
            "ShowOOBE"              =   "None" #{Full | None}
            "Telemetry"             =   "Enable" #{Enable | Disable}
            "DiagnosticPrompt"      =   "Enable" #{Enable | Disable}
            "PKey"                  =   "NPPR9-FWDCX-D2C8J-H872K-2YT43" #<product key>
            "PostOOBE"              =   "$($FuTempDir)\Scripts\SetupComplete.cmd" #<location> [\setupcomplete.cmd]
            "CopyLogs"              =   "$($LogPath)\$($ENV:COMPUTERNAME)" #<location> automtic log copy feature if setup fails.
            #"SkipFinalize"         =   "" #2004 and up
            #"Finalize"             =   "" #2004 and up
            #"NoReboot"             =   ""
            #"InstallDrivers"       =   "" #<location>
            #"MigrateDrivers"       =   "All" #{All | None}
            #"PostRollBack"         =   "$($FuTempDir)\Scripts\ErrorHandler.cmd" #<location>
            #"PostRollBackContext"  =   "System" #{system | user}
        }
    }
    <# Example of the removal option
    [System.Collections.Specialized.OrderedDictionary]$RemoveSettings = [ordered]@{
        "SetupConfig" = [ordered]@{
            "PostOOBE"              =   $null
            "PostRollBack"          =   $null
            "PostRollBackContext"   =   $null
            "InstallDrivers"        =   $null
        }
    },
    #>
)
#region Main
$main = {
    Try {
        If (Test-Path -Path $SourceIniFile -ErrorAction SilentlyContinue) {
            $CurrrentIniFileContent = Parse-IniFile -IniFile $SourceIniFile
        }
        If (-not $AlwaysReWrite.IsPresent -and ($CurrrentIniFileContent -is [System.Collections.Specialized.OrderedDictionary])) {
            $NewIniDictionary = Process-Content -OrigContent $CurrrentIniFileContent -NewContent $AddSettings -RemoveContent $RemoveSettings
        }
        Else {
            #If the ini file doesn't exist or has no content, then just set $NewIniDictionary to the $Settings parameter
            $NewIniDictionary = $AddSettings
            $NewIniDictionary["Compliance"] = "NonCompliant"
        }
        If ($Remediate) {
            #If no destination is specified, the source path is used
            If (-not $DestIniFile) {
                $DestIniFile = $SourceIniFile
            }
            $ComplianceValue = $NewIniDictionary["Compliance"]
            #Remove the compliance key so it doesn't get added to the final INI file.
            $NewIniDictionary.Remove("Compliance")
            Export-IniFile -Content $NewIniDictionary -NewFile $DestIniFile | Out-Null
        }
        Else {
            $ComplianceValue = $NewIniDictionary["Compliance"]
        }
        Return $ComplianceValue
    }
    Catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
#endregion
#parses an INI file content into ordered dictionaries
#https://github.com/hsmalley/Powershell/blob/master/Parse-IniFile.ps1
Function Parse-IniFile {
    [CmdletBinding()]
    Param (
        [Parameter()]
        [string]$IniFile
    )

    Try {
        $ini = [Ordered]@{}
        switch -regex -file $IniFile {
            #Section
            "^\[(.+)\]$" {
                $section = $matches[1].Trim()
                $ini[$section] = [Ordered]@{}
                continue
            }
            # Comment
            "^(;.*)$" {
                if (!($section)) {
                    $section = "No-Section"
                    $ini[$section] = [Ordered]@{}
                }
                $value = $matches[1]
                $CommentCount = $CommentCount + 1
                $name = "Comment" + $CommentCount
                $ini[$section][$name] = $value
                continue
            }
            # Key/Value Pair
            "(.+?)\s*=\s*(.*)" {
                if (!($section)) {
                    $section = "No-Section"
                    $ini[$section] = @{}
                }
                $name, $value = $matches[1..2]
                $ini[$section][$name] = $value
                continue
            }
            # Key Only
            "^\s*([^#].+?)\s*" {
                $ini[$section][$_] = $null
                continue
            }
        }
        Return $ini
    }
    Catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
Function Process-Content {
    #comment based help is here
    [cmdletbinding()]
    Param (
        [System.Collections.Specialized.OrderedDictionary]$OrigContent,
        [System.Collections.Specialized.OrderedDictionary]$NewContent,
        [System.Collections.Specialized.OrderedDictionary]$RemoveContent
    )

    Try {
        #create clones of hashtables so originals are not modified
        $Primary = $OrigContent
        $Secondary = $NewContent

        $Compliance = $null
        $NonCompliantCount = 0

        #If specified, we will remove these keys from the source if they exist
        ForEach ($Key in $RemoveContent.Keys) {
            If ($RemoveContent[$key] -is [System.Collections.Specialized.OrderedDictionary]) {
                ForEach ($ChildKey in $RemoveContent[$key].keys) {
                    If ($Primary[$key][$ChildKey]) {
                        $Primary[$key].Remove($ChildKey)
                        $NonCompliantCount++
                    }
                }
            }
            Else {
                If ($Primary[$key]) {
                    $Primary.Remove($Key)
                    $NonCompliantCount++
                }
            }
        }

        ForEach ($Key in $Primary.keys) {
            If ($Primary[$key] -is [System.Collections.Specialized.OrderedDictionary]) {

                #I'm so done writing this code. This basically checks to see if you have an exact number of records in the source and new
                #If you don't do this, then compliance will be incorrect.
                If ($Primary[$key].Count -lt $Secondary[$key].Count) {
                    $NonCompliantCount++
                }

                If ($Secondary[$key]) {

                    #Find all duplicate keys in the source
                    $Duplicates = $Primary[$key].keys | where-object { $Secondary[$key].Contains($_) }
                    If ($Duplicates) {
                        Foreach ($item in $Duplicates) {
                            #Test for compliance. If the values don't match, then this item should be remediated
                            If ($Primary[$key][$item] -ne $Secondary[$key][$item]) {
                                $NonCompliantCount ++
                            }
                            $Primary[$key].Remove($item)
                        }
                    }

                    #Adds remaining items from the source to the output since these weren't duplicates.
                    #These don't impact compliance since we don't care if they exist
                    ForEach ($ChildKey in $Primary[$key].keys) {
                        If ($Secondary[$key]) {
                            $Secondary[$key][$childKey] = $Primary[$key][$ChildKey]
                        }
                        Else {
                            $Secondary[$key] = $Primary[$key]
                        }
                    }
                }
                Else {
                    $Secondary[$key] = $Primary[$key]
                }
            }
            Else {
                $duplicates = $Primary.keys | where-object { $Secondary.Contains($_) }
                if ($duplicates) {
                    foreach ($item in $duplicates) {
                        #Test for compliance. If the values don't match, then this item should be remediated
                        If ($Primary[$item] -ne $Secondary[$item]) {
                            $NonCompliantCount ++
                        }
                        $Primary.Remove($item)
                    }
                }
            }
        }

        #If No Mismatched values are found, $Compliance is set to Compliance
        $Compliance = Switch ($NonCompliantCount) {
            0 { "Compliant"; break; }
            default { "NonCompliant"; break; }
        }

        $Secondary["Compliance"] = $Compliance

        Return $Secondary
    }

    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}

Function Export-IniFile {
    [CmdletBinding()]
    Param (
        [parameter()]
        [System.Collections.Specialized.OrderedDictionary]$Content,

        [parameter()]
        [string]$NewFile
    )

    Try {
        #This array will be the final ini output
        $NewIniContent = @()

        $KeyCount = 0
        #Convert the dictionary into ini file format
        ForEach ($sectionHash in $Content.Keys) {
            $KeyCount++
            #Create section headers
            $NewIniContent += "[{0}]" -f $sectionHash

            #Create all section content. Items with a Name and Value in the dictionary will be formatted as Name=Value.
            #Any items with no value will be formatted as Name only.
            ForEach ($key in $Content[$sectionHash].keys) {
                $NewIniContent +=
                If ($Key -like "Comment*") {
                    #Comment
                    $Content[$sectionHash][$key]
                }
                ElseIf ($NewIniDictionary[$sectionHash][$key]) {
                    #Name=Value format
                    ($key, $Content[$sectionHash][$key]) -join "="
                }
                Else {
                    #Name only format
                    $key
                }
            }
            #Add a blank line after each section if there is more than one, but don't add one after the last section
            If ($KeyCount -lt $Content.Keys.Count) {
                $NewIniContent += ""
            }
        }
        #Write $Content to the SetupConfig.ini file

        New-Item -Path $NewFile -ItemType File -Force | Out-Null
        $NewIniContent -join "`r`n" | Out-File -FilePath $NewFile -Force -NoNewline | Out-Null
        Return $NewIniContent
    }
    Catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}

#launch Main
&$main
