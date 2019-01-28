Handle g_hAdminMenu;
int g_iTarget[MAXPLAYERS+1];

public void InitializeMenu(Handle hTopMenu)
{
	if (hTopMenu == g_hAdminMenu)
		return;
	
	g_hAdminMenu = hTopMenu;
	TopMenuObject WarnCategory = FindTopMenuCategory(g_hAdminMenu, "warnmenu");
	
	if (!WarnCategory)
		WarnCategory = AddToTopMenu(g_hAdminMenu, "warnmenu", TopMenuObject_Category, Handle_AdminCategory, INVALID_TOPMENUOBJECT, "sm_warnmenu", ADMFLAG_GENERIC);
	
	AddToTopMenu(g_hAdminMenu, "sm_warn", TopMenuObject_Item, AdminMenu_Warn, WarnCategory, "sm_warn", ADMFLAG_GENERIC);
	AddToTopMenu(g_hAdminMenu, "sm_unwarn", TopMenuObject_Item, AdminMenu_UnWarn, WarnCategory, "sm_unwarn", ADMFLAG_GENERIC);
	AddToTopMenu(g_hAdminMenu, "sm_resetwarn", TopMenuObject_Item, AdminMenu_ResetWarn, WarnCategory, "sm_resetwarn", ADMFLAG_GENERIC);
	AddToTopMenu(g_hAdminMenu, "sm_checkwarn", TopMenuObject_Item, AdminMenu_CheckWarn, WarnCategory, "sm_checkwarn", ADMFLAG_GENERIC);
}

public void Handle_AdminCategory(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
		FormatEx(buffer, maxlength, "%T", "WS_AdminMenuTitle", param);
	else if (action == TopMenuAction_DisplayOption)
		FormatEx(buffer, maxlength, "%T", "WS_AdminMenuOption", param);
}

public void AdminMenu_Warn(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		FormatEx(buffer, maxlength, "%T", "WS_AdminMenuWarnTitle", param);
	else if (action == TopMenuAction_SelectOption)
		DisplaySomeoneTargetMenu(param, MenuHandler_Warn);
}

public void AdminMenu_UnWarn(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		FormatEx(buffer, maxlength, "%T", "WS_AdminMenuUnWarnTitle", param);
	else if (action == TopMenuAction_SelectOption)
		DisplaySomeoneTargetMenu(param, MenuHandler_UnWarn);
}

public void AdminMenu_ResetWarn(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		FormatEx(buffer, maxlength, "%T", "WS_AdminMenuResetWarnTitle", param);
	else if (action == TopMenuAction_SelectOption)
		DisplaySomeoneTargetMenu(param, MenuHandler_ResetWarn);
}

public void AdminMenu_CheckWarn(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		FormatEx(buffer, maxlength, "%T", "WS_AdminMenuCheckWarnTitle", param);
	else if (action == TopMenuAction_SelectOption)
		DisplaySomeoneTargetMenu(param, MenuHandler_CheckWarn);
}

public void DisplaySomeoneTargetMenu(int iClient, MenuHandler ptrFunc) {
	Menu hMenu = new Menu(ptrFunc, MenuAction_Select|MenuAction_Cancel|MenuAction_End);
	SetMenuTitle(hMenu, "%T", "WS_TargetMenuTitle", iClient);
	SetMenuExitBackButton(hMenu, true);
	AddTargetsToMenuCustom(hMenu, iClient);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

stock void AddTargetsToMenuCustom(Menu hMenu, int iAdmin)
{
	char sUserId[12], sName[128], sDisplay[128+12];
	for (int i = 1; i <= MaxClients; ++i)
		if (IsClientConnected(i) && !IsClientInKickQueue(i) && !IsFakeClient(i) && IsClientInGame(i) && iAdmin != i && CanUserTarget(iAdmin, i))
		{
			GetClientName(i, sName, sizeof(sName));
			FormatEx(sDisplay, sizeof(sDisplay), "%s [%i/%i]", sName, g_iWarnings[i], g_iMaxWarns);
			IntToString(GetClientUserId(i), sUserId, sizeof(sUserId));
			hMenu.AddItem(sUserId, sDisplay);
		}
}

public int MenuHandler_Warn(Menu menu, MenuAction action, int param1, int param2) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sInfo[8];
			int iTarget;
			
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			
			if (!(iTarget = GetClientOfUserId(StringToInt(sInfo))))
				CPrintToChat(param1, " %t %t", "WS_Prefix", "Player no longer available");
			else if (!CanUserTarget(param1, iTarget))
				CPrintToChat(param1, " %t %t", "WS_Prefix", "Unable to target");
			else
			{
				g_iTarget[param1] = iTarget;
				DisplayWarnReasons(param1);
			}
		}
		case MenuAction_Cancel:
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu)
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
			
		case MenuAction_End:
			CloseHandle(menu);
	}
}

