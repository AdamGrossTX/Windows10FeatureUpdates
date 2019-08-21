<#
.SYNOPSIS
    Copies files using the Process-Content script
.DESCRIPTION
    Copies all required Feature Update files/scripts to a device. Designed to be deployed as an Application from SCCM.
.PARAMETER GUID
    A unique GUID required by Windows 10 Feature Updates    
    Run New-GUID to get a new GUID any time changes are made to the content folders..
.PARAMETER RemoveOnly
    Set to true for the uninstall commandline in SCCM
    Powershell.exe -ExecutionPolicy ByPass -File Copy-FeatureUpdateFiles.PS1
.PARAMETER TranscriptPath

.NOTES
  Version:          1.0
  Author:           Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:    08/08/2019
  Purpose/Change:   Initial script development
  
.EXAMPLE
    Uninstall all files/folders
    Copy-FeatureUpdateFiles.PS1 -RemoveOnly

.EXAMPLE
    Copy all content
    Copy-FeatureUpdateFiles.PS1 -GUID "ca3d0b66-131d-4e85-b474-98565a01a1f2"
       
.EXAMPLE
    Remove DestPath and all child content without copying any new content
    ProcessContent -DestPath $DestPath -DestChildFolder $DestChild -RemoveLevel Root -RemoveOnly

.EXAMPLE        
    SCCM CommandLine
    Powershell.exe -ExecutionPolicy ByPass -File Copy-FeatureUpdateFiles.PS1
 #>
 
 Param (
    [string]$GUID = "6ace78a3-504c-4e45-b0e3-2e72fbeacf87",
    [switch]$RemoveOnly,
    [string]$TranscriptPath = "C:\Windows\CCM\Logs\FeatureUpdate-CopyFiles.log",
    [string]$BaselineName = "Feature Update Files"
)
#Import the Process-Content script/function. This file should be present in the folder where you are launching this file from, or you need to change the path.
. (Join-Path -Path $PSScriptRoot -ChildPath ".\Scripts\Process-Content.ps1")
. (Join-Path -Path $PSScriptRoot -ChildPath ".\Trigger-DCMEvaluation.ps1")

Start-Transcript -Path $TranscriptPath -Append -Force -ErrorAction SilentlyContinue
$Main = {

    $Sources = @{
        "Update" = @{
            SourcePath = (Join-Path -Path $PSScriptRoot -ChildPath "Update")
            DestPath = "c:\Windows\System32\update\run"
            DestChildFolder = $GUID
            RemoveLevel = 'Root'
        }
        "Scripts" = @{
            SourcePath = (Join-Path -Path $PSScriptRoot -ChildPath "Scripts")
            DestPath = "C:\~FeatureUpdateTemp"
            DestChildFolder = "Scripts"
            RemoveLevel = 'Child'
            Hide = $True
        }
    }

    ForEach($Key in $Sources.keys) {
        $ArgList = $Sources[$Key]
        If($RemoveOnly.IsPresent) {
            $ArgList.Remove("SourcePath")
            $ArgList.Remove("Hide")
            $ArgList["RemoveOnly"] = $True
        }
        ProcessContent @ArgList -ErrorAction Continue
    }
    
    Trigger-DCMEvaluation -BaseLine $BaselineName
}

&$main
Stop-Transcript