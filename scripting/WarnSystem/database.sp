Database g_hDatabase;

char g_sSQL_CreateTable_SQLite[] = "CREATE TABLE IF NOT EXISTS WarnSystem (id INTEGER(12) NOT NULL PRIMARY KEY AUTOINCREMENT, target VARCHAR(128) NOT NULL default '', targetid VARCHAR(32) NOT NULL default '', admin VARCHAR(128) NOT NULL default '', adminid VARCHAR(32) NOT NULL default '', reason VARCHAR(64) NOT NULL default '', time INTEGER(12) NOT NULL default 0, expired INTEGER(1) NOT NULL default 0)";
	g_sSQL_CreateTable_MySQL[] = "CREATE TABLE IF NOT EXISTS WarnSystem (id int(12) NOT NULL AUTO_INCREMENT, target VARCHAR(128) NOT NULL default '', targetid VARCHAR(32) NOT NULL default '', admin VARCHAR(128) NOT NULL default '', adminid VARCHAR(32) NOT NULL default '', reason VARCHAR(64) NOT NULL default '', time int(12) NOT NULL default 0, expired int(1) NOT NULL default 0, PRIMARY KEY (id)) CHARSET=utf8 COLLATE utf8_general_ci";
	g_sSQL_LoadPlayerData[] = "SELECT * FROM WarnSystem WHERE targetid='%s' AND expired != '1';"
	g_sSQL_WarnPlayer[] = "INSERT INTO WarnSystem (target, targetid, admin, adminid, reason, time, expired) VALUES ('%s', '%s', '%s', '%s', '%s', '%i', '0');"
	g_sSQL_DeleteWarns[] = "DELETE FROM WarnSystem WHERE targetid = '%s';";
	g_sSQL_SetExpired[] = "UPDATE WarnSystem SET expired = '1' WHERE targetid = '%s';";
	g_sSQL_SelectWarns[] = "SELECT * FROM WarnSystem WHERE targetid='%s' AND expired != '1' ORDER BY time DESC LIMIT 1;";
	g_sSQL_UnwarnPlayer[] = "DELETE FROM WarnSystem WHERE time = '%i' AND targetid = '%s';";
	g_sClientName[MAXPLAYERS+1][MAX_NAME_LENGTH];
	g_sSteamID[MAXPLAYERS+1][32];
	g_sClientIP[MAXPLAYERS+1][32];
int g_iWarnings[MAXPLAYERS+1];

public void InitializeDatabase()
{
	char sIdent[16], sError[256];
	g_hDatabase = SQL_Connect("warn", false, sError, 256);
	if(!g_hDatabase)
	{
		g_hDatabase = SQLite_UseDatabase("warn", sError, 256);
		if(!g_hDatabase)
			SetFailState("[WarnSystem] Could not connect to the database (%s)", sError);
	}

	DBDriver hDatabaseDriver = g_hDatabase.Driver;
	hDatabaseDriver.GetIdentifier(sIdent, sizeof(sIdent));
	SQL_LockDatabase(g_hDatabase);
	
	switch(sIdent[0])
	{
		case 's': if(!SQL_FastQuery(g_hDatabase, g_sSQL_CreateTable_SQLite)) SetFailState("[WarnSystem] Connect_Database - could not create table in SQLite");
		case 'm': if(!SQL_FastQuery(g_hDatabase, g_sSQL_CreateTable_MySQL)) SetFailState("[WarnSystem] Connect_Database - could not create table in MySQL");
		default: SetFailState("[WarnSystem] Connect_Database - type database is invalid");
	}
	
	SQL_UnlockDatabase(g_hDatabase);
	g_hDatabase.SetCharset("utf8");
}

public void LoadPlayerData(iClient)
{
	if(!g_hDatabase)
		SetFailState("[WarnSystem] LoadPlayerData - database is invalid");
	
	if(iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		char sSteamID[32], dbQuery[128];
		GetClientAuthId(iClient, AuthId_Steam2, sSteamID, sizeof(sSteamID));
		GetClientName(iClient, g_sClientName[iClient], sizeof(g_sClientName[iClient]));
		GetClientIP(iClient, g_sClientIP[iClient], sizeof(g_sClientIP[iClient]));
		g_sSteamID[iClient] = sSteamID;
		FormatEx(dbQuery, sizeof(dbQuery),  g_sSQL_LoadPlayerData, sSteamID);
		g_hDatabase.Query(SQL_LoadPlayerData, dbQuery, iClient);
		Fwd_OnClientLoaded(iClient);
	}
}

public void SQL_LoadPlayerData(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, int iClient)
{
	if (!hDatabaseResults)
	{
		LogError("[WarnSystem] SQL_LoadDataPlayer - error while working with data (%s)", sError);
		return;
	}
	
	if (hDatabaseResults.HasResults && hDatabaseResults.FetchRow())
	{
		g_iWarnings = SQL_GetRowCount(hDatabaseResults);
		if (g_bPrintToAdmins)
			PrintToAdmins("\x03[WarnSystem] \x01%t", "WarnConnect", g_iWarnings);
	}
}