public int MenuHandler_UnWarn(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sInfo[8];
			int iTarget;
			
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			
			if (!(iTarget = GetClientOfUserId(StringToInt(sInfo))))
				CPrintToChat(param1, " %t %t", "WS_Prefix", "Player no longer available");
			else if (!CanUserTarget(param1, iTarget))
				CPrintToChat(param1, " %t %t", "WS_Prefix", "Unable to target");
			else
			{
				g_iTarget[param1] = iTarget;
				DisplayUnWarnReasons(param1);
			}
		}
		case MenuAction_Cancel:
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu)
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
		
		case MenuAction_End:
			CloseHandle(menu);
	}
}

public int MenuHandler_ResetWarn(Menu menu, MenuAction action, int param1, int param2) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sInfo[8];
			int iTarget;
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			
			if (!(iTarget = GetClientOfUserId(StringToInt(sInfo))))
				CPrintToChat(param1, " %t %t", "WS_Prefix", "Player no longer available");
			else if (!CanUserTarget(param1, iTarget))
				CPrintToChat(param1, " %t %t", "WS_Prefix", "Unable to target");
			else
			{
				g_iTarget[param1] = iTarget;
				DisplayResetWarnReasons(param1);
			}
		}
		case MenuAction_Cancel:
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu)
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
		
		case MenuAction_End:
			CloseHandle(menu);
	}
}

public int MenuHandler_CheckWarn(Menu menu, MenuAction action, int param1, int param2) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sInfo[8];
			int iTarget;
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			
			if (!(iTarget = GetClientOfUserId(StringToInt(sInfo))))
				CPrintToChat(param1, " %t %t", "WS_Prefix", "Player no longer available");
			if (!CanUserTarget(param1, iTarget))
				CPrintToChat(param1, " %t %t", "WS_Prefix", "Unable to target");
			else
				CheckPlayerWarns(param1, iTarget);
		}
		case MenuAction_Cancel:
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu)
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
			
		case MenuAction_End:
			CloseHandle(menu);
	}
}

public void DisplayWarnReasons(int iClient) 
{
	char sReason[129];
	
	Menu hMenu = new Menu(MenuHandler_PreformWarn);
	SetMenuTitle(hMenu, "%T", "WS_AdminMenuReasonTitle", iClient);
	SetMenuExitBackButton(hMenu, true);
	
	Handle hFilePath = OpenFile(g_sPathWarnReasons, "rt");
	if (!hFilePath)
	{
		LogWarnings("Could not find the config file (addons/sourcemod/configs/WarnSystem/WarnReasons.cfg)");
		return;
	}
	while (!IsEndOfFile(hFilePath) && ReadFileLine(hFilePath, sReason, sizeof(sReason))) {
		TrimString(sReason);
		if (sReason[0])
			AddMenuItem(hMenu, sReason, sReason);
	}
	
	CloseHandle(hFilePath);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public void DisplayUnWarnReasons(int iClient) 
{
	char sReason[129];
	
	Menu hMenu = new Menu(MenuHandler_PreformUnWarn);
	SetMenuTitle(hMenu, "%T", "WS_AdminMenuReasonTitle", iClient);
	SetMenuExitBackButton(hMenu, true);
	
	Handle hFilePath = OpenFile(g_sPathUnwarnReasons, "rt");
	if (!hFilePath)
	{
		LogWarnings("Could not find the config file (addons/sourcemod/configs/WarnSystem/UnwarnReasons.cfg)");
		return;
	}
	while (!IsEndOfFile(hFilePath) && ReadFileLine(hFilePath, sReason, sizeof(sReason))) {
		TrimString(sReason);
		if (sReason[0])
			AddMenuItem(hMenu, sReason, sReason);
	}
	
	CloseHandle(hFilePath);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public void DisplayResetWarnReasons(int iClient) 
{
	char sReason[129];
	
	Menu hMenu = new Menu(MenuHandler_PreformResetWarn);
	SetMenuTitle(hMenu, "%T", "WS_AdminMenuReasonTitle", iClient);
	SetMenuExitBackButton(hMenu, true);
	
	Handle hFilePath = OpenFile(g_sPathResetReasons, "rt");
	if (!hFilePath)
	{
		LogWarnings("Could not find the config file (addons/sourcemod/configs/WarnSystem/ResetWarnReasons.cfg)");
		return;
	}
	while (!IsEndOfFile(hFilePath) && ReadFileLine(hFilePath, sReason, sizeof(sReason))) {
		TrimString(sReason);
		if (sReason[0])
			AddMenuItem(hMenu, sReason, sReason);
	}
	
	CloseHandle(hFilePath);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_PreformWarn(Handle menu, MenuAction action, int param1, int param2) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sInfo[129];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			WarnPlayer(param1, g_iTarget[param1], sInfo);
		}
		case MenuAction_Cancel:
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu)
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
			
		case MenuAction_End:
			CloseHandle(menu);
	}
}

