<#
.SYNOPSIS
    Gathers various Feature Update logs
.DESCRIPTION
    Gathers Feature Update logs, runs setupdiag.exe and parses it, then copies the results to a network share
.PARAMETER NetworkLogPath
    Path to network share that EVERYONE has full control to. If you secure this share, the UserName and Password params are also required
.PARAMETER LocalLogRoot
    Local path where logs will be gathered to. If network share is unavailable, logs will be copied here for local review.
.PARAMETER TranscriptPath
    Path where a transcript log file for this script will be written to.
.PARAMETER Type
    The deployment type that was performed. You may not need/care. We have several deployment types and this value is included in the output folder name
.PARAMETER SkipSetupDiag
    Don't run SetupDiag
.PARAMETER Username
    Optional - Username for network log share permissions
.PARAMETER Password
    Optional - Password for network log share permissions

.NOTES
  Version:          1.0
  Author:           Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:    08/08/2019
  Purpose/Change:   Initial script development
  
#>

[cmdletbinding()]
param (
    [string]$NetworkLogPath = "\\CM01\FeatureUpdateLogs$", #In case the log path isn't set
    [string]$LocalFileRoot = "C:\~FeatureUpdateTemp",
    [string]$TranscriptPath = "C:\Windows\CCM\Logs\FeatureUpdate-ProcessLogs.log",
    [string]$CallingScript = "SetupComplete",
    [string]$Type = "FeatureUpdate",
    [switch]$SkipSetupDiag=$False,
    [string]$Username,
    [string]$Password
)

#Import the Process-Content script/function. This file should be present in the folder where you are launching this file from, or you need to change the path.
. (Join-Path -Path $PSScriptRoot -ChildPath ".\Process-Content.PS1")
. (Join-Path -Path $PSScriptRoot -ChildPath ".\Process-SetupDiag.ps1")

#region main ########################
$main = {

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
        Write-Host $Error[0]
    }

    Write-Host "Copy Logs Completed."
    Stop-Transcript

}

#endregion #######################

#region functions#################

Function Authenticate {
    Param (
        [string]$UNCPath = $(Throw "An UNCPath must be specified"),
        [string]$User,
        [string]$PW
    )

    $Auth = $false
    Try {
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = "net.exe"
        $pinfo.UseShellExecute = $false
        $pinfo.Arguments = "USE $($UNCPath) /USER:$($User) $($PW)"
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $pinfo
        $p.Start() | Out-Null
        $p.WaitForExit()
        $Auth = $true
    }
    Catch {
        Write-Host "Auth failed when connecting to network share $($UNCPath)" 
        $Auth = $false
    }
    Return $Auth
}

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

        If($PreAuth) {
            $AuthPassed = Authenticate -UNCPath $NetworkLogPath -User $Username -PW $Password
        }
        Else {
            $AuthPassed = $True
        }

        $BasePath = "{0}\{1}\" -f $RootDestPath,$ComputerName
        $Fields = $Date,$Type,$Status,$BuildNumber,$ErrorCode,$ErrorExCode
        $DestChild = (($Fields | where-object { $_ }) -join "_")

        Write-Host "Copying $($LocalLogRoot) to $($OutputLogPath)"

        If ($AuthPassed) {
            ProcessContent -SourcePath $SourcePath -DestPath $BasePath -DestChildFolder $DestChild
        } 
        Else {
            Write-Host "Network Auth Failed. Check Local Logs."
        }
    }
    Catch {
        Write-Host "An Error occurred copying logs"
        Throw $Error
    }
}

  
#endregion #######################

# Calling the main function
&$main
# ------------------------------------------------------------------------------------------------
# END