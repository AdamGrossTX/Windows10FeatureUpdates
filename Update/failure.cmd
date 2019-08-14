@ECHO ON
Echo BEGIN failure.cmd >> c:\Windows\CCM\Logs\FeatureUpdate-failure.Log

START Powershell.exe -ExecutionPolicy Bypass -WindowStyle -Hidden -File "C:\~FeatureUpdateTemp\Scripts\Copy-FeatureUpdateLogs.ps1"

Echo END failure.cmd >> C:\Windows\CCM\Logs\FeatureUpdate-failure.Log
