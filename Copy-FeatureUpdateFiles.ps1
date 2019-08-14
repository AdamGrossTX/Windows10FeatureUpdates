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
    [string]$GUID = "1a71e7fd-837d-469b-8593-f93683f7f401",
    [switch]$RemoveOnly,
    [string]$TranscriptPath = "C:\Windows\CCM\Logs\FeatureUpdate-CopyFiles.log"
)
#Import the Process-Content script/function. This file should be present in the folder where you are launching this file from, or you need to change the path.
. (Join-Path -Path $PSScriptRoot -ChildPath ".\Process-Content.PS1")

Start-Transcript -Path $TranscriptPath -Append -Force -ErrorAction SilentlyContinue
$Main = {

    ######
    $Source1 = "Update"
    $SourcePath1 = Join-Path -Path $PSScriptRoot -ChildPath $Source1
    $DestPath1 = "c:\Windows\System32\update\run"
    $DestChild1 = $GUID
    ######
    
    ######
    $Source2 = "Scripts"
    $SourcePath2 = Join-Path -Path $PSScriptRoot -ChildPath $Source2
    $DestPath2 = "C:\~FeatureUpdateTemp"
    $DestChild2 = "Scripts"
    ######

    ######
    $SourcePath3 = $PSScriptRoot
    $DestPath3 = "C:\~FeatureUpdateTemp"
    $DestChild3 = "Scripts"
    $DestChild3File1 = "Process-Content.ps1"
    ######



    If($RemoveOnly.IsPresent) {
        ProcessContent -DestPath $DestPath1 -DestChildFolder $DestChild1 -RemoveLevel Root -RemoveOnly
        ProcessContent -DestPath $DestPath2 -DestChildFolder $DestChild2 -RemoveLevel Child -RemoveOnly
        ProcessContent -DestPath $DestPath3 -DestChildFolder $DestChild3 -FileName $DestChild3File1 -RemoveLevel Child -RemoveOnly

    }
    Else {
        ProcessContent -SourcePath $SourcePath1 -DestPath $DestPath1 -DestChildFolder $DestChild1 -RemoveLevel Root
        ProcessContent -SourcePath $SourcePath2 -DestPath $DestPath2 -DestChildFolder $DestChild2 -RemoveLevel Child -Hide
        ProcessContent -SourcePath $SourcePath3 -DestPath $DestPath3 -DestChildFolder $DestChild3 -FileName $DestChild3File1 -RemoveLevel File -Hide
    }
}

&$main
Stop-Transcript