int g_iServerID = 0;

char g_sSQL_CreateTablePlayers_SQLite[] = "CREATE TABLE IF NOT EXISTS `ws_player` (`account_id` int(12) NOT NULL AUTO_INCREMENT COMMENT 'Steam AccountID', `username` VARCHAR(128) NOT NULL default '', `warns` INTEGER(10) unsigned NOT NULL DEFAULT '0', PRIMARY KEY (account_id)) COMMENT = 'Перечень всех игроков';",
	g_sSQL_CreateTablePlayers_MySQL[] = "CREATE TABLE IF NOT EXISTS `ws_player` (`account_id` int(12) NOT NULL AUTO_INCREMENT COMMENT 'Steam AccountID', `username` VARCHAR(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL default '', `warns` INTEGER(10) unsigned NOT NULL DEFAULT '0', PRIMARY KEY (account_id)) CHARSET=utf8 COLLATE utf8_general_ci COMMENT = 'Перечень всех игроков';",
    g_sSQL_CreateTableWarns_MySQL[] = "CREATE TABLE IF NOT EXISTS `ws_warn` (`warn_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Уникальный идентификатор предупреждения', `admin_id` int(10) unsigned NOT NULL COMMENT 'Идентификатор игрока-администратора, выдавшего предупреждение', `client_id` int(10) unsigned NOT NULL COMMENT 'Идентификатор игрока, который получил предупреждение', `server_id` smallint(6) unsigned NOT NULL COMMENT 'Идентификатор сервера', `reason` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Причина', `created_at` int(10) unsigned NOT NULL COMMENT 'TIMESTAMP, когда был создан', `expires_at` int(10) unsigned NOT NULL COMMENT 'TIMESTAMP, когда истекает, или 0, если бессрочно', PRIMARY KEY (`warn_id`), KEY `FK_ws_warn_ws_server` (`server_id`), KEY `FK_ws_warn_ws_admin` (`admin_id`), KEY `FK_ws_warn_ws_client` (`client_id`), CONSTRAINT `FK_ws_warn_ws_admin` FOREIGN KEY (`admin_id`) REFERENCES `ws_player` (`account_id`) ON DELETE CASCADE ON UPDATE CASCADE, CONSTRAINT `FK_ws_warn_ws_client` FOREIGN KEY (`client_id`) REFERENCES `ws_player` (`account_id`) ON DELETE CASCADE ON UPDATE CASCADE, CONSTRAINT `FK_ws_warn_ws_server` FOREIGN KEY (`server_id`) REFERENCES `ws_server` (`server_id`) ON DELETE CASCADE ON UPDATE CASCADE) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Все выданные когда-либо предупреждения';",
    g_sSQL_CreateTableWarns_SQLite[] = "CREATE TABLE IF NOT EXISTS `ws_warn` (`warn_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Уникальный идентификатор предупреждения', `admin_id` int(10) unsigned NOT NULL COMMENT 'Идентификатор игрока-администратора, выдавшего предупреждение', `client_id` int(10) unsigned NOT NULL COMMENT 'Идентификатор игрока, который получил предупреждение', `server_id` smallint(6) unsigned NOT NULL COMMENT 'Идентификатор сервера', `reason` varchar(256) NOT NULL COMMENT 'Причина', `created_at` int(10) unsigned NOT NULL COMMENT 'TIMESTAMP, когда был создан', `expires_at` int(10) unsigned NOT NULL COMMENT 'TIMESTAMP, когда истекает, или 0, если бессрочно', PRIMARY KEY (`warn_id`), KEY `FK_ws_warn_ws_server` (`server_id`), KEY `FK_ws_warn_ws_admin` (`admin_id`), KEY `FK_ws_warn_ws_client` (`client_id`), CONSTRAINT `FK_ws_warn_ws_admin` FOREIGN KEY (`admin_id`) REFERENCES `ws_player` (`account_id`) ON DELETE CASCADE ON UPDATE CASCADE, CONSTRAINT `FK_ws_warn_ws_client` FOREIGN KEY (`client_id`) REFERENCES `ws_player` (`account_id`) ON DELETE CASCADE ON UPDATE CASCADE,CONSTRAINT `FK_ws_warn_ws_server` FOREIGN KEY (`server_id`) REFERENCES `ws_server` (`server_id`) ON DELETE CASCADE ON UPDATE CASCADE) COMMENT='Все выданные когда-либо предупреждения';",
	g_sSQL_CreateTableServers[] = "CREATE TABLE IF NOT EXISTS `ws_server` (`server_id` int(12) NOT NULL AUTO_INCREMENT, `address` VARCHAR(32) NOT NULL default '', `port` INTEGER(5) NOT NULL default '', PRIMARY KEY (server_id) UNIQUE KEY `ws_servers_address_port` (`address`,`port`)) CHARSET=utf8 COLLATE utf8_general_ci;",
	g_sSQL_GetServerID[] = "SELECT `server_id` FROM `ws_server` WHERE `address` = '%s' AND `port` = '%s';",
	g_sSQL_SetServerID[] = "INSERT INTO `ws_server` (`address`, `port`) VALUES ('%s', '%i');",
	g_sSQL_WarnPlayer[] = "INSERT INTO `ws_warn` (`server_id`, `client_id`, `admin_id`, `reason`, `time`, `expires_at`) VALUES ('%i', '%i', '%i', '%s', '%i', '%i');",
	g_sSQL_DeleteWarns[] = "DELETE FROM `ws_warn` WHERE `client_id` = '%i';",
	g_sSQL_DeleteExpired[] = "DELETE FROM `ws_warn` WHERE `expires_at` < UNIX_TIMESTAMP ;",
	g_sSQL_SelectWarns[] = "SELECT `ws_warn`.`warn_id` FROM `ws_warn` INNER JOIN `ws_player` ON `ws_player`.`client_id` = '%i' INNER JOIN `ws_server` ON `ws_server`.`server_id` = '%i';",
	g_sSQL_UnwarnPlayer[] = "DELETE FROM `ws_warn` WHERE `warn_id` = '%i';",
	g_sSQL_CheckPlayerWarns[] = "SELECT `ws_warn`.`warn_id`, `player`.`account_id` client_id, `admin`.`username` admin_name, `ws_warn`.`created_at` FROM `ws_warn` INNER JOIN `ws_player` AS player ON `ws_warn`.`client_id` = `player`.`account_id`",
	g_sSQL_GetInfoWarn[] = "SELECT `admin`.`account_id` admin_id, `admin`.`username` admin_name, `player`.`account_id` client_id, `player`.`username` client_name, `ws_warn`.`reason` `ws_warn`.`expires_at`, `ws_warn`.`created_at` FROM `ws_warn` INNER JOIN `ws_player` AS admin  ON `ws_warn`.`admin_id` = `admin`.`account_id` INNER JOIN `ws_player` AS player ON `ws_warn`.`client_id` = `player`.`account_id` WHERE `ws_warn`.`warn_id` = '%i';",
	g_sClientIP[MAXPLAYERS+1][65],
	g_sAddress[64];
	
