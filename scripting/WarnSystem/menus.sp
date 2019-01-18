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
	char sUserId[12], sName[MAX_NAME_LENGTH], sDisplay[MAX_NAME_LENGTH+12];
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
			else if (!CanUserTarget(param1, iTarget))
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
	char sReason[64];
	
	Menu hMenu = new Menu(MenuHandler_PreformWarn, MenuAction_Select|MenuAction_Cancel|MenuAction_End);
	SetMenuTitle(hMenu, "%T", "WS_AdminMenuReasonTitle", iClient);
	SetMenuExitBackButton(hMenu, true);
	
	Handle hFilePath = OpenFile(g_sPathWarnReasons, "rt");
	if (!hFilePath)
	{
		LogWarnings("Could not find the config file (addons/sourcemod/configs/WarnSystem/WarnReasons.cfg)");
		return;
	}
	while (!IsEndOfFile(hFilePath) && ReadFileLine(hFilePath, sReason, sizeof(sReason)))
		AddMenuItem(hMenu, sReason, sReason);
	
	CloseHandle(hFilePath);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public void DisplayUnWarnReasons(int iClient) 
{
	char sReason[64];
	
	Menu hMenu = new Menu(MenuHandler_PreformUnWarn, MenuAction_Select|MenuAction_Cancel|MenuAction_End);
	SetMenuTitle(hMenu, "%T", "WS_AdminMenuReasonTitle", iClient);
	SetMenuExitBackButton(hMenu, true);
	
	Handle hFilePath = OpenFile(g_sPathUnwarnReasons, "rt");
	if (!hFilePath)
	{
		LogWarnings("Could not find the config file (addons/sourcemod/configs/WarnSystem/UnwarnReasons.cfg)");
		return;
	}
	while (!IsEndOfFile(hFilePath) && ReadFileLine(hFilePath, sReason, sizeof(sReason)))
		AddMenuItem(hMenu, sReason, sReason);
	
	CloseHandle(hFilePath);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public void DisplayResetWarnReasons(int iClient) 
{
	char sReason[64];
	
	Menu hMenu = new Menu(MenuHandler_PreformResetWarn, MenuAction_Select|MenuAction_Cancel|MenuAction_End);
	SetMenuTitle(hMenu, "%T", "WS_AdminMenuReasonTitle", iClient);
	SetMenuExitBackButton(hMenu, true);
	
	Handle hFilePath = OpenFile(g_sPathResetReasons, "rt");
	if (!hFilePath)
	{
		LogWarnings("Could not find the config file (addons/sourcemod/configs/WarnSystem/ResetWarnReasons.cfg)");
		return;
	}
	while (!IsEndOfFile(hFilePath) && ReadFileLine(hFilePath, sReason, sizeof(sReason)))
		AddMenuItem(hMenu, sReason, sReason);
	
	CloseHandle(hFilePath);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_PreformWarn(Handle menu, MenuAction action, int param1, int param2) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
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
			char sInfo[64];
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
			char sInfo[64];
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

public void BuildAgreement(int iClient)
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
	while(!IsEndOfFile(hFilePath) && ReadFileLine(hFilePath, sBuffer, sizeof(sBuffer)))
		DrawPanelText(hMenu, sBuffer);
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
		CloseHandle(hCheckData); 
	} else return;
	
	if (!hDatabaseResults.RowCount)
	{
		CPrintToChat(iAdmin, " %t %t", "WS_ColoredPrefix", "WS_NotWarned", iClient);
		return;
	}
	
	//CPrintToChat(iAdmin, " %t %t", "WS_ColoredPrefix", "WS_Console", iClient, g_iWarnings[iClient]);
	//CPrintToChat(iAdmin, " %t %t", "WS_ColoredPrefix", "See console for output");
	
	char szAdmin[64], szTimeFormat[32], szBuffer[80], szID[13];
	int iDate;
	Menu hMenu = new Menu(CheckPlayerWarnsMenu);
	hMenu.SetTitle("%T:\n", "WS_CPWTitle", iClient);
	//Ya, nice output
	
	while (hDatabaseResults.FetchRow()) // Сделай вывод всех сначала в меню, а потом выбор нужной, то, что ниже - не канает.
	{
		szID = IntToString(hDatabaseResults.FetchInt(0));
		SQL_FetchString(hDatabaseResults, 1, szAdmin, sizeof(szAdmin));
		iDate = hDatabaseResults.FetchInt(2);
		
		
		FormatTime(szTimeFormat, sizeof(szTimeFormat), "%Y-%m-%d %X", iDate);
		FormatEx(szBuffer, sizeof(szBuffer), "[%s] %s", szAdmin, szTimeFormat);
		menu.AddItem(szID, szBuffer);
	}
	hMenu.ExitBackButton = true;
	hMenu.Display(iAdmin, MENU_TIME_FOREVER);
}

public int CheckPlayerWarnsMenu(Handle hMenu, MenuAction action, int param1, int iItem)
{
    switch(action){
        
        case MenuAction_Select: {
            char szDBQuery[512];
            int iID = StringToInt(hMenu.GetItem(iItem, szID, sizeof(szID)));
            
            FormatEx(szDBQuery, sizeof(szDBQuery),  g_sSQL_GetInfoWarn, iID);
            g_hDatabase.Query(szDBQuery, param1); // OH NO! DB-query in menus.sp!!! FUCK!!!
        } 
        case MenuAction_End:
            CloseHandle(hMenu);
        case MenuAction_Cancel:
            CloseHandle(hMenu);
            
        
}

//-------------------------------------CREATE MENU WITH INFORMATION ABOUT SELECTED WARN------------------------------------------

void DisplayInfoWarn(DBResultSet hDatabaseResults, any iAdmin)
{
    char szClient[64], szAdmin[64], szReason[64], szTimeFormat[32], szBuffer[80];
    int iDate, iExpired;
    
    Menu hMenu = new Menu(GetInfoWarnMenu_CallBack);
    hMenu.SetTitle("%T:\n", "WS_InfoWarn");
    
    SQL_FetchString(hDatabaseResults, 0, szClient, sizeof(szClient));
    FormatEx(szBuffer, sizeof(szBuffer), szClient);
    hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
    SQL_FetchString(hDatabaseResults, 1, szAdmin, sizeof(szAdmin));
    FormatEx(szBuffer, sizeof(szBuffer), szAdmin);
    hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
    SQL_FetchString(hDatabaseResults, 2, szReason, sizeof(szReason));
    FormatEx(szBuffer, sizeof(szBuffer), szReason);
    hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
    iDate = hDatabaseResults.FetchInt(3);
    FormatEx(szBuffer, sizeof(szBuffer), iDate);
    hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
    iExpired = hDatabaseResults.FetchInt(4);
    FormatEx(szBuffer, sizeof(szBuffer), iExpired);
    hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
    FormatTime(szTimeFormat, sizeof(szTimeFormat), "%Y-%m-%d %X", iDate);
    FormatEx(szBuffer, sizeof(szBuffer), szTimeFormat);
    hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
	
    hMenu.ExitBackButton = true;
    hMenu.ExitButton = false;
	hMenu.Display(iAdmin, MENU_TIME_FOREVER);
}

public int GetInfoWarnMenu_CallBack(Handle hMenu, MenuAction action, int param1, int iItem)
{
    switch(action){
        case MenuAction_End:
            CloseHandle(hMenu);
        case MenuAction_Cancel: 
            CloseHandle(hMenu);
}