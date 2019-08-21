@ECHO ON
Echo BEGIN failure.cmd >> c:\Windows\CCM\Logs\FeatureUpdate-failure.Log

START Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\~FeatureUpdateTemp\Scripts\Process-FeatureUpdateLogs.ps1" -CallingScript failure

Echo END failure.cmd >> C:\Windows\CCM\Logs\FeatureUpdate-failure.Log