int g_iAccountID[MAXPLAYERS+1];

//----------------------------------------------------DATABASE INITILIZING---------------------------------------------------

public void InitializeDatabase()
{
	char sError[256];
	g_hDatabase = SQL_Connect("warnsystem", false, sError, 256);
	if(!g_hDatabase)
	{
		if (sError[0])
			LogWarnings(sError);
		g_hDatabase = SQLite_UseDatabase("warnsystem", sError, 256);
		if(!g_hDatabase)
			SetFailState("[WarnSystem] Could not connect to the database (%s)", sError);
	}

	Handle hDatabaseDriver = view_as<Handle>(g_hDatabase.Driver);
	if (hDatabaseDriver == SQL_GetDriver("sqlite"))
	{
        //g_hDatabase.SetCharset("utf8");
        SQL_LockDatabase(g_hDatabase);
        g_hDatabase.Query(SQL_CheckError, g_sSQL_CreateTablePlayers_SQLite);
        g_hDatabase.Query(SQL_CheckError, g_sSQL_CreateTableWarns_SQLite);
        SQL_UnlockDatabase(g_hDatabase);
	} else
        if (hDatabaseDriver == SQL_GetDriver("mysql"))
        {
            g_iServerID = -1;
            //STATS_Generic_GetIP(g_sAddress, sizeof(g_sAddress));
            
            g_hDatabase.SetCharset("utf8");
            SQL_LockDatabase(g_hDatabase);
            g_hDatabase.Query(SQL_CheckError, g_sSQL_CreateTablePlayers_MySQL);
            g_hDatabase.Query(SQL_CheckError, g_sSQL_CreateTableWarns_MySQL);
            g_hDatabase.Query(SQL_CreateTableServers, g_sSQL_CreateTableServers);
            SQL_UnlockDatabase(g_hDatabase);
        } else
            SetFailState("[WarnSystem] InitializeDatabase - type database is invalid");
	
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
	char dbQuery[257];
	FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_GetServerID, g_sAddress, g_iPort);
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
	
	char dbQuery[257];
	FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_SetServerID, g_sAddress, g_iPort);
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
	if(IsValidClient(iClient) && g_hDatabase)
	{
		char dbQuery[257];
		g_iAccountID[iClient] = GetSteamAccountID(iClient);
		GetClientIP(iClient, g_sClientIP[iClient], 65);
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
    
    //while (hDatabaseResults.FetchRow())
	
	else if (hDatabaseResults.HasResults)
	{
		g_iWarnings[iClient] = hDatabaseResults.RowCount;
		if (g_bPrintToAdmins && !g_bIsLateLoad)
			PrintToAdmins(" %t %t", "WS_ColoredPrefix", "WS_PlayerWarns", iClient, g_iWarnings[iClient]);
	} else 
		g_iWarnings[iClient] = 0;
	
	WarnSystem_OnClientLoaded(iClient);
}

