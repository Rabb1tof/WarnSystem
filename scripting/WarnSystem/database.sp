int g_iServerID = 0;

char g_sSQL_CreateTable_SQLite[] = "CREATE TABLE IF NOT EXISTS `WarnSystem` (`id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, `serverid` INTEGER(12) NOT NULL default 0, `client` VARCHAR(128) NOT NULL default '', `clientid` INTEGER(32) NOT NULL default '0', `admin` VARCHAR(128) NOT NULL default '', `adminid` INTEGER(32) NOT NULL default '0', `reason` VARCHAR(64) NOT NULL default '', `time` INTEGER(32) NOT NULL default 0, `expired` INTEGER(1) NOT NULL default 0);",
	g_sSQL_CreateTable_MySQL[] = "CREATE TABLE IF NOT EXISTS `WarnSystem` (`id` int(12) NOT NULL AUTO_INCREMENT, `serverid` int(12) NOT NULL default 0, `client` VARCHAR(128) NOT NULL default '', `clientid` int(64) NOT NULL default '0', `admin` VARCHAR(128) NOT NULL default '', `adminid` int(64) NOT NULL default '0', `reason` VARCHAR(64) NOT NULL default '', `time` int(12) NOT NULL default 0, `expired` int(1) NOT NULL default 0, PRIMARY KEY (id)) CHARSET=utf8 COLLATE utf8_general_ci;",
	g_sSQL_CreateTableServers[] = "CREATE TABLE IF NOT EXISTS `WarnSystem_Servers` (`sid` int(12) NOT NULL AUTO_INCREMENT, `address` VARCHAR(64) NOT NULL default '', PRIMARY KEY (sid)) CHARSET=utf8 COLLATE utf8_general_ci;",
	g_sSQL_GetServerID[] = "SELECT `sid` FROM `WarnSystem_Servers` WHERE `address` = '%s';",
	g_sSQL_SetServerID[] = "INSERT INTO `WarnSystem_Servers` (`address`) VALUES ('%s');",
	g_sSQL_WarnPlayer[] = "INSERT INTO `WarnSystem` (`serverid`, `client`, `clientid`, `admin`, `adminid`, `reason`, `time`) VALUES ('%i', '%s', '%i', '%s', '%i', '%s', '%i');",
	g_sSQL_DeleteWarns[] = "DELETE FROM `WarnSystem` WHERE `clientid` = '%i' AND `serverid` = '%i';",
	g_sSQL_SetExpired[] = "UPDATE `WarnSystem` SET `expired` = '1' WHERE `clientid` = '%i' AND `serverid` = '%i';",
	g_sSQL_SelectWarns[] = "SELECT `id` FROM `WarnSystem` WHERE `clientid` = '%i' AND `serverid` = '%i' AND `expired` = '0' ORDER BY `id` DESC LIMIT 1;",
	g_sSQL_UnwarnPlayer[] = "DELETE FROM `WarnSystem` WHERE `id` = '%i' AND `serverid` = '%i';",
	g_sSQL_CheckPlayerWarns[] = "SELECT `client`,`admin`,`reason`,`time`,`expired` FROM `WarnSystem` WHERE `clientid` = '%i' AND `serverid` = '%i';",
	g_sClientIP[MAXPLAYERS+1][32],
	g_sAddress[24];
	
int g_iAccountID[MAXPLAYERS+1];

//----------------------------------------------------DATABASE INITILIZING---------------------------------------------------

