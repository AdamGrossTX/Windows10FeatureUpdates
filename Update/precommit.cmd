@ECHO ON
Echo BEGIN precommit.cmd >> c:\Windows\CCM\Logs\FeatureUpdate-precommit.Log

c:
cd /d %~dp0
cmd /c whoami >> c:\Windows\CCM\Logs\FeatureUpdate-precommit.log

ECHO PreCommit!! >> c:\Windows\CCM\Logs\FeatureUpdate-precommit.log
REM %SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File .\YourScript.ps1 -add

Echo Finished precommit >> c:\Windows\CCM\Logs\FeatureUpdate-precommit.Log