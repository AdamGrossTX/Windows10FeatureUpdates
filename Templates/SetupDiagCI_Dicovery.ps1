#SetupDiag Discovery
[cmdletbinding()]
Param()
try {
    $Value1 = Get-ItemPropertyValue -Path "HKLM:\System\Setup\MoSetup\Volatile\SetupDiag" -Name "CustomSetupDiagResult" -ErrorAction SilentlyContinue
    $Value2 = Get-ItemPropertyValue -Path "HKLM:\System\Setup\MoSetup\Volatile\SetupDiag" -Name "DateTime" -ErrorAction SilentlyContinue
    if(($Value1 -eq 'Failed' -or $Value1 -eq 'Success') -and $Value2) {
        Return $True
    }
    Else {
        Return $False
    }
}
Catch {
    Return $False
}
