Database g_hDatabase;

char g_sSQL_CreateTable_SQLite[] = "CREATE TABLE IF NOT EXISTS WarnSystem (id INTEGER(12) NOT NULL PRIMARY KEY AUTOINCREMENT, client VARCHAR(128) NOT NULL default '', clientid VARCHAR(32) NOT NULL default '', admin VARCHAR(128) NOT NULL default '', adminid VARCHAR(32) NOT NULL default '', reason VARCHAR(64) NOT NULL default '', time INTEGER(12) NOT NULL default 0, expired INTEGER(1) NOT NULL default 0);",
	g_sSQL_CreateTable_MySQL[] = "CREATE TABLE IF NOT EXISTS WarnSystem (id int(12) NOT NULL AUTO_INCREMENT, client VARCHAR(128) NOT NULL default '', clientid VARCHAR(32) NOT NULL default '', admin VARCHAR(128) NOT NULL default '', adminid VARCHAR(32) NOT NULL default '', reason VARCHAR(64) NOT NULL default '', time int(12) NOT NULL default 0, expired int(1) NOT NULL default 0, PRIMARY KEY (id)) CHARSET=utf8 COLLATE utf8_general_ci;",
	g_sSQL_LoadPlayerData[] = "SELECT * FROM WarnSystem WHERE clientid='%s' AND expired = '0';",
	g_sSQL_WarnPlayer[] = "INSERT INTO WarnSystem (client, clientid, admin, adminid, reason, time) VALUES ('%s', '%s', '%s', '%s', '%s', '%i');",
	g_sSQL_DeleteWarns[] = "DELETE FROM WarnSystem WHERE clientid = '%s';",
	g_sSQL_SetExpired[] = "UPDATE WarnSystem SET expired = '1' WHERE clientid = '%s';",
	g_sSQL_SelectWarns[] = "SELECT * FROM WarnSystem WHERE clientid='%s' AND expired = '0' ORDER BY id DESC LIMIT 1;",
	g_sSQL_UnwarnPlayer[] = "DELETE FROM WarnSystem WHERE id = '%i';",
	g_sSQL_CheckPlayerWarns[] = "SELECT * FROM WarnSystem WHERE clientid='%s';",
	g_sClientName[MAXPLAYERS+1][MAX_NAME_LENGTH],
	g_sSteamID[MAXPLAYERS+1][32],
	g_sClientIP[MAXPLAYERS+1][32];
	
int g_iWarnings[MAXPLAYERS+1];

public void InitializeDatabase()
{
	char sError[256];
	g_hDatabase = SQL_Connect("warnsystem", false, sError, 256);
	if(!g_hDatabase)
	{
		g_hDatabase = SQLite_UseDatabase("warnsystem", sError, 256);
		if(!g_hDatabase)
			SetFailState("[WarnSystem] Could not connect to the database (%s)", sError);
	}

	Handle hDatabaseDriver = view_as<Handle>(g_hDatabase.Driver);
	
	if (hDatabaseDriver == SQL_GetDriver("sqlite"))
		g_hDatabase.Query(SQL_CreateTable, g_sSQL_CreateTable_SQLite);
	else if (hDatabaseDriver == SQL_GetDriver("mysql"))
		{
			g_hDatabase.Query(SQL_CreateTable, g_sSQL_CreateTable_MySQL);
			g_hDatabase.SetCharset("utf8");
		} else 
			SetFailState("[WarnSystem] InitializeDatabase - type database is invalid");
	
	for(int iClient = 1; iClient <= MaxClients; ++iClient)
		LoadPlayerData(iClient);
}

public void SQL_CheckError(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, any data)
{
	if(sError[0])
		LogError("SQL_CheckError: %s", sError);
}

public void SQL_CreateTable(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, any data)
{
	if(sError[0])
		SetFailState("SQL_CreateTable: %s", sError);
}

public void LoadPlayerData(int iClient)
{
	if(!g_hDatabase) return;
	
	if(iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		char dbQuery[128];
		GetClientAuthId(iClient, AuthId_Steam2, g_sSteamID[iClient], 32);
		GetClientName(iClient, g_sClientName[iClient], MAX_NAME_LENGTH);
		GetClientIP(iClient, g_sClientIP[iClient], 32);
		FormatEx(dbQuery, sizeof(dbQuery),  g_sSQL_LoadPlayerData, 32);
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
		g_iWarnings[iClient] = SQL_GetRowCount(hDatabaseResults);
		if (g_bPrintToAdmins)
			PrintToAdmins("\x03[WarnSystem] \x01%t", "WarnConnect", iClient, g_iWarnings);
	}
}

