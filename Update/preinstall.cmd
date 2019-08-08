@ECHO ON
Echo BEGIN preinstall.cmd >> c:\Windows\CCM\Logs\FU-preinstall.Log

c:
cd /d %~dp0
cmd /c whoami >> c:\Windows\CCM\Logs\FU-preinstall.log

ECHO PreCommit!! >> c:\Windows\CCM\Logs\FU-preinstall.log
REM %SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File .\YourScript.ps1 -add >> c:\Windows\CCM\Logs\FU-YourScript.log

Echo Finished precommit >> c:\Windows\CCM\Logs\FU-preinstall.Log