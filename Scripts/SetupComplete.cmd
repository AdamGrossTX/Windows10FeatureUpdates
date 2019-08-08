@ECHO ON
Echo BEGIN SetupComplete.cmd >> c:\Windows\CCM\Logs\FU-SetupComplete.Log

START /WAIT Powershell.exe -ExecutionPolicy Bypass -File "C:\~FUTemp\Scripts\Copy-FULogs.ps1" >> C:\Windows\CCM\Logs\FU-SetupComplete.Log

Echo END Failure.cmd >> C:\Windows\CCM\Logs\FU-SetupComplete.Log