//----------------------------------------------------WARN PLAYER---------------------------------------------------

public void WarnPlayer(int iAdmin, int iClient, char sReason[129])
{
	if (IsValidClient(iClient) && -1<iAdmin && iAdmin<=MaxClients && WarnSystem_OnClientWarnPre(iAdmin, iClient, sReason) == Plugin_Continue)
	{
		if (iAdmin == iClient)
		{
			CPrintToChat(iAdmin, " %t %t", "WS_ColoredPrefix", "WS_CantTargetYourself");
			return;
		}
		char sEscapedAdminName[128], sEscapedClientName[128], sEscapedReason[129], 
				dbQuery[257], TempNick[128];
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
	
		if (g_bPrintToChat)
			CPrintToChatAll(" %t %t", "WS_ColoredPrefix", "WS_WarnPlayer", iAdmin, iClient, sReason);
		else
		{
			PrintToAdmins(" %t %t", "WS_ColoredPrefix", "WS_WarnPlayer", iAdmin, iClient, sReason);
			CPrintToChat(iClient, " %t %t", "WS_ColoredPrefix", "WS_WarnPlayerPersonal", iAdmin, sReason);
		}
		
		if(g_bLogWarnings)
			LogWarnings("[WarnSystem] ADMIN (NICK: %N | STEAMID32: STEAM_1:%i:%i | IP: %s) issued a warning on PLAYER (NICK: %N | STEAMID32: STEAM_1:%i:%i | IP: %s) with reason: %s", iAdmin, g_iAccountID[iAdmin] & 1, g_iAccountID[iAdmin] / 2, g_sClientIP[iAdmin], iClient, g_iAccountID[iClient] & 1, g_iAccountID[iClient] / 2, g_sClientIP[iClient], sReason);
		
		WarnSystem_OnClientWarn(iAdmin, iClient, sReason);
		
		//We don't need to fuck db because we cached warns.
		if (g_iWarnings[iClient] >= g_iMaxWarns)
		{
            if(g_bResetWarnings)
				FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_DeleteWarns, g_iAccountID[iClient], g_iServerID);
			else
				FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_DeleteExpired, g_iAccountID[iClient], g_iServerID);
            g_hDatabase.Query(SQL_CheckError, dbQuery);
            PunishPlayerOnMaxWarns(iAdmin, iClient, sReason);
		} else
			PunishPlayer(iAdmin, iClient, sReason);
	}
}

