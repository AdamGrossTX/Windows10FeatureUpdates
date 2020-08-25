<#
.SYNOPSIS
    Runs SetupDiag.exe and parses the results to determine success or failure for a Windows 10 Feature Update.
.DESCRIPTION
    Runs SetupDiag.exe and parses the results to determine success or failure for a Windows 10 Feature Update.
.PARAMETER LocalLogRoot
    Local path where logs will be gathered to. If network share is unavailable, logs will be copied here for local review.
.PARAMETER SetupDiagPath
    Path to where SetupDiag.exe is. Defaults to PSScriptRoot
.PARAMETER CallingScript
    The name of the script that called SetupDiag
.PARAMETER SkipSetupDiag
    If you want to skip running setupdiag and just re-process existing results, set to $Trus
.PARAMETER WriteRegKey
    Allows the script to add a custom registry key under the SetupDiag registry key HKEY_LOCAL_MACHINE\SYSTEM\Setup\MoSetup\Volatile\SetupDiag
    The key is CustomSetupDiagResult.

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
Function Process-SetupDiag {
    [cmdletbinding()]
    param (
        [string]$LocalLogRoot = "C:\~FeatureUpdateTemp\Logs",
        [string]$CallingScript = "None",
        [string]$TranscriptPath = "C:\Windows\CCM\Logs\FeatureUpdate-ProcessSetupDiag.log",
        [string]$SetupDiagPath = $PSScriptRoot,
        [switch]$SkipSetupDiag,
        [switch]$SkipWriteRegKey
    )
        #Set the status to the script name that called it until we process the results.
        $Status = $CallingScript

        #cleanup any existing logs
        Remove-Item $TranscriptPath -Force -recurse -Confirm:$False -ErrorAction SilentlyContinue | Out-Null
        Remove-Item "$($LocalLogRoot)\Logs*.zip" -Force -recurse -Confirm:$False -ErrorAction SilentlyContinue | Out-Null
        Remove-Item "$($LocalLogRoot)\SetupDiag*.log" -Force -recurse -Confirm:$False -ErrorAction SilentlyContinue | Out-Null

        Start-Transcript -Path $TranscriptPath -Force -Append -NoClobber -ErrorAction Continue | Out-Null

        #set variables
        $ResultsXMLPath = Join-Path -Path $LocalLogRoot -ChildPath "FeatureUpdateResults.XML"
        $SetupDiagKeyPath = "HKLM:\System\Setup\MoSetup\Volatile\SetupDiag"
        $SummaryLogName = "SetupDiagSummary.log"
        $OutputLog = "$($LocalLogRoot)\$($SummaryLogName)"
        $CustomRegKeyName = "CustomSetupDiagResult" #Creates a custom key to hold the Success or Failure status after we process setupdiag output.
        $IncompletePantherLogPath = "c:\`$WINDOWS.~BT\Sources\Panther"
        $CompletedPantherLogPath = "c:\Windows\Panther"
        $ResultsXMLPath = Join-Path -Path $LocalLogRoot -ChildPath "FeatureUpdateResults.XML"

        If(!($SkipSetupDiag.IsPresent)) {
            #Check to see if panther log exists
            If(Test-Path -Path $IncompletePantherLogPath -ErrorAction SilentlyContinue) {
                #If this path exists, the FeatureUpdate likely failed
                $PantherLogPath = $IncompletePantherLogPath
            }
            Else {
                $PantherLogPath = $CompletedPantherLogPath
            }


            If($CallingScript -eq "SetupComplete") {
                $SetupAct = Join-Path -Path $PantherLogPath -ChildPath "setupact.log"
                $startDate = Get-Date
                $LogsFinalized = $False

                Do {
                    $LastLogLine = Get-Content -Path $SetupAct -Tail 1 -ErrorAction SilentlyContinue
                    If($LastLogLine -Like "*Ending TrustedInstaller finalization.")
                    {
                        Write-Host "Logs have been finalized. Proceeding to run SetupDiag."
                        $LogsFinalized = $True
                    }
                    Else {
                        Write-Host "Waiting for logs to be finalized."
                        Write-host "LastLogLine: $($LastLogLine)"
                        Start-Sleep -Seconds 10
                        $LogsFinalized = $False
                    }

                } While ($LogsFinalized -eq $False -and $startDate.AddMinutes(10) -gt (Get-Date))

                If(!($LogsFinalized)) {
                    Write-Host "Timed out waiting for logs to be finalized. Will attempt to run SetupDiag anyway."
                }
            }
        }

        #Do work
        Write-Host "Running SetupDiag to gather deployment results."
        Try{
            New-Item -Path $LocalLogRoot -ItemType Directory -ErrorAction SilentlyContinue -Force | Out-Null
            If(!($SkipSetupDiag.IsPresent)) {
                If(Test-Path "$($SetupDiagPath)\setupdiag.exe") {
                    Remove-Item -path $ResultsXMLPath -Force -ErrorAction SilentlyContinue | Out-Null
                    Start-Process -FilePath "$($SetupDiagPath)\setupdiag.exe" -ArgumentList "/Output:$($ResultsXMLPath) /Format:XML /AddReg /Verbose" -WindowStyle Hidden -Wait -ErrorAction Stop
                }
                Else {
                    Write-Host "Setupdiag.exe not found."
                }
            }
            [XML]$xml = Get-Content -Path $ResultsXMLPath -ErrorAction Stop
        }
        Catch {
            Write-Host "An error occurred running SetupDiag."
            Throw $Error[0]
        }

        Write-Host "Parsing SetupDiag Results."
        Try {

            $XMLResults = $xml.SetupDiag
            $ResultsList = @{}
            $ResultsList["ErrorProfile"] = $XMLResults.ProfileName
            $ResultsList["Remediation"] = $XMLResults.Remediation

            If($XMLResults.FailureDetails) {
                $XMLResults.FailureDetails.Split(',').Trim() | ForEach-Object {
                    If($_ -like "*KB*") {
                        $key,$value = $_.Split(' ').Trim()
                    }
                    Else {
                        $key,$value = $_.Split('=').Trim()
                    }
                    $ResultsList[$key] = $value
                }
            }

            If($XMLResults.FailureData) {
                $FailureData = $XMLResults.FailureData.Split([Environment]::NewLine)
                If($FailureData -like '*SetupDiag reports successful upgrade found.*'){
                    $ResultsList["UpgradeStatus"] = "Success"
                }
                ElseIf($FailureData -like '*SetupDiag was unable to match to any known failure signatures.*') {
                    $ResultsList["UpgradeStatus"] = "NoMatchFound"
                }
                Else {
                    $ResultsList["UpgradeStatus"] = "Failed"
                }
            }
            Else {
                $ResultsList["UpgradeStatus"] = "Unknown"
            }

            #Export ResultsList to file
            ForEach($Key in $ResultsList.Keys) {
                Add-Content -Path $OutputLog -Force -Value ("{0} : {1}" -f $key,($ResultsList[$key] | out-string))
            }
            #Add FailureData separately last since it may have multiple lines
            Add-Content -Path $OutputLog -Force -Value ("{0} : {1}" -f "FailureData",($FailureData | ForEach-Object {"      " + $_} | Out-String))

            If($ResultsList.UpgradeStatus) {
                $Status = $ResultsList.UpgradeStatus
            }
            Else {
                $Status = "NoResults"
            }

            If(!($SkipWriteRegKey.IsPresent)) {
                If(Get-Item -Path $SetupDiagKeyPath -ErrorAction SilentlyContinue) {
                    New-ItemProperty -Path $SetupDiagKeyPath -Name $CustomRegKeyName -Value $Status -PropertyType string -Force | Out-Null
                }
            }
        }
        Catch {
            Write-Host "An error occurred processing SetupDiag results."
            Throw $Error[0]
        }

        Write-Host $Status
        Write-Host "Copy Logs Completed."
        Stop-Transcript | Out-Null
        Return $Status
    }