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
.NOTES
  Version:        1.0
  Author:         Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:  08/08/2019
  Purpose/Change: Initial script development
  
.EXAMPLE
    Since this will be called in SCCM, set all values in the Param section instead of passing in the command line args.

#>

Param (
    [string]
    $ActualValue, 
    
    [System.Collections.Specialized.OrderedDictionary]$AddSettings = [ordered]@{
        "SetupConfig" = [ordered]@{
            "BitLocker"="AlwaysSuspend"
            "Compat"="IgnoreWarning"
            "Priority"="Normal"
            "DynamicUpdate"="Enable"
            "ShowOOBE"="None"
            "Telemetry"="Enable"
            "DiagnosticPrompt"="Enable"
            "PKey"="NPPR9-FWDCX-D2C8J-H872K-2YT43"
            "PostOOBE"="C:\~FUTemp\Scripts\SetupComplete.cmd"
            #"PostRollBack"="C:\~FUTemp\Scripts\ErrorHandler.cmd"
            #"PostRollBackContext"="System"
            "CopyLogs"="\\CM01\FeatureUpdateLogs$\FailedFULogs\$($ENV:COMPUTERNAME)" #Change this to your network path that EVERYONE has write access to. This will likely run under local System so it needs to be wide open.
            #"Drivers"="" #Consider adding drivers if we need it in the future
        }
    },
    [System.Collections.Specialized.OrderedDictionary]$RemoveSettings = [ordered]@{
        "SetupConfig" = [ordered]@{
            "PostOOBE"=$null
            "PostRollBack"=$null
            "PostRollBackContext"=$null
            "Drivers"=$null
        }
    },
    [string]$SourceIniFile = "$($env:SystemDrive)\Users\Default\AppData\Local\Microsoft\Windows\WSUS\SetupConfig.ini",
    [string]$DestIniFile,
    [switch]$Remediate=$True, #Set to $False for the CI Rule but set to $True for the remediation script.
    [switch]$AlwaysReWrite
)
#region Main
$main = {
    Try {
        IF(Test-Path -Path $SourceIniFile) {
            $CurrrentIniFileContent = Parse-IniFile -IniFile $SourceIniFile
        }
        If((!($AlwaysReWrite.IsPresent)) -and ($CurrrentIniFileContent -is [System.Collections.Specialized.OrderedDictionary])) {
            $NewIniDictionary = Process-Content -OrigContent $CurrrentIniFileContent -NewContent $AddSettings -RemoveContent $RemoveSettings
        }
        Else {
            #If the ini file doesn't exist or has no content, then just set $NewIniDictionary to the $Settings parameter
            $NewIniDictionary = $AddSettings
            $NewIniDictionary["Compliance"] = "NonCompliant"
        }
        If($Remediate.IsPresent) {
            #If no destination is specified, the source path is used
            If(!($DestIniFile)) { $DestIniFile = $SourceIniFile }
            $ComplianceValue =  $NewIniDictionary["Compliance"]
            #Remove the compliance key so it doesn't get added to the final INI file.
            $NewIniDictionary.Remove("Compliance")
            $Results = Export-IniFile -Content $NewIniDictionary -NewFile $DestIniFile
        }
        Else {
            $ComplianceValue =  $NewIniDictionary["Compliance"]
        }
        $ReturnValue = $ComplianceValue
    }
    Catch {
        $ReturnValue = $Error[0]
    }

    Return $ReturnValue
    
}
#endregion
#parses an INI file content into ordered dictionaries
#https://github.com/hsmalley/Powershell/blob/master/Parse-IniFile.ps1
Function Parse-IniFile {
    Param (
        $IniFile
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
                if (!($section))  
                {  
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
            "(.+?)\s*=\s*(.*)"  
            {  
                if (!($section))  
                {  
                    $section = "No-Section"  
                    $ini[$section] = @{}  
                }  
                $name,$value = $matches[1..2]  
                $ini[$section][$name] = $value  
                continue
            }
            # Key Only
            "^\s*([^#].+?)\s*" {
                $ini[$section][$_] = $null
                continue
            }
        }
        $ReturnValue = $ini
    }
    Catch {
        $ReturnValue = $Error[0]
    }
    Return $ReturnValue
    
  }
