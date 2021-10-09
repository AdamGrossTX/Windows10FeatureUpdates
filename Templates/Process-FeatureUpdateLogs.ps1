<#
.SYNOPSIS
    Gathers various Feature Update logs
.DESCRIPTION
    Gathers Feature Update logs, runs setupdiag.exe and parses it, then copies the results to a network share
.PARAMETER NetworkLogPath
    Path to network share that EVERYONE can create and delete files and folders on.
.PARAMETER LocalLogRoot
    Local path where logs will be gathered to. If network share is unavailable, logs will be copied here for local review.
.PARAMETER TranscriptPath
    Path where a transcript log file for this script will be written to.
.PARAMETER Type
    The deployment type that was performed. You may not need/care. We have several deployment types and this value is included in the output folder name
.PARAMETER SkipSetupDiag
    Don't run SetupDiag

.NOTES
  Version:          1.1
  Author:           Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:    08/08/2019
  Purpose/Change:
    1.0 Initial script development
    1.1 Updated formatting
    1.2 Removed Auth function
#>

[cmdletbinding()]
param (
    [Parameter()]
    [string]$NetworkLogPath,

    [Parameter()]
    [string]$LocalFileRoot,

    [Parameter()]
    [string]$TranscriptPath,

    [Parameter()]
    [string]$CallingScript = "SetupComplete",

    [Parameter()]
    [string]$Type = "FeatureUpdate",

    [Parameter()]
    [switch]$SkipSetupDiag=$False
)

#Import the Process-Content script/function. This file should be present in the folder where you are launching this file from, or you need to change the path.
. (Join-Path -Path $PSScriptRoot -ChildPath ".\Process-Content.PS1")
. (Join-Path -Path $PSScriptRoot -ChildPath ".\Process-SetupDiag.ps1")

#region main ########################
$main = {

    if($TranscriptPath) {
    #cleanup any existing logs
        Remove-Item $TranscriptPath -Force -recurse -Confirm:$False -ErrorAction SilentlyContinue | Out-Null
        Start-Transcript -Path $TranscriptPath -Force -Append -NoClobber -ErrorAction Continue

        Try {

            #Variables
            $DateString = Get-Date -Format yyyyMMdd_HHmmss
            $LocalLogRoot = Join-Path -Path $LocalFileRoot -ChildPath "Logs"
            $LocalScriptRoot = Join-Path -Path $LocalFileRoot -ChildPath "Scripts"

            #Run SetupDiag and Parse Results
            $Status = Process-SetupDiag -LocalLogRoot $LocalLogRoot -CallingScript $CallingScript -SkipSetupDiag:$SkipSetupDiag

            $Sources = @{
                "MoSetup" = @{
                    SourcePath = "c:\Windows\Logs\MoSetup"
                    DestPath = $LocalLogRoot
                    DestChildFolder = "MoSetup"
                    RemoveLevel = 'Child'
                }
                #Removing DISM since the logs tend to be quite large.
                "DISM" = @{
                    DestPath = "$($LocalLogRoot)\DISM"
                    RemoveLevel = 'Root'
                    RemoveOnly = $True
                }
                "FeatureUpdateLogs" = @{
                    SourcePath = "C:\Windows\CCM\Logs"
                    DestPath = $LocalLogRoot
                    FileName = "FeatureUpdate-*.Log"
                    RemoveLevel = 'File'
                }
                "SetupDiagLogs" = @{
                    SourcePath = $LocalScriptRoot
                    DestPath = $LocalLogRoot
                    FileName = "SetupDiag_*.Log"
                    RemoveLevel = 'File'
                }
            }

            $OSInfo = Get-CIMInstance -Class Win32_OperatingSystem
            Write-Host "OSInfo"
            Write-Host "BuildNumber: $($OSInfo.BuildNumber)"
            Write-Host "SerialNumber: $($OSInfo.SerialNumber)"
            Write-Host "Version: $($OSInfo.Version)"

            Write-Host "Panther Log Path : $($PantherLogPath)"
            Write-Host "Setting status to: $($Status)"
            Write-Host "SystemRoot : $($Env:SystemRoot)\logs\DISM"
            Write-Host "Local Log Path : $($LocalLogRoot)"
            Write-Host "Computername : $($ENV:COMPUTERNAME)"
            Write-Host "Calling Script : $($CallingScript)"

            ForEach($Key in $Sources.keys) {
                $Args = $Sources[$Key]
                ProcessContent @Args -ErrorAction Continue
            }

            #Pause so that setup can exit.
            Copy-LogsToNetwork -SourcePath $LocalLogRoot -RootDestPath $NetworkLogPath -ComputerName $ENV:COMPUTERNAME -Date $DateString -Type $Type -Status $Status -BuildNumber $OSInfo.BuildNumber -ErrorCode $Results.ErrorCode -ErrorExCode $Results.ExCode -PreAuth:$false

        }
        Catch {
            Throw $_
        }

        Write-Host "Copy Logs Completed."
        Stop-Transcript
    }
    else {
        throw "This file wasn't built properly. Please use SetupFUFramework and try again."
    }

}

#endregion

#region functions
Function Copy-LogsToNetwork {
    Param (
        [string]$SourcePath,
        [string]$RootDestPath,
        [string]$ComputerName,
        [string]$Date,
        [string]$Type,
        [string]$Status,
        [string]$BuildNumber,
        [string]$ErrorCode,
        [string]$ErrorExCode,
        [switch]$PreAuth=$false
    )

    Try {

        $BasePath = "{0}\{1}\" -f $RootDestPath,$ComputerName
        $Fields = $Date,$Type,$Status,$BuildNumber,$ErrorCode,$ErrorExCode
        $DestChild = (($Fields | where-object { $_ }) -join "_")
        Write-Host "Copying $($LocalLogRoot) to $($OutputLogPath)"
        ProcessContent -SourcePath $SourcePath -DestPath $BasePath -DestChildFolder $DestChild
    }
    Catch {
        Write-Host "An Error occurred copying logs"
        Throw $_
    }
}
#endregion

& $main