public int MenuHandler_PreformUnWarn(Handle menu, MenuAction action, int param1, int param2) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sInfo[129];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			UnWarnPlayer(param1, g_iTarget[param1], sInfo);
		}
		case MenuAction_Cancel:
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu)
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
		
		case MenuAction_End:
			CloseHandle(menu);
	}
}

public int MenuHandler_PreformResetWarn(Handle menu, MenuAction action, int param1, int param2) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sInfo[129];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			ResetPlayerWarns(param1, g_iTarget[param1], sInfo);
		}
		case MenuAction_Cancel:
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu)
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
		
		case MenuAction_End:
			CloseHandle(menu);
	}
}

public void BuildAgreement(int iClient, int iAdmin, char[] szReason)
{
	Handle hFilePath = OpenFile(g_sPathAgreePanel, "rt");
	if (!hFilePath)
	{
		LogWarnings("Could not find the config file (addons/sourcemod/configs/WarnSystem/WarnAgreement.cfg)");
		return;
	}
	
	char sBuffer[128];
	
	Handle hMenu = CreatePanel();
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "WS_AgreementTitle", iClient);
	SetPanelTitle(hMenu, sBuffer);
	DrawPanelItem(hMenu, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	while(!IsEndOfFile(hFilePath) && ReadFileLine(hFilePath, sBuffer, sizeof(sBuffer))) {
		char szAdmin[20];
		GetClientName(iAdmin, szAdmin, sizeof(szAdmin));
		ReplaceString(sBuffer, sizeof(sBuffer), "{ADMIN}", szAdmin, false);
		ReplaceString(sBuffer, sizeof(sBuffer), "{REASON}", szReason, false);
		DrawPanelText(hMenu, sBuffer);
	}
	DrawPanelItem(hMenu, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "WS_AgreementAgree", iClient);
	DrawPanelItem(hMenu, sBuffer);
	SendPanelToClient(hMenu, iClient, MenuHandler_WarnAgreement, MENU_TIME_FOREVER);
	
	CloseHandle(hMenu);
	CloseHandle(hFilePath);
}

public int MenuHandler_WarnAgreement(Handle hMenu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		CPrintToChat(param1, " %t %t", "WS_Prefix", "WS_AgreementMessage");
		if (IsPlayerAlive(param1))
			SetEntityMoveType(param1, MOVETYPE_WALK);
	} else if (action == MenuAction_End)
		CloseHandle(hMenu);
}

//------------------------------------------CREATE MENU WITH ALL WARNS OF TARGET---------------------------------------------

void DisplayCheckWarnsMenu(DBResultSet hDatabaseResults, Handle hCheckData)
{
	int iAdmin, iClient;
	
	if(hCheckData)
	{
		iAdmin = GetClientOfUserId(ReadPackCell(hCheckData));
		iClient = GetClientOfUserId(ReadPackCell(hCheckData));
		g_iUserID[iAdmin] = GetClientUserId(iClient);
		CloseHandle(hCheckData); 
	} else return;
	
	if (!hDatabaseResults.RowCount)
	{
		CPrintToChat(iAdmin, " %t %t", "WS_ColoredPrefix", "WS_NotWarned", iClient);
		return;
	}
	
	if(!IsValidClient(iAdmin))      return;
	
	//`ws_warn`.`warn_id`, `ws_player`.`account_id`, `ws_player`.`username`, `ws_warn`.`created_at`
	
	//CPrintToChat(iAdmin, " %t %t", "WS_ColoredPrefix", "WS_Console", iClient, g_iWarnings[iClient]);
	//CPrintToChat(iAdmin, " %t %t", "WS_ColoredPrefix", "See console for output");
	
	char szAdmin[129], szTimeFormat[65], szBuffer[80], szID[25];
	int iDate, iID;
	Menu hMenu = new Menu(CheckPlayerWarnsMenu);
	hMenu.SetTitle("%T:\n", "WS_CPWTitle", iAdmin, iClient);
	//Ya, nice output *NOW TO MENU, BITCHES*!
	
	while (hDatabaseResults.FetchRow())
	{
		iID = hDatabaseResults.FetchInt(0);
		IntToString(iID, szID, sizeof(szID));
		SQL_FetchString(hDatabaseResults, 2, szAdmin, sizeof(szAdmin));
		iDate = hDatabaseResults.FetchInt(3);
		
		
		FormatTime(szTimeFormat, sizeof(szTimeFormat), "%Y-%m-%d %X", iDate);
		FormatEx(szBuffer, sizeof(szBuffer), "[%s] %s", szAdmin, szTimeFormat);
		hMenu.AddItem(szID, szBuffer);
	}
	hMenu.ExitBackButton = true;
	hMenu.Display(iAdmin, MENU_TIME_FOREVER);
}

