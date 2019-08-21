@ECHO ON
Echo BEGIN SetupComplete.cmd >> c:\Windows\CCM\Logs\FeatureUpdate-SetupComplete.Log

START Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\~FeatureUpdateTemp\Scripts\Process-FeatureUpdateLogs.ps1" -CallingScript SetupComplete

Echo END SetupComplete.cmd >> C:\Windows\CCM\Logs\FeatureUpdate-SetupComplete.Log