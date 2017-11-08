Handle g_hAdminMenu;
int g_iTarget[MAXPLAYERS+1];

public void InitializeMenu(Handle topmenu)
{
	if (topmenu == g_hAdminMenu)
		return;
	
	g_hAdminMenu = topmenu;
	TopMenuObject WarnCategory = FindTopMenuCategory(g_hAdminMenu, "warnmenu");
	
	if (!WarnCategory)
		WarnCategory = AddToTopMenu(g_hAdminMenu, "warnmenu", TopMenuObject_Category, Handle_AdminCategory, INVALID_TOPMENUOBJECT, "sm_warnmenu", ADMINMENUFLAG);
	
	AddToTopMenu(g_hAdminMenu, "sm_warn", TopMenuObject_Item, AdminMenu_Warn, WarnCategory, "sm_warn", WARNFLAG);
	AddToTopMenu(g_hAdminMenu, "sm_unwarn", TopMenuObject_Item, AdminMenu_UnWarn, WarnCategory, "sm_unwarn", UNWARNFLAG);
	AddToTopMenu(g_hAdminMenu, "sm_resetwarn", TopMenuObject_Item, AdminMenu_ResetWarn, WarnCategory, "sm_resetwarn", RESETWARNSFLAG);
	AddToTopMenu(g_hAdminMenu, "sm_checkwarn", TopMenuObject_Item, AdminMenu_CheckWarn, WarnCategory, "sm_checkwarn", CHECKWARNFLAG);
}

public void Handle_AdminCategory(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayTitle:
		{
			FormatEx(buffer, maxlength, "%T", "WS_AdminMenuTitle", param);
		}
		case TopMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlength, "%T", "WS_AdminMenuOption", param);
		}
	}
}

public void AdminMenu_Warn(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlength, "%T", "WS_AdminMenuWarnTitle", param);
		}
		case TopMenuAction_SelectOption:
		{
			DisplaySomeoneTargetMenu(param, MenuHandler_Warn);
		}
	}
}

public void AdminMenu_UnWarn(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlength, "%T", "WS_AdminMenuUnWarnTitle", param);
		}
		case TopMenuAction_SelectOption:
		{
			DisplaySomeoneTargetMenu(param, MenuHandler_UnWarn);
		}
	}
}

public void AdminMenu_ResetWarn(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlength, "%T", "WS_AdminMenuResetWarnTitle", param);
		}
		case TopMenuAction_SelectOption:
		{
			DisplaySomeoneTargetMenu(param, MenuHandler_ResetWarn);
		}
	}
}

public void AdminMenu_CheckWarn(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlength, "%T", "WS_AdminMenuCheckWarnTitle", param);
		}
		case TopMenuAction_SelectOption:
		{
			DisplaySomeoneTargetMenu(param, MenuHandler_CheckWarn);
		}
	}
}

/*public void DisplayWarnTargetMenu(int iClient) 
{
	Menu hMenu = new Menu(MenuHandler_Warn, MENU_ACTIONS_ALL);
	SetMenuTitle(hMenu, "%T", "WS_TargetMenuTitle", iClient);
	SetMenuExitBackButton(hMenu, true);
	AddTargetsToMenu2(hMenu, iClient, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public void DisplayUnWarnTargetMenu(int iClient) 
{
	Menu hMenu = new Menu(MenuHandler_UnWarn, MENU_ACTIONS_ALL);
	SetMenuTitle(hMenu, "%T", "WS_TargetMenuTitle", iClient);
	SetMenuExitBackButton(hMenu, true);
	AddTargetsToMenu2(hMenu, iClient, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public void DisplayResetWarnTargetMenu(int iClient) 
{
	Menu hMenu = new Menu(MenuHandler_ResetWarn, MENU_ACTIONS_ALL);
	SetMenuTitle(hMenu, "%T", "WS_TargetMenuTitle", iClient);
	SetMenuExitBackButton(hMenu, true);
	AddTargetsToMenu2(hMenu, iClient, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public void DisplayCheckWarnTargetMenu(int iClient) 
{
	Menu hMenu = new Menu(MenuHandler_CheckWarn, MENU_ACTIONS_ALL);
	SetMenuTitle(hMenu, "%T", "WS_TargetMenuTitle", iClient);
	SetMenuExitBackButton(hMenu, true);
	AddTargetsToMenu2(hMenu, iClient, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}*/

