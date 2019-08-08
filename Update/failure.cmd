@ECHO ON
Echo BEGIN failure.cmd >> c:\Windows\CCM\Logs\FU-failure.Log

START /WAIT Powershell.exe -ExecutionPolicy Bypass -File "C:\~FUTemp\Scripts\Copy-FULogs.ps1" >> C:\Windows\CCM\Logs\FU-failure.Log

Echo END Failure.cmd >> C:\Windows\CCM\Logs\FU-failure.Log
