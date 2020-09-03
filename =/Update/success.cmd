REM Windows 10 2004 and above
REM https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-enable-custom-actions
@ECHO ON
Echo BEGIN success.cmd >> \\media.cpchem.net\osd$\FUApplication\FeatureUpdate-success.log

START Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "\\media.cpchem.net\osd$\FUApplication\Scripts\Process-FeatureUpdateLogs.ps1" -CallingScript success

Echo END success.cmd >> \\media.cpchem.net\osd$\FUApplication\FeatureUpdate-success.log