public int CheckPlayerWarnsMenu(Menu hMenu, MenuAction action, int param1, int iItem)
{
	switch(action){
		
		case MenuAction_Select: {
			char szdbQuery[513];
			char szID[25];
			int iID;
			hMenu.GetItem(iItem, szID, sizeof(szID));
			iID = StringToInt(szID);
			
			FormatEx(szdbQuery, sizeof(szdbQuery),  g_sSQL_GetInfoWarn, iID);
			//LogMessage("Fetch warn: %s", szdbQuery);
			g_hDatabase.Query(SQL_GetInfoWarn, szdbQuery, param1); // OH NO! DB-query in menus.sp!!! FUCK!!!
			if(g_bLogQuery)
				LogQuery("CheckPlayerWarnsMenu::SQL_GetInfoWarn: %s", szdbQuery);
		} 
		case MenuAction_End:    CloseHandle(hMenu);
		case MenuAction_Cancel: if(iItem == MenuCancel_ExitBack)    DisplaySomeoneTargetMenu(param1, MenuHandler_CheckWarn);
			
			
	}
}

//-------------------------------------CREATE MENU WITH INFORMATION ABOUT SELECTED WARN------------------------------------------

void DisplayInfoAboutWarn(DBResultSet hDatabaseResults, any iAdmin)
{
	if(!hDatabaseResults.FetchRow())     return;
	if(!IsValidClient(iAdmin))      return;
	char szClient[129], szAdmin[129], szReason[129], szTimeFormat[65], szBuffer[80];
	int iDate, iExpired;
	
	//                    0                            1                                 2                              3                      4                  5                       6
	//`admin`.`account_id` admin_id, `admin`.`username` admin_name, `player`.`account_id` client_id, `player`.`username` client_name, `ws_warn`.`reason` `ws_warn`.`expires_at`, `ws_warn`.`created_at`
	
	Menu hMenu = new Menu(GetInfoWarnMenu_CallBack);
	hMenu.SetTitle("%T:\n", "WS_InfoWarn", iAdmin);
	
	SQL_FetchString(hDatabaseResults, 1, szAdmin, sizeof(szAdmin));
	FormatEx(szBuffer, sizeof(szBuffer), "%T", "WS_InfoAdmin", iAdmin, szAdmin);
	hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
	SQL_FetchString(hDatabaseResults, 3, szClient, sizeof(szClient));
	FormatEx(szBuffer, sizeof(szBuffer), "%T", "WS_InfoClient", iAdmin, szClient);
	hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
	SQL_FetchString(hDatabaseResults, 4, szReason, sizeof(szReason));
	FormatEx(szBuffer, sizeof(szBuffer), "%T", "WS_InfoReason", iAdmin ,szReason);
	hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
	iExpired = hDatabaseResults.FetchInt(5);
	iDate    = hDatabaseResults.FetchInt(6);
	FormatTime(szTimeFormat, sizeof(szTimeFormat), "%Y-%m-%d %X", iExpired);
	FormatEx(szBuffer, sizeof(szBuffer), "%T", "WS_InfoExpired", iAdmin, szTimeFormat);
	hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
	FormatTime(szTimeFormat, sizeof(szTimeFormat), "%Y-%m-%d %X", iDate);
	FormatEx(szBuffer, sizeof(szBuffer), "%T", "WS_InfoTime", iAdmin, szTimeFormat);
	hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
	
	hMenu.ExitBackButton = true;
	hMenu.ExitButton = false;
	hMenu.Display(iAdmin, MENU_TIME_FOREVER);
}

public int GetInfoWarnMenu_CallBack(Menu hMenu, MenuAction action, int iAdmin, int iItem)
{
	switch(action){
		case MenuAction_End:    CloseHandle(hMenu);
		case MenuAction_Cancel: if(iItem == MenuCancel_ExitBack)    CheckPlayerWarns(iAdmin, GetClientOfUserId(g_iUserID[iAdmin]));
	}
}