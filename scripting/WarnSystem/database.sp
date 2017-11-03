Handle g_hDatabase;

public void InitializeDatabase() { SQL_TConnect(SQL_OnConnect, "warn"); }

public void SQL_OnConnect(Handle owner, Handle hndl, const char[] sError, any data)
{
	if (!hndl)
	{
		SetFailState("[WarnSystem] Database failure: %s", sError);
		return;
	}
	g_hDatabase = hndl;
	char sBuffer[32];
	SQL_GetDriverIdent(SQL_ReadDriver(g_hDatabase), sBuffer, sizeof(sBuffer));
	bool UseMySQL = !strcmp(sBuffer, "mysql", false) ? true : false;
	SQL_LockDatabase(g_hDatabase);
	if (UseMySQL)
		FormatEx(sBuffer, sizeof(sBuffer), "CREATE TABLE IF NOT EXISTS `WarnSystem` (`id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,\
																					`target` VARCHAR(64),\
																					`targetid` VARCHAR(32),\
																					`admin` VARCHAR(64),\
																					`adminid` VARCHAR(32),\
																					`reason` VARCHAR(64),\
																					`time` VARCHAR(64),\
																					`expired` VARCHAR(1))");
	else
		FormatEx(sBuffer, sizeof(sBuffer), "CREATE TABLE IF NOT EXISTS WarnSystem (id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,\
																				   target TEXT,\
																				   targetid TEXT,\
																				   admin TEXT,\
																				   adminid TEXT,\
																				   reason TEXT,\
																				   time TEXT,\
																				   expired TEXT);");
	SQL_UnlockDatabase(g_hDatabase);
	SQL_TQuery(g_hDatabase, SQL_EmptyCallback, sBuffer);
	if (UseMySQL)
	{
		char dbQuery[16];
		strcopy(dbQuery, sizeof(dbQuery), "SET NAMES 'utf8'");
		SQL_TQuery(g_hDatabase, SQL_EmptyCallback, dbQuery);
	}
}

public void SQL_CheckWarnings(Handle owner, Handle hndl, const char[] sError, int iClient)
{
	if (!hndl)
	{
		InitializeDatabase();
		return;
	}
	
	if(sError[0])
	{
		LogError("SQL_CheckWarnings: %s", sError);
		return;
	}
	
	if (SQL_FetchRow(hndl))
	{
		int iWarnings = SQL_GetRowCount(hndl);
		if (g_bPrintToAdmins)
			PrintToAdmins("\x03[WarnSystem] \x01%t", "warn_warnconnect", iWarnings);
	}
}

