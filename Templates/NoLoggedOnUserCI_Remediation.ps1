#No Logged On User Remdiation
Param (
    $IncomingValue
)

Try {
    $SoftwareDistFolder = "$($env:windir)\SoftwareDistribution\Download"
    If(Test-Path $SoftwareDistFolder) {
        Get-Service wuauserv | Stop-Service -Force
        Get-ChildItem -Path $SoftwareDistFolder | Remove-Item -Force -Recurse
        Start-Service wuauserv

        $Actions = @(
            "{00000000-0000-0000-0000-000000000021}",
            "{00000000-0000-0000-0000-000000000022}",
            "{00000000-0000-0000-0000-000000000108}"
        )

        ForEach ($Action in $Actions) {
            $Filter = "InventoryActionID = '{0}'" -f $Action
            Get-CIMInstance -Namespace "ROOT\ccm\invagt" -ClassName InventoryActionStatus -Filter $Filter | Remove-CimInstance -ErrorAction SilentlyContinue | Out-Null
            $ArgList = @{sScheduleID = $Action}
            Invoke-CimMethod -Namespace "root\ccm" -ClassName "SMS_Client" -MethodName TriggerSchedule -Arguments $ArgList -ErrorAction Stop  | Out-Null
        }
    }
    Else {
        Throw "$($SoftwareDistFolder) not found. No Action Taken."
    }
}
Catch {
    Return $_
}