public void WarnPlayer(int iClient, int iTarget, char sReason[64])
{
	if (iTarget && IsClientInGame(iTarget) && !IsFakeClient(iTarget))
	{
		char dbQuery[255];
		
		Handle hWarnData = CreateDataPack();
		if (iClient)
			WritePackCell(hWarnData, GetClientUserId(iClient));
		else
			WritePackCell(hWarnData, 0);
		WritePackCell(hWarnData, GetClientUserId(iTarget));
		WritePackString(hWarnData, sReason);
		ResetPack(hWarnData);
		
		FormatEx(dbQuery, sizeof(dbQuery),  g_sSQL_LoadPlayerWarnings , g_sSteamID[iTarget]);
		g_hDatabase.Query(SQL_WarnPlayer, dbQuery, hWarnData);
		
		PrintToChatAll("\x03[WarnSystem] \x01%t", "warn_warnplayer", iClient, iTarget, sReason);
		
		if(g_bWarnSound)
			EmitSoundToClient(iTarget, g_sWarnSoundPath);
		
		Fwd_OnClientWarn(iClient, iTarget, sReason);
	}
}

public void SQL_WarnPlayer(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, Handle hWarnData)
{
	if (!hDatabaseResults)
	{
		LogError("[WarnSystem] SQL_WarnPlayer - error while working with data (%s)", sError);
		return;
	}
	
	int iClient, iTarget, iTime;
	iTime = GetTime();
	char sReason[64], sEscapedClientNick[64], sEscapedTargetNick[64], sEscapedReason[64], dbQuery[255];
	
	if(hWarnData)
	{
		iClient = GetClientOfUserId(ReadPackCell(hWarnData));
		iTarget = GetClientOfUserId(ReadPackCell(hWarnData));
		ReadPackString(hWarnData, sReason, sizeof(sReason));
		CloseHandle(hWarnData);
	}
	
	SQL_EscapeString(g_hDatabase, g_sClientName[iTarget], sEscapedTargetNick, sizeof(sEscapedTargetNick));
	SQL_EscapeString(g_hDatabase, sReason, sEscapedReason, sizeof(sEscapedReason));
	
	++g_iWarnings[iTarget];
	FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_WarnPlayer, sEscapedTargetNick, g_sSteamID[iTarget], sEscapedClientNick, g_sSteamID[iClient], sEscapedReason, iTime);
	g_hDatabase.FastQuery(dbQuery);
	
	if (hDatabaseResults.FetchRow())
	{
		if (g_iWarnings >= g_iMaxWarns)
		{
			if(g_bResetWarnings)
				FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_DeleteWarns, g_sSteamID[iTarget]);
			else
				FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_SetExpired, g_sSteamID[iTarget]);
			g_hDatabase.FastQuery(dbQuery);
			
			if(g_bLogWarnings)
				LogWarnings("[WarnSystem] %t", "warn_warn_log", iClient, g_sSteamID[iClient], g_sClientIP[iClient], iTarget, g_sSteamID[iTarget], g_sClientIP[iTarget], sReason);
			
			PunishPlayerOnMaxWarns(iTarget, sReason);
		}
	}
	
	PunishPlayer(iTarget, sReason);
}

public void UnWarnPlayer(int iClient, int iTarget, char sReason[64])
{
	if (iTarget && IsClientInGame(iTarget) && !IsFakeClient(iTarget))
	{
		char dbQuery[255];
		FormatEx(dbQuery, sizeof(dbQuery),  g_sSQL_SelectWarns, g_sSteamID[iTarget]);
		
		Handle hUnwarnData = CreateDataPack();
		if (iClient)
			WritePackCell(hUnwarnData, GetClientUserId(iClient));
		else
			WritePackCell(hUnwarnData, 0);
		WritePackCell(hUnwarnData, GetClientUserId(iTarget));
		WritePackString(hUnwarnData, sSteamID);
		WritePackString(hUnwarnData, sReason);
		ResetPack(hUnwarnData);
		
		g_hDatabase.Query(SQL_UnWarnPlayer, dbQuery, hUnwarnData);
	}
}

public void SQL_UnWarnPlayer(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, Handle hUnwarnData)
{
	if (!hDatabaseResults)
	{
		LogError("[WarnSystem] SQL_UnWarnPlayer - error while working with data (%s)", sError);
		return;
	}
	
	char sReason[64], dbQuery[255];
	int iClient, iTarget;
	
	if(hUnwarnData)
	{
		iClient = GetClientOfUserId(ReadPackCell(hUnwarnData));
		iTarget = GetClientOfUserId(ReadPackCell(hUnwarnData));
		ReadPackString(hUnwarnData, sTargetID, sizeof(sTargetID));
		ReadPackString(hUnwarnData, sReason, sizeof(sReason));
		CloseHandle(hUnwarnData); 
	}
	
	if (hDatabaseResults.FetchRow())
	{
		int iTime;
		hDatabaseResults.FetchInt(6, iTime);
		
		FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_UnwarnPlayer, iTime, g_sSteamID[iTarget]);
		g_hDatabase.FastQuery(dbQuery);
		PrintToChatAll("\x03[WarnSystem] \x01", "%t", "warn_unwarn_player", iClient, iTarget, sReason);
		
		if(g_bLogWarnings)
			LogWarnings("[WarnSystem] %t", "warn_unwarn_log", iClient, g_sSteamID[iClient], g_sClientIP[iClient], iTarget, g_sSteamID[iTarget], g_sClientIP[iTarget], sReason);
	} else
		PrintToChat(iClient, "\x03[WarnSystem] \x01%t", "warn_notwarned", iTarget);
}

