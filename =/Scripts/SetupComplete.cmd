@ECHO ON
Echo BEGIN SetupComplete.cmd >> \\media.cpchem.net\osd$\FUApplication\FeatureUpdate-SetupComplete.log

START Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "\\media.cpchem.net\osd$\FUApplication\Scripts\Process-FeatureUpdateLogs.ps1" -CallingScript SetupComplete

Echo END SetupComplete.cmd >> \\media.cpchem.net\osd$\FUApplication\FeatureUpdate-SetupComplete.log