public void InitializeDatabase() {SQL_TConnect(SQL_DBConnect, "warnsystem");}
public void SQL_DBConnect(Handle owner, Handle hndl, const char[] sError, any data)
{
	char sSQLiteError[128];
	if(!hndl)
	{
		g_hDatabase = SQLite_UseDatabase("warnsystem", sSQLiteError, 256);
		if(!g_hDatabase)
			SetFailState("[WarnSystem] Could not connect to the database (%s)", sError);
	} else g_hDatabase = view_as<Database>(hndl);

	Handle hDatabaseDriver = view_as<Handle>(g_hDatabase.Driver);
	
	SQL_LockDatabase(g_hDatabase);
	if (hDatabaseDriver == SQL_GetDriver("sqlite"))
	{
		g_hDatabase.Query(SQL_CheckError, g_sSQL_CreateTable_SQLite);
		SQL_UnlockDatabase(g_hDatabase);
	} else
		if (hDatabaseDriver == SQL_GetDriver("mysql"))
		{
			g_iServerID = -1;
			g_hDatabase.SetCharset("utf8");
			g_hDatabase.Query(SQL_CheckError, g_sSQL_CreateTable_MySQL);
			
			int array[24];
			array[0] = GetConVarInt(FindConVar("hostip"));
			FormatEx(g_sAddress, sizeof(g_sAddress), "%d.%d.%d.%d:%d", g_sAddress[3] + 0, g_sAddress[2] + 0, g_sAddress[1] + 0, g_sAddress[0] + 0, GetConVarInt(FindConVar("hostport")));
			
			g_hDatabase.Query(SQL_CreateTableServers, g_sSQL_CreateTableServers);
			SQL_UnlockDatabase(g_hDatabase);
		} else {
			SQL_UnlockDatabase(g_hDatabase);
			SetFailState("[WarnSystem] InitializeDatabase - type database is invalid");
		}
	
	if (g_bIsLateLoad)
	{
		for(int iClient = 1; iClient <= MaxClients; ++iClient)
			LoadPlayerData(iClient);
		g_bIsLateLoad = false;
	}
}

public void SQL_CreateTableServers(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, any data)
{
	if (hDatabaseResults == INVALID_HANDLE || sError[0])
		SetFailState("[WarnSystem] SQL_CreateTableServers: %s", sError);
	GetServerID();
}

public void GetServerID()
{
	char dbQuery[255];
	FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_GetServerID, g_sAddress);
	g_hDatabase.Query(SQL_SelectServerID, dbQuery);
}

public void SQL_SelectServerID(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, any data)
{
	if (hDatabaseResults == INVALID_HANDLE || sError[0])
	{
		LogWarnings("[WarnSystem] SQL_SelectServerID: %s", sError);
		return;
	}

	if(SQL_FetchRow(hDatabaseResults))
	{
		g_iServerID = SQL_FetchInt(hDatabaseResults, 0);
		return;
	}
	
	char dbQuery[255];
	FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_SetServerID, g_sAddress);
	g_hDatabase.Query(SQL_SetServerID, dbQuery);
}

public void SQL_SetServerID(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, any data)
{
	if (hDatabaseResults == INVALID_HANDLE || sError[0])
	{
		LogWarnings("[WarnSystem] SQL_SetServerID: %s", sError);
		return;
	}

	if(SQL_GetAffectedRows(hDatabaseResults))
		g_iServerID = SQL_GetInsertId(g_hDatabase);
}

//----------------------------------------------------LOAD PLAYER DATA---------------------------------------------------

public void LoadPlayerData(int iClient)
{
	if(!g_hDatabase) return;
	
	if(iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		char dbQuery[255];
		g_iAccountID[iClient] = GetSteamAccountID(iClient);
		GetClientIP(iClient, g_sClientIP[iClient], 32);
		FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_SelectWarns, g_iAccountID[iClient], g_iServerID);
		g_hDatabase.Query(SQL_LoadPlayerData, dbQuery, iClient);
	}
}

public void SQL_LoadPlayerData(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, int iClient)
{
	if (hDatabaseResults == INVALID_HANDLE || sError[0])
	{
		LogWarnings("[WarnSystem] SQL_LoadDataPlayer - error while working with data (%s)", sError);
		return;
	}
	
	if (hDatabaseResults.HasResults)
	{
		g_iWarnings[iClient] = hDatabaseResults.RowCount;
		if (g_bPrintToAdmins && !g_bIsLateLoad)
			PrintToAdmins(" %t %t", "WS_Prefix", "WS_PlayerWarns", iClient, g_iWarnings[iClient]);
	} else 
		g_iWarnings[iClient] = 0;
	
	WarnSystem_OnClientLoaded(iClient);
}

//----------------------------------------------------WARN PLAYER---------------------------------------------------