public void DisplaySomeoneTargetMenu(int iClient, MenuHandler ptrFunc) {
    Menu hMenu = new Menu(ptrFunc, MENU_ACTIONS_ALL);
    SetMenuTitle(hMenu, "%T", "WS_TargetMenuTitle", iClient);
    SetMenuExitBackButton(hMenu, true);
    AddTargetsToMenu2(hMenu, iClient, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);
    DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_Warn(Menu menu, MenuAction action, int param1, int param2) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
			int iUserid, iTarget;
			
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			iUserid = StringToInt(sInfo);

			if (!(iTarget = GetClientOfUserId(iUserid)))
				CPrintToChat(param1, "%t %t", "WS_Prefix", "Player no longer available");
			else if (!CanUserTarget(param1, iTarget))
				CPrintToChat(param1, "%t %t", "WS_Prefix", "Unable to target");
			else
			{
				g_iTarget[param1] = iUserid;
				DisplayWarnReasons(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu)
			{
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public int MenuHandler_UnWarn(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
			int iUserid, iTarget;
			
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			iUserid = StringToInt(sInfo);

			if (!(iTarget = GetClientOfUserId(iUserid)))
				CPrintToChat(param1, "%t %t", "WS_Prefix", "Player no longer available");
			else if (!CanUserTarget(param1, iTarget))
				CPrintToChat(param1, "%t %t", "WS_Prefix", "Unable to target");
			else
			{
				g_iTarget[param1] = iUserid;
				DisplayUnWarnReasons(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu)
			{
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public int MenuHandler_ResetWarn(Menu menu, MenuAction action, int param1, int param2) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
			int iUserid, iTarget;
			
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			iUserid = StringToInt(sInfo);

			if (!(iTarget = GetClientOfUserId(iUserid)))
				CPrintToChat(param1, "%t %t", "WS_Prefix", "Player no longer available");
			else if (!CanUserTarget(param1, iTarget))
				CPrintToChat(param1, "%t %t", "WS_Prefix", "Unable to target");
			else
			{
				g_iTarget[param1] = iUserid;
				DisplayResetWarnReasons(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu)
			{
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public int MenuHandler_CheckWarn(Menu menu, MenuAction action, int param1, int param2) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
			int iTarget;
			
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			iTarget = GetClientOfUserId(StringToInt(sInfo));

			if (!iTarget)
				CPrintToChat(param1, "%t %t", "WS_Prefix", "Player no longer available");
			else if (!CanUserTarget(param1, iTarget))
				CPrintToChat(param1, "%t %t", "WS_Prefix", "Unable to target");
			else
				CheckPlayerWarns(param1, iTarget);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu)
			{
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public void DisplayWarnReasons(int iClient) 
{
	char sReason[64];
	
	Menu hMenu = new Menu(MenuHandler_PreformUnWarn, MENU_ACTIONS_ALL);
	SetMenuTitle(hMenu, "%T", "WS_AdminMenuReasonTitle", iClient);
	SetMenuExitBackButton(hMenu, true);
	
	Handle hFilePath = OpenFile(g_sPathWarnReasons, "rt");
	if (!hFilePath)
	{
		LogWarnings("Could not find the config file (addons/sourcemod/configs/WarnSystem/WarnReasons.cfg)");
		return;
	}
	while (!IsEndOfFile(hFilePath) && ReadFileLine(hFilePath, sReason, sizeof(sReason)))
	{
		AddMenuItem(hMenu, sReason, sReason);
	}
	
	CloseHandle(hFilePath);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public void DisplayUnWarnReasons(int iClient) 
{
	char sReason[64];
	
	Menu hMenu = new Menu(MenuHandler_PreformUnWarn, MENU_ACTIONS_ALL);
	SetMenuTitle(hMenu, "%T", "WS_AdminMenuReasonTitle", iClient);
	SetMenuExitBackButton(hMenu, true);
	
	Handle hFilePath = OpenFile(g_sPathUnwarnReasons, "rt");
	if (!hFilePath)
	{
		LogWarnings("Could not find the config file (addons/sourcemod/configs/WarnSystem/UnwarnReasons.cfg)");
		return;
	}
	while (!IsEndOfFile(hFilePath) && ReadFileLine(hFilePath, sReason, sizeof(sReason)))
	{
		AddMenuItem(hMenu, sReason, sReason);
	}
	CloseHandle(hFilePath);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public void DisplayResetWarnReasons(int iClient) 
{
	char sReason[64];
	
	Menu hMenu = new Menu(MenuHandler_PreformResetWarn, MENU_ACTIONS_ALL);
	SetMenuTitle(hMenu, "%T", "WS_AdminMenuReasonTitle", iClient);
	SetMenuExitBackButton(hMenu, true);
	
	Handle hFilePath = OpenFile(g_sPathResetReasons, "rt");
	if (!hFilePath)
	{
		LogWarnings("Could not find the config file (addons/sourcemod/configs/WarnSystem/ResetWarnReasons.cfg)");
		return;
	}
	while (!IsEndOfFile(hFilePath) && ReadFileLine(hFilePath, sReason, sizeof(sReason)))
	{
		AddMenuItem(hMenu, sReason, sReason);
	}
	CloseHandle(hFilePath);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public void MenuHandler_PreformWarn(Handle menu, MenuAction action, int param1, int param2) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			WarnPlayer(GetClientOfUserId(param1), g_iTarget[param1], sInfo);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu)
			{
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
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
			UnWarnPlayer(GetClientOfUserId(param1), g_iTarget[param1], sInfo);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu)
			{
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
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
			ResetPlayerWarns(GetClientOfUserId(param1), g_iTarget[param1], sInfo);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu)
			{
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
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
	char sTitle[32], sAgree[32], sData[64];
	FormatEx(sTitle, sizeof(sTitle), "%T", "WS_AgreementTitle", iClient);
	FormatEx(sAgree, sizeof(sAgree), "%T", "WS_AgreementAgree", iClient);
	
	Handle hMenu = CreatePanel();
	SetPanelTitle(hMenu, sTitle);
	DrawPanelItem(hMenu, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	while(!IsEndOfFile(hFilePath) && ReadFileLine(hFilePath, sData, sizeof(sData)))
		DrawPanelText(hMenu, sData);
	DrawPanelItem(hMenu, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	DrawPanelItem(hMenu, sAgree);
	SendPanelToClient(hMenu, iClient, MenuHandler_WarnAgreement, MENU_TIME_FOREVER);

	CloseHandle(hMenu);
	CloseHandle(hFilePath);
}

public int MenuHandler_WarnAgreement(Handle hMenu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			CPrintToChat(param1, "%t %t", "WS_Prefix", "WS_AgreementMessage");
			if (IsPlayerAlive(param1))
				SetEntityMoveType(param1, MOVETYPE_WALK);
		}
		case MenuAction_End:
		{
			CloseHandle(hMenu);
		}
	}
}