public void SQL_WarnPlayer(Handle owner, Handle hndl, const char[] sError, Handle hWarnData)
{
	if (!hndl)
	{
		InitializeDatabase();
		return;
	}
	
	if(sError[0])
	{
		LogError("SQL_WarnPlayer: %s", sError);
		return;
	}
	
	int iClient, iTarget, iTime;
	iTime = GetTime();
	char sReason[64], sClientID[32], sTargetID[32], sClientNick[64], sTargetNick[64],
		 sEscapedClientNick[64], sEscapedTargetNick[64], sEscapedReason[64], dbQuery[255];
	
	if(hWarnData)
	{
		iClient = GetClientOfUserId(ReadPackCell(hWarnData));
		iTarget = GetClientOfUserId(ReadPackCell(hWarnData));
		ReadPackString(hWarnData, sReason, sizeof(sReason));
		CloseHandle(hWarnData); 
	}
	
	if (iClient)
	{
		GetClientAuthId(iClient, AuthId_Steam2, sClientID, sizeof(sClientID));
		GetClientName(iClient, sClientNick, sizeof(sClientNick));
		SQL_EscapeString(g_hDatabase, sClientNick, sEscapedClientNick, sizeof(sEscapedClientNick));
	} else
	{
		strcopy(sClientID, sizeof(sClientID), "CONSOLE");
		strcopy(sEscapedClientNick, sizeof(sEscapedClientNick), "CONSOLE");
	}
	
	GetClientAuthId(iTarget, AuthId_Steam2, sTargetID, sizeof(sTargetID));
	GetClientName(iTarget, sTargetNick, sizeof(sTargetNick));
	SQL_EscapeString(g_hDatabase, sTargetNick, sEscapedTargetNick, sizeof(sEscapedTargetNick));
	SQL_EscapeString(g_hDatabase, sReason, sEscapedReason, sizeof(sEscapedReason));
	
	if (SQL_FetchRow(hndl))
	{
		int iWarnings = SQL_GetRowCount(hndl);
		++iWarnings;
		
		FormatEx(dbQuery, sizeof(dbQuery), "INSERT INTO WarnSystem (target, targetid, admin, adminid, reason, time, expired) VALUES ('%s', '%s', '%s', '%s', '%s', '%i', '0')", sEscapedTargetNick, sTargetID, sEscapedClientNick, sClientID, sEscapedReason, iTime);
		SQL_TQuery(g_hDatabase, SQL_EmptyCallback, dbQuery);
		
		if (iWarnings >= g_iMaxWarns)
		{
			if(g_bResetWarnings)
			{
				FormatEx(dbQuery, sizeof(dbQuery), "DELETE FROM WarnSystem WHERE targetid = '%s'", sTargetID);
				SQL_TQuery(g_hDatabase, SQL_EmptyCallback, dbQuery);
			}
			else
			{
				FormatEx(dbQuery, sizeof(dbQuery), "UPDATE WarnSystem SET expired = '1' WHERE targetid = '%s'", sTargetID);
				SQL_TQuery(g_hDatabase, SQL_EmptyCallback, dbQuery);
			}
			
			if(g_bLogWarnings)
			{
				char sTargetIP[32], sClientIP[32];
				GetClientIP(iTarget, sTargetIP, sizeof(sTargetIP));
				GetClientIP(iClient, sClientIP, sizeof(sClientIP));
				LogWarnings("[WarnSystem] %t", "warn_warn_log", iClient, sClientID, sClientIP, iTarget, sTargetID, sTargetIP, sReason);
			}
			PunishPlayerOnMaxWarns(iTarget, sReason);
		}
	} else
	{
		FormatEx(dbQuery, sizeof(dbQuery), "INSERT INTO WarnSystem (target, targetid, admin, adminid, reason, time, expired) VALUES ('%s', '%s', '%s', '%s', '%s', '%i', '0')", sTargetNick, sTargetID, sClientNick, sClientID, sReason, iTime);
		SQL_TQuery(g_hDatabase, SQL_EmptyCallback, dbQuery);
	}
	
	PunishPlayer(iTarget, sReason);
}

public void SQL_UnWarnPlayer(Handle owner, Handle hndl, const char[] sError, Handle hUnwarnData)
{
	if (!hndl)
	{
		InitializeDatabase();
		return;
	}
	
	if(sError[0])
	{
		LogError("SQL_UnWarnPlayer: %s", sError);
		return;
	}
	
	int iClient, iTarget;
	char sTargetID[32], sReason[32], dbQuery[255];
	
	if(hUnwarnData)
	{
		iClient = GetClientOfUserId(ReadPackCell(hUnwarnData));
		iTarget = GetClientOfUserId(ReadPackCell(hUnwarnData));
		ReadPackString(hUnwarnData, sTargetID, sizeof(sTargetID));
		ReadPackString(hUnwarnData, sReason, sizeof(sReason));
		CloseHandle(hUnwarnData); 
	}
	
	if (SQL_FetchRow(hndl))
	{
		char sTime[64];
		SQL_FetchString(hndl, 6, sTime, sizeof(sTime));
		
		FormatEx(dbQuery, sizeof(dbQuery), "DELETE FROM WarnSystem WHERE time = '%s' AND targetid = '%s'", sTime, sTargetID);
		SQL_TQuery(g_hDatabase, SQL_EmptyCallback, dbQuery);
		PrintToChatAll("\x03[WarnSystem] \x01", "%t", "warn_unwarn_player", iTarget, sReason);
		
		if(g_bLogWarnings)
		{
			char sClientID[32], sClientIP[32], sTargetIP[32];
			if (iClient)
			{
				GetClientAuthId(iClient, AuthId_Steam2, sClientID, sizeof(sClientID));
				GetClientIP(iClient, sClientIP, sizeof(sClientIP));
			} else
			{
				strcopy(sClientID, sizeof(sClientID), "CONSOLE");
				strcopy(sClientIP, sizeof(sClientIP), "Unknown");
			}
			GetClientIP(iTarget, sTargetIP, sizeof(sTargetIP));
			LogWarnings("[WarnSystem] %t", "warn_unwarn_log", iClient, sClientID, sClientIP, iTarget, sTargetID, sTargetIP, sReason);
		}
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
		SQL_TQuery(g_hDatabase, SQL_EmptyCallback, dbQuery);
		
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
		
public void SQL_EmptyCallback(Handle owner, Handle hndl, const char[] sError, Handle hWarnData)
{
	if(sError[0])
		LogError("Query failure: %s", sError);
}