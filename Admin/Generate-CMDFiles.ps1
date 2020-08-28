<#
.SYNOPSIS
    Quick script to generate new CMD files for Windows 10 Feature Updates. You should not need to update this file
.DESCRIPTION
    Creates Failure.cmd, ErrorHandler.cmd and SetupComplete.cmd with the same content.
.PARAMETER LogPath
    Path for script logs to be stored
    Default is "C:\Windows\CCM\Logs"
.PARAMETER CopyLogsPath
    Path and file name for the copy logs script
    Default is "C:\~FeatureUpdateTemp\Scripts\Process-FeatureUpdateLogs.ps1"
.PARAMETER OutputPathRoot
    Path where new cmd files will be generated
.PARAMETER ScriptsToGen
    Dpecify which script to generate and paths to store them.
    Defaults:
    "failure"       = "$($OutputPathRoot)\Update"
    "SetupComplete" = "$($OutputPathRoot)\Scripts"
    #"ErrorHandler" = "$($OutputPathRoot)\Scripts" #Not going to export this one for now since I don't have anything new for it to do. Failure.cmd will do the same work for now. This is used for post-rollback.
}

.NOTES
  Version:          1.2
  Author:           Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:    08/08/2019
  Purpose/Change:
    1.0 Initial script development
    1.1 Updated formatting
    1.2 More formatting changes

#>
[cmdletbinding()]
Param (
    [Parameter()]
    [string]$LogPath = "C:\Windows\CCM\Logs",

    [Parameter()]
    [string]$CopyLogsPath = "C:\~FeatureUpdateTemp\Scripts\Process-FeatureUpdateLogs.ps1",

    [Parameter()]
    [string]$OutputPathRoot = ".",

    [Parameter()]
    $ScriptsToGen = @{
        "failure"       = "$($OutputPathRoot)\Update"
        "SetupComplete" = "$($OutputPathRoot)\Scripts"
    }
)

Try {
    $script:tick = [char]0x221a
    ForEach ($Key in $ScriptsToGen.Keys) {
        Write-Host " + Generating $($Key).cmd" -ForegroundColor Cyan -NoNewline
        $Content = @"
@ECHO ON
Echo BEGIN $($Key).cmd >> c:\Windows\CCM\Logs\FeatureUpdate-$($Key).Log

START Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$($CopyLogsPath)`" -CallingScript $($Key)

Echo END $($Key).cmd >> $($LogPath)\FeatureUpdate-$($Key).Log
"@
        New-Item -Path $ScriptsToGen[$Key] -ItemType Directory -Force | Out-Null
        $OutPath = Join-Path -Path $ScriptsToGen[$Key] -ChildPath "$($Key).cmd"
        $Content | Set-Content -Path $OutPath -Force -Encoding Default
        Write-Host $Script:tick -ForegroundColor green
    }
}
Catch {
    Write-Error "Error creating scripts."
    Throw $_
}