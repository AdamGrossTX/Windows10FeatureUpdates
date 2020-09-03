REM Windows 10 2004 and above
REM https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-enable-custom-actions
@ECHO ON
Echo BEGIN postuninstall.cmd >> \\media.cpchem.net\osd$\FUApplication\FeatureUpdate-postuninstall.log

START Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "\\media.cpchem.net\osd$\FUApplication\Scripts\Process-FeatureUpdateLogs.ps1" -CallingScript postuninstall

Echo END postuninstall.cmd >> \\media.cpchem.net\osd$\FUApplication\FeatureUpdate-postuninstall.log
