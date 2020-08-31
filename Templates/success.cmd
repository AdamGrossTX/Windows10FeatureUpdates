REM Windows 10 2004 and above
REM https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-enable-custom-actions
@ECHO ON
Echo BEGIN %%CommandName%%.cmd >> %%LogPath%%\%%LogPrefix%%-%%CommandName%%.log

START Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "%%ScriptsPath%%\%%ScriptNameAndParams%%" -CallingScript %%CommandName%%

Echo END %%CommandName%%.cmd >> %%LogPath%%\%%LogPrefix%%-%%CommandName%%.log