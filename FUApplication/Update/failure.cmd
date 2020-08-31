@ECHO ON
Echo BEGIN failure.cmd >> C:\Windows\CCM\Logs\FeatureUpdate-failure.log

START Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\~FeatureUpdateTemp\Scripts\Process-FeatureUpdateLogs.ps1" -CallingScript failure

Echo END failure.cmd >> C:\Windows\CCM\Logs\FeatureUpdate-failure.log
