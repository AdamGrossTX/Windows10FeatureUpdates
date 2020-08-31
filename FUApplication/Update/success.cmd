REM Windows 10 2004 and above
REM https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-enable-custom-actions
@ECHO ON
Echo BEGIN success.cmd >> C:\Windows\CCM\Logs\FeatureUpdate-success.log

START Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\~FeatureUpdateTemp\Scripts\Process-FeatureUpdateLogs.ps1" -CallingScript success

Echo END success.cmd >> C:\Windows\CCM\Logs\FeatureUpdate-success.log
