<#
.SYNOPSIS
    Quick script to generate new CMD files for Windows 10 Feature Updates.
.DESCRIPTION
    Creates Failure.cmd, ErrorHandler.cmd and SetupComplete.cmd with the same content.

.NOTES
  Version:          1.1
  Author:           Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:    08/08/2019
  Purpose/Change:
    1.0 Initial script development
    1.1 Updated formatting

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
    [string]$ScriptsToGen = @{
        "failure"       = "$($OutputPathRoot)\Update"
        #"ErrorHandler" = "$($OutputPathRoot)\Scripts" #Not going to export this one for now since I don't have anything new for it to do. Failure.cmd will do the same work for now. This is used for post-rollback.
        "SetupComplete" = "$($OutputPathRoot)\Scripts"
    }
)

Try {
    ForEach ($Key in $ScriptsToGen.Keys) {
        $Content = @"
@ECHO ON
Echo BEGIN $($Key).cmd >> c:\Windows\CCM\Logs\FeatureUpdate-$($Key).Log

START Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$($CopyLogsPath)`" -CallingScript $($Key)

Echo END $($Key).cmd >> $($LogPath)\FeatureUpdate-$($Key).Log
"@

        Write-Host "Creating new $($Key) script"
        New-Item -Path $ScriptsToGen[$Key] -ItemType Directory -Force | Out-Null
        $OutPath = Join-Path -Path $ScriptsToGen[$Key] -ChildPath "$($Key).cmd"

        $Content | Set-Content -Path $OutPath -Force -Encoding Default

    }
}
Catch {
    Write-Host "Error creating scripts."
    Throw $_
}