//----------------------------------------------------UNWARN PLAYER---------------------------------------------------

public void UnWarnPlayer(int iAdmin, int iClient, char sReason[129])
{
	if (IsValidClient(iClient) && -1<iAdmin && iAdmin<=MaxClients && WarnSystem_OnClientUnWarnPre(iAdmin, iClient, sReason) == Plugin_Continue)
	{
		if (iAdmin == iClient)
		{
			CPrintToChat(iAdmin, " %t %t", "WS_ColoredPrefix", "WS_CantTargetYourself");
			return;
		}
		
		char dbQuery[257];
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
	
	char sReason[129], dbQuery[257];
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
		FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_UnwarnPlayer, iID);
		g_hDatabase.Query(SQL_CheckError, dbQuery);
		
		if (g_bPrintToChat)
			CPrintToChatAll(" %t %t", "WS_ColoredPrefix", "WS_UnWarnPlayer", iAdmin, iClient, sReason);
		else
		{
			PrintToAdmins(" %t %t", "WS_ColoredPrefix", "WS_UnWarnPlayer", iAdmin, iClient, sReason);
			CPrintToChat(iClient, " %t %t", "WS_ColoredPrefix", "WS_UnWarnPlayerPersonal", iAdmin, sReason);
		}
		
		if (g_bLogWarnings)
			LogWarnings("[WarnSystem] ADMIN (NICK: %N | STEAMID32: STEAM_1:%i:%i | IP: %s) removed a warning on PLAYER (NICK: %N | STEAMID32: STEAM_1:%i:%i | IP: %s) with reason: %s", iAdmin, g_iAccountID[iAdmin] & 1, g_iAccountID[iAdmin] / 2, g_sClientIP[iAdmin], iClient, g_iAccountID[iClient] & 1, g_iAccountID[iClient] / 2, g_sClientIP[iClient], sReason);
		
		WarnSystem_OnClientUnWarn(iAdmin, iClient, sReason);
	} else
		CPrintToChat(iAdmin, " %t %t", "WS_ColoredPrefix", "WS_NotWarned", iClient);
}

//----------------------------------------------------RESET WARNS---------------------------------------------------

