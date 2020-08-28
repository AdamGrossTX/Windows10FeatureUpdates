#No Logged In User Discovery
Try {
    If(Get-CimInstance -Namespace "ROOT\ccm\ClientSDK" -ClassName "CCM_SoftwareUpdate" -Filter ("ErrorCode = 2149842976") -ErrorAction Stop) {
        Return "Non-Compliant"
    }
    Else {
        Return "Compliant"
    }
}
Catch {
    Return "Non-Compliant"
}