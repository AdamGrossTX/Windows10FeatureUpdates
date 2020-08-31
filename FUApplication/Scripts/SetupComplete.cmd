@ECHO ON
Echo BEGIN SetupComplete.cmd >> C:\Windows\CCM\Logs\FeatureUpdate-SetupComplete.log

START Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\~FeatureUpdateTemp\Scripts\Process-FeatureUpdateLogs.ps1" -CallingScript SetupComplete

Echo END SetupComplete.cmd >> C:\Windows\CCM\Logs\FeatureUpdate-SetupComplete.log
