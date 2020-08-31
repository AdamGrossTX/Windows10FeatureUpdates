@ECHO ON
Echo BEGIN %%CommandName%%.cmd >> %%LogPath%%\%%LogPrefix%%-%%CommandName%%.log

START Powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "%%ScriptsPath%%\%%ScriptNameAndParams%%" -CallingScript %%CommandName%%

Echo END %%CommandName%%.cmd >> %%LogPath%%\%%LogPrefix%%-%%CommandName%%.log