public void WarnPlayer(int iAdmin, int iClient, char sReason[64])
{
	if (iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		char dbQuery[255];
		
		Handle hWarnData = CreateDataPack();
		if (iAdmin)
			WritePackCell(hWarnData, GetClientUserId(iAdmin));
		else
			WritePackCell(hWarnData, 0);
		WritePackCell(hWarnData, GetClientUserId(iClient));
		WritePackString(hWarnData, sReason);
		ResetPack(hWarnData);
		
		FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_LoadPlayerData, g_sSteamID[iClient]);
		g_hDatabase.Query(SQL_WarnPlayer, dbQuery, hWarnData);
		
		PrintToChatAll("\x03[WarnSystem] \x01%t", "warn_warnplayer", iAdmin, iClient, sReason);
		
		if(g_bWarnSound)
			EmitSoundToClient(iClient, g_sWarnSoundPath);
		
		Fwd_OnClientWarn(iAdmin, iClient, sReason);
	}
}

public void SQL_WarnPlayer(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, Handle hWarnData)
{
	if (!hDatabaseResults)
	{
		LogError("[WarnSystem] SQL_WarnPlayer - error while working with data (%s)", sError);
		return;
	}
	
	int iAdmin, iClient, iTime;
	iTime = GetTime();
	char sReason[64], sEscapedClientNick[64], sEscapedTargetNick[64], sEscapedReason[64], dbQuery[255];
	
	if(hWarnData)
	{
		iAdmin = GetClientOfUserId(ReadPackCell(hWarnData));
		iClient = GetClientOfUserId(ReadPackCell(hWarnData));
		ReadPackString(hWarnData, sReason, sizeof(sReason));
		CloseHandle(hWarnData);
	} else return;
	
	SQL_EscapeString(g_hDatabase, g_sClientName[iClient], sEscapedTargetNick, sizeof(sEscapedTargetNick));
	SQL_EscapeString(g_hDatabase, sReason, sEscapedReason, sizeof(sEscapedReason));
	
	++g_iWarnings[iClient];
	FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_WarnPlayer, sEscapedTargetNick, g_sSteamID[iClient], sEscapedClientNick, g_sSteamID[iAdmin], sEscapedReason, iTime);
	g_hDatabase.Query(SQL_CheckError, dbQuery);
	
	if (hDatabaseResults.FetchRow())
	{
		if (g_iWarnings[iClient] >= g_iMaxWarns)
		{
			if(g_bResetWarnings)
				FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_DeleteWarns, g_sSteamID[iClient]);
			else
				FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_SetExpired, g_sSteamID[iClient]);
			g_hDatabase.Query(SQL_CheckError, dbQuery);
			
			if(g_bLogWarnings)
				LogWarnings("[WarnSystem] %t", "warn_warn_log", iAdmin, g_sSteamID[iAdmin], g_sClientIP[iAdmin], iClient, g_sSteamID[iClient], g_sClientIP[iClient], sReason);
			
			PunishPlayerOnMaxWarns(iClient, sReason);
		}
	}
	
	PunishPlayer(iAdmin, iClient, sReason);
}

public void UnWarnPlayer(int iAdmin, int iClient, char sReason[64])
{
	if (iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		char dbQuery[255];
		FormatEx(dbQuery, sizeof(dbQuery),  g_sSQL_SelectWarns, g_sSteamID[iClient]);
		
		Handle hUnwarnData = CreateDataPack();
		if (iAdmin)
			WritePackCell(hUnwarnData, GetClientUserId(iAdmin));
		else
			WritePackCell(hUnwarnData, 0);
		WritePackCell(hUnwarnData, GetClientUserId(iClient));
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
	int iAdmin, iClient;
	
	if(hUnwarnData)
	{
		iAdmin = GetClientOfUserId(ReadPackCell(hUnwarnData));
		iClient = GetClientOfUserId(ReadPackCell(hUnwarnData));
		ReadPackString(hUnwarnData, sReason, sizeof(sReason));
		CloseHandle(hUnwarnData);
	} else return;
	
	if (hDatabaseResults.FetchRow())
	{
		int iID;
		iID = hDatabaseResults.FetchInt(0);
		
		FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_UnwarnPlayer, iID);
		g_hDatabase.Query(SQL_CheckError, dbQuery);
		PrintToChatAll("\x03[WarnSystem] \x01%t", "warn_unwarn_player", iAdmin, iClient, sReason);
		
		if(g_bLogWarnings)
			LogWarnings("[WarnSystem] %t", "warn_unwarn_log", iAdmin, g_sSteamID[iAdmin], g_sClientIP[iAdmin], iClient, g_sSteamID[iClient], g_sClientIP[iClient], sReason);
	} else
		PrintToChat(iAdmin, "\x03[WarnSystem] \x01%t", "warn_notwarned", iClient);
}