public void SQL_ResetWarnPlayer(Handle owner, Handle hndl, const char[] sError, Handle hResetWarnData)
{	
	if (!hndl)
	{
		InitializeDatabase();
		return;
	}
	
	if(sError[0])
	{
		LogError("SQL_ResetWarnPlayer: %s", sError);
		return;
	}
	
	int iClient, iTarget;
	char sTargetID[32], sReason[32], dbQuery[255];
	
	if(hResetWarnData)
	{
		iClient = GetClientOfUserId(ReadPackCell(hResetWarnData));
		iTarget = GetClientOfUserId(ReadPackCell(hResetWarnData));
		ReadPackString(hResetWarnData, sTargetID, sizeof(sTargetID));
		ReadPackString(hResetWarnData, sReason, sizeof(sReason));
		CloseHandle(hResetWarnData); 
	}
	
	if (SQL_FetchRow(hndl))
	{
		FormatEx(dbQuery, sizeof(dbQuery), "DELETE FROM WarnSystem WHERE targetid = '%s'", sTargetID);
		g_hDatabase.FastQuery(dbQuery);
		
		PrintToChatAll("\x03[WarnSystem] \x01", "%t", "warn_resetplayer", iTarget, sReason);
		
		if(g_bLogWarnings)
		{
			char sClientID[32], sClientIP[32], sTargetIP[32];
			if (iClient)
			{
				GetClientAuthId(iClient, AuthId_Steam2, sClientID, sizeof(sClientID));
				GetClientIP(iClient, sClientIP, sizeof(sClientIP));
			}
			else
			{
				strcopy(sClientID, sizeof(sClientID), "CONSOLE");
				strcopy(sClientIP, sizeof(sClientIP), "Unknown");
			}
			GetClientIP(iTarget, sTargetIP, sizeof(sTargetIP));
			LogWarnings("[WarnSystem] %t", "warn_resetwarn_log", iClient, sClientID, sClientIP, iTarget, sTargetID, sTargetIP, sReason);
		}
	}
	else
		PrintToChat(iClient, "\x03[WarnSystem] \x01%t", "warn_notwarned", iTarget);
}

public void SQL_CheckPlayer(Handle owner, Handle hndl, const char[] sError, Handle hCheckData)
{
	if (!hndl)
	{
		InitializeDatabase();
		return;
	}
	
	if(sError[0])
	{
		LogError("SQL_CheckPlayer: %s", sError);
		return;
	}
	
	int iClient, iTarget;
	
	if(hCheckData)
	{
		iClient = GetClientOfUserId(ReadPackCell(hCheckData));
		iTarget = GetClientOfUserId(ReadPackCell(hCheckData));
		CloseHandle(hCheckData); 
	}
	
	if (!SQL_GetRowCount(hndl))
	{
		PrintToChat(iClient, "\x03[WarnSystem] \x01%t", "warn_notwarned", iTarget);
		return;
	}
	
	PrintToChat(iClient, "\x03[WarnSystem] \x01Check console for output");
	
	int iWarnings = SQL_GetRowCount(hndl);
	char sNickname[32], sAdmin[32], sReason[32], sDate[32], sExpired[16];
	PrintToConsole(iClient, "");
	PrintToConsole(iClient, "");
	PrintToConsole(iClient, "[WarnSystem] %t", "warn_consoleoutput", iTarget, iWarnings);
	PrintToConsole(iClient, "%-15s %-16s %-22s %-33s %-3s", "Player", "Admin", "Date", "Reason", "Expired");
	PrintToConsole(iClient, "----------------------------------------------------------------------------------------------------");
	
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 1, sNickname, sizeof(sNickname));
		SQL_FetchString(hndl, 3, sAdmin, sizeof(sAdmin));
		SQL_FetchString(hndl, 5, sReason, sizeof(sReason));
		SQL_FetchString(hndl, 6, sDate, sizeof(sDate));
		SQL_FetchString(hndl, 7, sExpired, sizeof(sExpired));
		
		if(!strcmp(sExpired, "0", false))
			FormatEx(sExpired, sizeof(sExpired), "No");
		else
			FormatEx(sExpired, sizeof(sExpired), "Yes");
		
		int iBuffer = StringToInt(sDate);
		FormatTime(sDate, sizeof(sDate), "%Y-%m-%d %X", iBuffer);
		
		PrintToConsole(iClient, "%-15s %-16s %-22s %-33s %-3s", sNickname, sAdmin, sDate, sReason, sExpired);
	}
}