public void ResetPlayerWarns(int iAdmin, int iClient, char sReason[129])
{
	if (IsValidClient(iClient) && -1<iAdmin && iAdmin<=MaxClients && WarnSystem_OnClientResetWarnsPre(iAdmin, iClient, sReason) == Plugin_Continue)
	{
		if (iAdmin == iClient)
		{
			CPrintToChat(iAdmin, " %t %t", "WS_ColoredPrefix", "WS_CantTargetYourself");
			return;
		}
		char dbQuery[257];
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

//------------------------------------Check for expired warnings------------------------------------------------

void CheckExpiredWarns()
{
    char dbQuery[257];
    FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_DeleteExpired);
    g_hDatabase.Query(SQL_CheckExpiredWarns, dbQuery);
}

public void SQL_CheckExpiredWarns(Database hDatabase, DBResultSet hDatabaseResults, const char[] szError, Handle hResetWarnData)
{
    if (szError[0])
	{
		LogWarnings("[WarnSystem] SQL_CheckExpiredWarns - error while working with data (%s)", szError);
		return;
	}
}

public void SQL_ResetWarnPlayer(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, Handle hResetWarnData)
{	
	if (hDatabaseResults == INVALID_HANDLE || sError[0])
	{
		LogWarnings("[WarnSystem] SQL_ResetWarnPlayer - error while working with data (%s)", sError);
		return;
	}

	char sReason[129], dbQuery[257];
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
		
		if (g_bPrintToChat)
			CPrintToChatAll(" %t %t", "WS_ColoredPrefix", "WS_ResetPlayer", iAdmin, iClient, sReason);
		else
		{
			PrintToAdmins(" %t %t", "WS_ColoredPrefix", "WS_ResetPlayer", iAdmin, iClient, sReason);
			CPrintToChat(iClient, " %t %t", "WS_ColoredPrefix", "WS_ResetPlayerPersonal", iAdmin, sReason);
		}
		
		WarnSystem_OnClientResetWarns(iAdmin, iClient, sReason);
		if(g_bLogWarnings)
			LogWarnings("[WarnSystem] ADMIN (NICK: %N | STEAMID32: STEAM_1:%i:%i | IP: %s) reseted warnings on PLAYER (NICK: %N | STEAMID32: STEAM_1:%i:%i | IP: %s) with reason: %s", iAdmin, g_iAccountID[iAdmin] & 1, g_iAccountID[iAdmin] / 2, g_sClientIP[iAdmin], iClient, g_iAccountID[iAdmin] & 1, g_iAccountID[iAdmin] / 2, g_sClientIP[iClient], sReason);
	} else
		CPrintToChat(iAdmin, " %t %t", "WS_ColoredPrefix", "WS_NotWarned", iClient);
}

//----------------------------------------------------CHECK PLAYER WARNS---------------------------------------------------

public void CheckPlayerWarns(int iAdmin, int iClient)
{
	if (IsValidClient(iClient) && -1<iAdmin && iAdmin<=MaxClients)
	{
		char dbQuery[257];
		FormatEx(dbQuery, sizeof(dbQuery),  g_sSQL_CheckPlayerWarns, g_iAccountID[iClient], g_iServerID);
		
		Handle hCheckData = CreateDataPack(); 
		WritePackCell(hCheckData, GetClientUserId(iAdmin));
		WritePackCell(hCheckData, GetClientUserId(iClient));
		ResetPack(hCheckData);
		
		g_hDatabase.Query(SQL_CheckPlayerWarns, dbQuery, hCheckData);
		//mb print only count of warns? Hm...no.
	}
}

public void SQL_CheckPlayerWarns(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, Handle hCheckData)
{
	if (hDatabaseResults == INVALID_HANDLE || sError[0])
	{
		LogWarnings("[WarnSystem] SQL_CheckPlayerWarns - error while working with data (%s)", sError);
		return;
	}
	
	DisplayCheckWarnsMenu(hDatabaseResults, hCheckData); // Transfer to menus.sp
}

//------------------------------------------------GET INFO ABOUT WARN--------------------------------------------------------

public void SQL_GetInfoWarn(Database hDatabase, DBResultSet hDatabaseResults, const char[] szError, any iAdmin)
{
	if (hDatabaseResults == INVALID_HANDLE || szError[0])
	{
		LogWarnings("[WarnSystem] SQL_GetInfoWarn - error while working with data (%s)", szError);
		return;
	}
	
	DisplayInfoAboutWarn(hDatabaseResults, iAdmin); // Transfer to menus.sp
}

/* public void SQL_CheckPlayerWarns(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, Handle hCheckData)
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
		CPrintToChat(iAdmin, " %t %t", "WS_ColoredPrefix", "WS_NotWarned", iClient);
		return;
	}
	
	CPrintToChat(iAdmin, " %t %t", "WS_ColoredPrefix", "WS_Console", iClient, g_iWarnings[iClient]);
	CPrintToChat(iAdmin, " %t %t", "WS_ColoredPrefix", "See console for output");
	
	char sClient[129], sAdmin[129], sReason[129], sTimeFormat[65];
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
} */

public void SQL_CheckError(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, any data)
{
	if (hDatabaseResults == INVALID_HANDLE || sError[0])
		LogWarnings("[WarnSystem] SQL_CheckError: %s", sError);
}