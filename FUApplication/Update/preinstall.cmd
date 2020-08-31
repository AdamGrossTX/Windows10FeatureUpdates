@ECHO ON
Echo BEGIN preinstall.cmd >> C:\Windows\CCM\Logs\FeatureUpdate-preinstall.log

c:
cd /d %~dp0
cmd /c whoami >> C:\Windows\CCM\Logs\FeatureUpdate-preinstall.log

Echo END preinstall.cmd >> C:\Windows\CCM\Logs\FeatureUpdate-preinstall.log
