@ECHO ON
Echo BEGIN preinstall.cmd >> \\media.cpchem.net\osd$\FUApplication\FeatureUpdate-preinstall.log

c:
cd /d %~dp0
cmd /c whoami >> \\media.cpchem.net\osd$\FUApplication\FeatureUpdate-preinstall.log

Echo END preinstall.cmd >> \\media.cpchem.net\osd$\FUApplication\FeatureUpdate-preinstall.log
