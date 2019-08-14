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
    [string]$NetworkLogPath = "\\CM01\FeatureUpdateLogs$",
    [string]$LocalLogRoot = "C:\~FeatureUpdateTemp\Logs",
    [string]$TranscriptPath = "C:\Windows\CCM\Logs\FeatureUpdate-CopyLogs.log",
    [string]$SetupDiagPath,
    [Parameter()]
    [ValidateSet("FeatureUpdate")]
    [string]$Type = "FeatureUpdate",
    [switch]$SkipSetupDiag,
    [string]$Username,
    [string]$Password
)

#Import the Process-Content script/function. This file should be present in the folder where you are launching this file from, or you need to change the path.
. (Join-Path -Path $PSScriptRoot -ChildPath ".\Process-Content.PS1")

#region main ########################
$main = {

   #cleanup any existing logs
    Remove-Item $TranscriptPath -Force -recurse -Confirm:$False -ErrorAction SilentlyContinue | Out-Null
    Start-Transcript -Path $TranscriptPath -Force -Append -NoClobber -ErrorAction Continue

    Try {

        #Variables
        $DateString = Get-Date -Format yyyyMMdd_HHmmss
        $IncompletePantherLogPath = "c:\`$WINDOWS.~BT\Sources\Panther"
        $CompletedPantherLogPath = "c:\Windows\Panther"
        $ResultsXMLPath = Join-Path -Path $LocalLogRoot -ChildPath "FeatureUpdateResults.XML"
        #Check to see if panther log exists
        If(Test-Path -Path $IncompletePantherLogPath -ErrorAction SilentlyContinue) {
            #If this path exists, the FeatureUpdate likely failed
            $PantherLogPath = $IncompletePantherLogPath
        }
        Else {
            $PantherLogPath = $CompletedPantherLogPath
        }

        #Run SetupDiag and Parse Results
        $Status = "Unknown"
        $SetupAct = Join-Path -Path $PantherLogPath -ChildPath "setupact.log"
        $startDate = Get-Date
        $LogsFinalized = $False

        Do {
            $LastLogLine = Get-Content -Path $SetupAct -Tail 1 -ErrorAction SilentlyContinue
            Write-host "LastLogLine: $($LastLogLine)"
            If($LastLogLine -Like "*Ending TrustedInstaller finalization.")
            {
                Write-Host "Logs have been finalized. Proceeding to run SetupDiag."
                $LogsFinalized = $True
            }
            Else {
                Write-Host "Waiting for logs to be finalized."
                Start-Sleep -Seconds 10
                $LogsFinalized = $False
            }
            
        } While ($LogsFinalized -eq $False -and $startDate.AddMinutes(10) -gt (Get-Date))

        If(!($LogsFinalized)) { 
            Write-Host "Timed out waiting for logs to be finalized. Will attempt to run SetupDiag anyway."
            #RegAdd Here - since we can't run setupdiag - not sure what we want to do to try again later.
            #Also, how do we handle this on failure?
        }
        Write-Host "Starting SetupDiag"
        
        $Status = 
        If($SkipSetupDiag.IsPresent) {
            "SkippedSetupDiag"
        }
        Else {
        $Results = Invoke-SetupDiag -XMLPath $ResultsXMLPath -SetupDiagPath $SetupDiag -LogPath $LocalLogRoot
            If($Results) {
                Switch ($Results.ErrorProfile) {
                            'FindSuccessfulUpgrade' {"Success"; break;}
                            'No Match Found' {"NoMatchFound"; break;}
                            $null {"NoResults"; break;}
                            default {"Failed"; break;} #If we get a value, that means that we got a value
                        }
            }
            Else {
                "NoResults"
            }
        }

        $SourcePath1 = "c:\Windows\Logs\MoSetup"
        $DestPath1 = $LocalLogRoot
        $DestChild1 = "MoSetup"
    
        $SourcePath2 = "c:\Windows\Logs\DISM"
        $DestPath2 = $LocalLogRoot
        $DestChild2 = "DISM"

        $SourcePath3 = "C:\Windows\CCM\Logs"
        $DestPath3 = $LocalLogRoot
        $DestPath3File1 = "FeatureUpdate-*.Log"

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
      
        ProcessContent -SourcePath $SourcePath1 -DestPath $DestPath1 -DestChildFolder $DestChild1 -RemoveLevel Child -ErrorAction Continue
        ProcessContent -SourcePath $SourcePath2 -DestPath $DestPath2 -DestChildFolder $DestChild2 -RemoveLevel Child -ErrorAction Continue
        ProcessContent -SourcePath $SourcePath3 -DestPath $DestPath3 -FileName $DestPath3File1 -RemoveLevel File -ErrorAction Continue

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

Function Invoke-SetupDiag {
    Param (
        [string]$XMLPath,
        [string]$SetupDiagPath,
        [string]$LogPath
    )

    If([string]::IsNullOrEmpty($SetupDiagPath)) {
        $SetupDiagPath = $PSScriptRoot
    }

    Write-Host "Running SetupDiag to gather deployment results."
    try{
        If(Test-Path "$($SetupDiagPath)\setupdiag.exe") {
            New-Item -Path $LogPath -ItemType Directory -ErrorAction SilentlyContinue -Force
            Start-Process -FilePath "$($SetupDiagPath)\setupdiag.exe" -ArgumentList "/Output:$($ResultsXMLPath) /Format:XML /AddReg /Verbose" -WindowStyle Hidden -Wait -ErrorAction Stop
            [XML]$xml = Get-Content -Path $ResultsXMLPath -ErrorAction Stop
        }
        Else {
            Write-Host "Setupdiag.exe not found."
        }
    }
    catch {
        Write-Host "An error occurred running SetupDiag."
        return $null
    }

    Write-Host "Parsing SetupDiag Results."
    try {
        
        $XMLResults = $xml.SetupDiag
        $ErrorList = @{}
        $ErrorList["ErrorProfile"] = $XMLResults.ProfileName

        If($XMLResults.FailureDetails) {
            $XMLResults.FailureDetails.Split(',').Trim() | ForEach-Object {
                If($_ -like "*KB*") {
                    $key,$value = $_.Split(' ').Trim()
                }
                Else {
                    $key,$value = $_.Split('=').Trim()    
                }
                $ErrorList[$key] = $value
            }
        }

        $ErrorList["Remediation"] = $XMLResults.Remediation
        $ErrorList | Out-File "$($LocalLogRoot)\SetupDiagSummary.Log"
        Return $ErrorList
    }
    catch {
        Write-Host "An error occurred processing SetupDiag results."
        Return $null
    }
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