@ECHO ON
Echo BEGIN precommit.cmd >> \\media.cpchem.net\osd$\FUApplication\FeatureUpdate-precommit.log

c:
cd /d %~dp0
cmd /c whoami >> \\media.cpchem.net\osd$\FUApplication\FeatureUpdate-precommit.log

Echo END precommit.cmd >> \\media.cpchem.net\osd$\FUApplication\FeatureUpdate-precommit.log
