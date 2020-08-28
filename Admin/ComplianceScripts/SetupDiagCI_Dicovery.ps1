#SetupDiag Discovery
[cmdletbinding()]
Param()
Try {
    $Value = Get-ItemPropertyValue -Path "HKLM:\System\Setup\MoSetup\Volatile\SetupDiag" -Name "CustomSetupDiagResult" -ErrorAction SilentlyContinue
    If($Value -eq 'Failed' -or $Value -eq 'Success') {
        Return $True
    }
    Else {
        Return $False
    }
}
Catch {
    Return $False
}