Function Process-Content {
    #comment based help is here
    [cmdletbinding()]
    Param (
        [System.Collections.Specialized.OrderedDictionary]$OrigContent,
        [System.Collections.Specialized.OrderedDictionary]$NewContent,
        [System.Collections.Specialized.OrderedDictionary]$RemoveContent
    )
    
    $ReturnValue = $null
    Try  {
        #create clones of hashtables so originals are not modified
        $Primary = $OrigContent
        $Secondary = $NewContent

        $Compliance = $null
        $NonCompliantCount = 0

        #If specified, we will remove these keys from the source if they exist
        ForEach($Key in $RemoveContent.Keys)
        {
            If($RemoveContent[$key] -is [System.Collections.Specialized.OrderedDictionary]) {
                ForEach($ChildKey in $RemoveContent[$key].keys) {
                    If($Primary[$key][$ChildKey]) {
                        $Primary[$key].Remove($ChildKey)
                        $NonCompliantCount++
                    }
                }
            }
            Else {
                If($Primary[$key]) {
                    $Primary.Remove($Key)
                    $NonCompliantCount++
                }
            }
        }

        ForEach($Key in $Primary.keys) {
            If($Primary[$key] -is [System.Collections.Specialized.OrderedDictionary]) {

                #I'm so done writing this code. This basically checks to see if you have an exact number of records in the source and new
                #If you don't do this, then compliance will be incorrect.
                If($Primary[$key].Count -lt $Secondary[$key].Count)
                {
                    $NonCompliantCount++
                }

                If($Secondary[$key]) {

                    #Find all duplicate keys in the source
                    $Duplicates = $Primary[$key].keys | where-object {$Secondary[$key].Contains($_)}
                    If ($Duplicates) {
                        Foreach ($item in $Duplicates) {
                            #Test for compliance. If the values don't match, then this item should be remediated
                            If($Primary[$key][$item] -ne $Secondary[$key][$item])
                            {
                                $NonCompliantCount ++
                            }
                            $Primary[$key].Remove($item)
                        }
                    }

                    #Adds remaining items from the source to the output since these weren't duplicates.
                    #These don't impact compliance since we don't care if they exist
                    ForEach($ChildKey in $Primary[$key].keys) {
                        If($Secondary[$key]) {
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
                $duplicates = $Primary.keys | where-object {$Secondary.Contains($_)}
                if ($duplicates) {
                    foreach ($item in $duplicates) {
                        #Test for compliance. If the values don't match, then this item should be remediated
                        If($Primary[$item] -ne $Secondary[$item])
                        {
                            $NonCompliantCount ++
                        }
                        $Primary.Remove($item)
                    }
                }
            }
        }

        #If No Mismatched values are found, $Compliance is set to Compliance
        $Compliance = Switch ($NonCompliantCount) {
            0 {"Compliant"; break;}
            default {"NonCompliant"; break;}
        }

        $Secondary["Compliance"] = $Compliance

        $ReturnValue = $Secondary
    }

    catch {
        $ReturnValue = $error[0]
    }
        Return $ReturnValue
}

Function Export-IniFile {

    Param (
        [System.Collections.Specialized.OrderedDictionary]$Content,
        [string]$NewFile
    )
    
    $ReturnValue = $null
    Try {
        #This array will be the final ini output
        $NewIniContent = @()

        $KeyCount = 0
        #Convert the dictionary into ini file format
        ForEach($sectionHash in $Content.Keys)
        {
            $KeyCount++
            #Create section headers
            $NewIniContent += "[{0}]" -f $sectionHash

            #Create all section content. Items with a Name and Value in the dictionary will be formatted as Name=Value. 
            #Any items with no value will be formatted as Name only.
            ForEach ($key in $Content[$sectionHash].keys) {
                $NewIniContent += 
                If ($Key -like "Comment*"){
                    #Comment
                    $Content[$sectionHash][$key]
                }    
                ElseIf($NewIniDictionary[$sectionHash][$key]) {
                    #Name=Value format
                    ($key, $Content[$sectionHash][$key]) -join "="
                }
                Else {
                    #Name only format
                    $key
                }
            }
            #Add a blank line after each section if there is more than one, but don't add one after the last section
            If($KeyCount -lt $Content.Keys.Count) {
                $NewIniContent += ""
            }
        }
        #Write $Content to the SetupConfig.ini file

        New-Item -Path $NewFile -ItemType File -Force | Out-Null
        $NewIniContent -join "`r`n" | Out-File -FilePath $NewFile -Force -NoNewline | Out-Null
        $ReturnValue = $NewIniContent
    }
    Catch {
        $ReturnValue = $Error[0]
    }
    Return $ReturnValue
}

#launch Main
&$main