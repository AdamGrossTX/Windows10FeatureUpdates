@ECHO ON
Echo BEGIN failure.cmd >> \\media.cpchem.net\osd$\FUApplication\FeatureUpdate-failure.log

START Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "\\media.cpchem.net\osd$\FUApplication\Scripts\Process-FeatureUpdateLogs.ps1" -CallingScript failure

Echo END failure.cmd >> \\media.cpchem.net\osd$\FUApplication\FeatureUpdate-failure.log
