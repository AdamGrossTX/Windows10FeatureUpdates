#SetupDiag Remediation
[cmdletbinding()]
Param(
    $IncomingValue,
    [string]$ScriptPath = "C:\~FeatureUpdateTemp\Scripts\Process-SetupDiag.ps1"
)
. $ScriptPath
Process-SetupDiag