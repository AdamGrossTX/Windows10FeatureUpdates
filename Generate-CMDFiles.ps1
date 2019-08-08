<#
.SYNOPSIS
    Quick script to generate new CMD files for Windows 10 Feature Updates.
.DESCRIPTION
    Creates Failure.cmd, ErrorHandler.cmd and SetupComplete.cmd with the same content.

.NOTES
  Version:          1.0
  Author:           Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:    08/08/2019
  Purpose/Change:   Initial script development
        
#>


$LogPath = "C:\Windows\CCM\Logs"
$CopyLogsPath = "C:\~FUTemp\Scripts\Copy-FULogs.ps1"
$OutputPathRoot = "."

$ScriptsToGen = @{
    "failure" = "$($OutputPathRoot)\Update"
    "ErrorHandler" = "$($OutputPathRoot)\Scripts"
    "SetupComplete" = "$($OutputPathRoot)\Scripts"
}

ForEach ($Key in $ScriptsToGen.Keys) {

$Content = @"
@ECHO ON
Echo BEGIN $($Key).cmd >> c:\Windows\CCM\Logs\FU-$($Key).Log

START /WAIT Powershell.exe -ExecutionPolicy Bypass -File `"$($CopyLogsPath)`" >> $($LogPath)\FU-$($Key).Log

Echo END Failure.cmd >> $($LogPath)\FU-$($Key).Log
"@

New-Item -Path $ScriptsToGen[$Key] -ItemType Directory -Force
$OutPath = Join-Path -Path $ScriptsToGen[$Key] -ChildPath "$($Key).cmd"

$Content | Set-Content -Path $OutPath -Force -Encoding Default

}