public void ResetPlayerWarns(int iAdmin, int iClient, char sReason[64])
{
	if (iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		char dbQuery[255];
		FormatEx(dbQuery, sizeof(dbQuery),  g_sSQL_SelectWarns, g_sSteamID[iClient]);
		
		Handle hResetWarnData = CreateDataPack();
		
		if (iAdmin)
			WritePackCell(hResetWarnData, GetClientUserId(iAdmin));
		else
			WritePackCell(hResetWarnData, 0);
		WritePackCell(hResetWarnData, GetClientUserId(iClient));
		WritePackString(hResetWarnData, sReason);
		ResetPack(hResetWarnData);
		
		g_hDatabase.Query(SQL_ResetWarnPlayer, dbQuery, hResetWarnData);
	}
	
}

public void SQL_ResetWarnPlayer(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, Handle hResetWarnData)
{	
	if (!hDatabaseResults)
	{
		LogError("[WarnSystem] SQL_ResetWarnPlayer - error while working with data (%s)", sError);
		return;
	}

	char sReason[64], dbQuery[255];
	int iAdmin, iClient;
	
	if(hResetWarnData)
	{
		iAdmin = GetClientOfUserId(ReadPackCell(hResetWarnData));
		iClient = GetClientOfUserId(ReadPackCell(hResetWarnData));
		ReadPackString(hResetWarnData, sReason, sizeof(sReason));
		CloseHandle(hResetWarnData); 
	} else return;
	
	if (hDatabaseResults.FetchRow())
	{
		FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_DeleteWarns, g_sSteamID[iClient]);
		g_hDatabase.Query(SQL_CheckError, dbQuery);
		
		PrintToChat(iAdmin, "\x03[WarnSystem] \x01", "%t", "warn_resetplayer", iClient, sReason);
		
		if(g_bLogWarnings)
			LogWarnings("[WarnSystem] %t", "warn_resetwarn_log", iAdmin, g_sSteamID[iAdmin], g_sClientIP[iAdmin], iClient, g_sSteamID[iClient], g_sClientIP[iClient], sReason);
	} else
		PrintToChat(iAdmin, "\x03[WarnSystem] \x01%t", "warn_notwarned", iClient);
}

public void CheckPlayerWarns(int iAdmin, int iClient){
	if (iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		char dbQuery[255];
		FormatEx(dbQuery, sizeof(dbQuery),  g_sSQL_CheckPlayerWarns, g_sSteamID[iClient]);
		
		Handle hCheckData = CreateDataPack(); 
		WritePackCell(hCheckData, GetClientUserId(iAdmin));
		WritePackCell(hCheckData, GetClientUserId(iClient));
		ResetPack(hCheckData);
		
		g_hDatabase.Query(SQL_CheckPlayerWarns, dbQuery, hCheckData);
	}
}

public void SQL_CheckPlayerWarns(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, Handle hCheckData)
{
	if (!hDatabaseResults)
	{
		LogError("[WarnSystem] SQL_CheckPlayerWarns - error while working with data (%s)", sError);
		return;
	}
	
	int iAdmin, iClient;
	
	if(hCheckData)
	{
		iAdmin = GetClientOfUserId(ReadPackCell(hCheckData));
		iClient = GetClientOfUserId(ReadPackCell(hCheckData));
		CloseHandle(hCheckData); 
	} else return;
	
	if (hDatabaseResults.FetchRow())
	{
		PrintToChat(iAdmin, "\x03[WarnSystem] \x01%t", "warn_notwarned", iClient);
		return;
	}
	
	PrintToChat(iAdmin, "\x03[WarnSystem] \x01%t", "Check console for output");
	
	char sClient[64], sAdmin[64], sReason[64], sTimeFormat[32];
	int iDate, iExpired;
	PrintToConsole(iAdmin, "");
	PrintToConsole(iAdmin, "");
	PrintToConsole(iAdmin, "[WarnSystem] %t", "warn_consoleoutput", iClient, g_iWarnings[iClient]);
	PrintToConsole(iAdmin, "%-15s %-16s %-22s %-33s %-3i", "Player", "Admin", "Date", "Reason", "Expired");
	PrintToConsole(iAdmin, "----------------------------------------------------------------------------------------------------");
	
	while (hDatabaseResults.FetchRow())
	{
		SQL_FetchString(hDatabaseResults, 1, sClient, sizeof(sClient));
		SQL_FetchString(hDatabaseResults, 3, sAdmin, sizeof(sAdmin));
		SQL_FetchString(hDatabaseResults, 5, sReason, sizeof(sReason));
		iDate = hDatabaseResults.FetchInt(6);
		iExpired = hDatabaseResults.FetchInt(7);
		
		FormatTime(sTimeFormat, sizeof(sTimeFormat), "%Y-%m-%d %X", iDate);
		
		PrintToConsole(iAdmin, "%-15s %-16s %-22s %-33s %-3i", sClient, sAdmin, sTimeFormat, sReason, iExpired);
	}
}