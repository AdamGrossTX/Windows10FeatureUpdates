@ECHO ON
Echo BEGIN %%CommandName%%.cmd >> %%LogPath%%\%%LogPrefix%%-%%CommandName%%.log

c:
cd /d %~dp0
cmd /c whoami >> %%LogPath%%\%%LogPrefix%%-%%CommandName%%.log

Echo END %%CommandName%%.cmd >> %%LogPath%%\%%LogPrefix%%-%%CommandName%%.log