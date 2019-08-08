@ECHO ON
Echo BEGIN precommit.cmd >> c:\Windows\CCM\Logs\FU-precommit.Log

c:
cd /d %~dp0
cmd /c whoami >> c:\Windows\CCM\Logs\FU-precommit.log

ECHO PreCommit!! >> c:\Windows\CCM\Logs\FU-precommit.log
REM %SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File .\YourScript.ps1 -add >> c:\Windows\CCM\Logs\FU-YourScript.log

Echo Finished precommit >> c:\Windows\CCM\Logs\FU-precommit.Log