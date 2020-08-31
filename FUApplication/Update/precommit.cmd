@ECHO ON
Echo BEGIN precommit.cmd >> C:\Windows\CCM\Logs\FeatureUpdate-precommit.log

c:
cd /d %~dp0
cmd /c whoami >> C:\Windows\CCM\Logs\FeatureUpdate-precommit.log

Echo END precommit.cmd >> C:\Windows\CCM\Logs\FeatureUpdate-precommit.log