public void WarnPlayer(int iAdmin, int iClient, char sReason[64])
{
	if (0<iClient<=MaxClients && IsClientInGame(iClient) && !IsFakeClient(iClient) && -1<iAdmin<=MaxClients)
	{
		char sEscapedAdminName[MAX_NAME_LENGTH], sEscapedClientName[MAX_NAME_LENGTH], sEscapedReason[64], 
				dbQuery[255], TempNick[MAX_NAME_LENGTH];
		int iTime = GetTime();
		
		GetClientName(iAdmin, TempNick, sizeof(TempNick));
		SQL_EscapeString(g_hDatabase, TempNick, sEscapedAdminName, sizeof(sEscapedAdminName));
		GetClientName(iClient, TempNick, sizeof(TempNick));
		SQL_EscapeString(g_hDatabase, TempNick, sEscapedClientName, sizeof(sEscapedClientName));
		SQL_EscapeString(g_hDatabase, sReason, sEscapedReason, sizeof(sEscapedReason));
		
		++g_iWarnings[iClient];
		FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_WarnPlayer, g_iServerID, sEscapedClientName, g_iAccountID[iClient], sEscapedAdminName, g_iAccountID[iAdmin], sEscapedReason, iTime);
		g_hDatabase.Query(SQL_CheckError, dbQuery);
		
		if(g_bWarnSound)
			if (g_bIsFuckingGame)
			{
				char sBuffer[PLATFORM_MAX_PATH];
				FormatEx(sBuffer, sizeof(sBuffer), "*/%s", g_sWarnSoundPath);
				EmitSoundToClient(iClient, sBuffer);
			} else
				EmitSoundToClient(iClient, g_sWarnSoundPath);
	
		CPrintToChatAll(" %t %t", "WS_Prefix", "WS_WarnPlayer", iAdmin, iClient, sReason);
		if(g_bLogWarnings)
			LogWarnings(" %t %t", "WS_Prefix", "WS_LogWarn", iAdmin, g_iAccountID[iAdmin], g_sClientIP[iAdmin], iClient, g_iAccountID[iClient], g_sClientIP[iClient], sReason);
		
		WarnSystem_OnClientWarn(iAdmin, iClient, sReason);
		
		//We don't need to fuck db because we cached warns.
		if (g_iWarnings[iClient] >= g_iMaxWarns)
		{
			if(g_bResetWarnings)
				FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_DeleteWarns, g_iAccountID[iClient], g_iServerID);
				else
				FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_SetExpired, g_iAccountID[iClient], g_iServerID);
			g_hDatabase.Query(SQL_CheckError, dbQuery);
			PunishPlayerOnMaxWarns(iAdmin, iClient, sReason);
		} else
			PunishPlayer(iAdmin, iClient, sReason);
	}
}

//----------------------------------------------------UNWARN PLAYER---------------------------------------------------

public void UnWarnPlayer(int iAdmin, int iClient, char sReason[64])
{
	if (0<iClient<=MaxClients && IsClientInGame(iClient) && !IsFakeClient(iClient) && -1<iAdmin<=MaxClients)
	{
		char dbQuery[255];
		FormatEx(dbQuery, sizeof(dbQuery),  g_sSQL_SelectWarns, g_iAccountID[iClient], g_iServerID);
		
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
	if (hDatabaseResults == INVALID_HANDLE || sError[0])
	{
		LogWarnings("[WarnSystem] SQL_UnWarnPlayer - error while working with data (%s)", sError);
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
		
		--g_iWarnings[iClient];
		FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_UnwarnPlayer, iID, g_iServerID);
		g_hDatabase.Query(SQL_CheckError, dbQuery);
		
		CPrintToChatAll(" %t %t", "WS_Prefix", "WS_UnWarnPlayer", iAdmin, iClient, sReason);
		if(g_bLogWarnings)
			LogWarnings(" %t %t", "WS_Prefix", "WS_LogUnWarn", iAdmin, g_iAccountID[iAdmin], g_sClientIP[iAdmin], iClient, g_iAccountID[iClient], g_sClientIP[iClient], sReason);
		
		WarnSystem_OnClientUnWarn(iAdmin, iClient, sReason);
	} else
		CPrintToChat(iAdmin, " %t %t", "WS_Prefix", "WS_NotWarned", iClient);
}

//----------------------------------------------------RESET WARNS---------------------------------------------------

