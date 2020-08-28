#No Logged On User Remdiation
Param (
    $IncomingValue
)

Try {
    Get-Service wuauserv | Stop-Service -Force
    Get-Item -Path "C:\Windows\SoftwareDistribution\Download\*"  | Remove-Item -Force -Recurse
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
Catch {
    Return $_
}