@ECHO ON
Echo BEGIN ErrorHandler.cmd >> c:\Windows\CCM\Logs\FU-ErrorHandler.Log

START /WAIT Powershell.exe -ExecutionPolicy Bypass -File "C:\~FUTemp\Scripts\Copy-FULogs.ps1" >> C:\Windows\CCM\Logs\FU-ErrorHandler.Log

Echo END Failure.cmd >> C:\Windows\CCM\Logs\FU-ErrorHandler.Log