public void ResetPlayerWarns(int iAdmin, int iClient, char sReason[64])
{
	if (0<iClient<=MaxClients && IsClientInGame(iClient) && !IsFakeClient(iClient) && -1<iAdmin<=MaxClients)
	{
		char dbQuery[255];
		FormatEx(dbQuery, sizeof(dbQuery),  g_sSQL_SelectWarns, g_iAccountID[iClient], g_iServerID);
		
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
	if (hDatabaseResults == INVALID_HANDLE || sError[0])
	{
		LogWarnings("[WarnSystem] SQL_ResetWarnPlayer - error while working with data (%s)", sError);
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
	
	if (hDatabaseResults.HasResults)
	{
		g_iWarnings[iClient] = 0;
		FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_DeleteWarns, g_iAccountID[iClient], g_iServerID);
		g_hDatabase.Query(SQL_CheckError, dbQuery);
		//Delete data. Or make it expired?
		
		CPrintToChat(iAdmin, " %t %t", "WS_Prefix", "WS_ResetPlayer", iAdmin, iClient, sReason);
		WarnSystem_OnClientResetWarns(iAdmin, iClient, sReason);
		if(g_bLogWarnings)
			LogWarnings(" %t %t", "WS_Prefix", "WS_LogResetWarn", iAdmin, g_iAccountID[iAdmin], g_sClientIP[iAdmin], iClient, g_iAccountID[iClient], g_sClientIP[iClient], sReason);
	} else
		CPrintToChat(iAdmin, " %t %t", "WS_Prefix", "WS_NotWarned", iClient);
}

//----------------------------------------------------CHECK PLAYER WARNS---------------------------------------------------

public void CheckPlayerWarns(int iAdmin, int iClient)
{
	if (0<iClient<=MaxClients && IsClientInGame(iClient) && !IsFakeClient(iClient) && -1<iAdmin<=MaxClients)
	{
		char dbQuery[255];
		FormatEx(dbQuery, sizeof(dbQuery),  g_sSQL_CheckPlayerWarns, g_iAccountID[iClient], g_iServerID);
		
		Handle hCheckData = CreateDataPack(); 
		WritePackCell(hCheckData, GetClientUserId(iAdmin));
		WritePackCell(hCheckData, GetClientUserId(iClient));
		ResetPack(hCheckData);
		
		g_hDatabase.Query(SQL_CheckPlayerWarns, dbQuery, hCheckData);
		//mb print only count of warns?
	}
}

public void SQL_CheckPlayerWarns(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, Handle hCheckData)
{
	if (hDatabaseResults == INVALID_HANDLE || sError[0])
	{
		LogWarnings("[WarnSystem] SQL_CheckPlayerWarns - error while working with data (%s)", sError);
		return;
	}
	
	int iAdmin, iClient;
	
	if(hCheckData)
	{
		iAdmin = GetClientOfUserId(ReadPackCell(hCheckData));
		iClient = GetClientOfUserId(ReadPackCell(hCheckData));
		CloseHandle(hCheckData); 
	} else return;
	
	if (!hDatabaseResults.RowCount)
	{
		CPrintToChat(iAdmin, " %t %t", "WS_Prefix", "WS_NotWarned", iClient);
		return;
	}
	
	CPrintToChat(iAdmin, " %t %t", "WS_Prefix", "WS_Console", iClient, g_iWarnings[iClient]);
	CPrintToChat(iAdmin, " %t %t", "WS_Prefix", "See console for output");
	
	char sClient[64], sAdmin[64], sReason[64], sTimeFormat[32];
	int iDate, iExpired, i;
	for (i = 0; i < 2; ++i) PrintToConsole(iAdmin, " ");
	PrintToConsole(iAdmin, "%-18s %-18s %-20s %-26s %-1s", "Player", "Admin", "Date", "Reason", "Expired");
	PrintToConsole(iAdmin, "-----------------------------------------------------------------------------------------------------------");
	//Ya, nice output
	
	while (hDatabaseResults.FetchRow())
	{
		SQL_FetchString(hDatabaseResults, 0, sClient, sizeof(sClient));
		SQL_FetchString(hDatabaseResults, 1, sAdmin, sizeof(sAdmin));
		SQL_FetchString(hDatabaseResults, 2, sReason, sizeof(sReason));
		iDate = hDatabaseResults.FetchInt(3);
		iExpired = hDatabaseResults.FetchInt(4);
		
		FormatTime(sTimeFormat, sizeof(sTimeFormat), "%Y-%m-%d %X", iDate);
		PrintToConsole(iAdmin, "%-18s %-18s %-20s %-26s %-1i", sClient, sAdmin, sTimeFormat, sReason, iExpired);
	}
	PrintToConsole(iAdmin, "-----------------------------------------------------------------------------------------------------------");
	for (i = 0; i < 2; ++i) PrintToConsole(iAdmin, " ");
}

public void SQL_CheckError(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, any data)
{
	if (hDatabaseResults == INVALID_HANDLE || sError[0])
		LogWarnings("[WarnSystem] SQL_CheckError: %s", sError);
}