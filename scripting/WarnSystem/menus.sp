Handle g_hAdminMenu;
int g_iTarget[MAXPLAYERS+1];

public void InitializeMenu(Handle topmenu)
{
	if (topmenu == g_hAdminMenu)
		return;
	
	g_hAdminMenu = topmenu;
	TopMenuObject WarnCategory = FindTopMenuCategory(g_hAdminMenu, "warnmenu");
	
	if (!WarnCategory)
		WarnCategory = AddToTopMenu(g_hAdminMenu, "warnmenu", TopMenuObject_Category, Handle_AdminCategory, INVALID_TOPMENUOBJECT, "sm_warnmenu", ADMFLAG_BAN);
	
	AddToTopMenu(g_hAdminMenu, "sm_warn", TopMenuObject_Item, AdminMenu_Warn, WarnCategory, "sm_warn", ADMFLAG_BAN);
	AddToTopMenu(g_hAdminMenu, "sm_unwarn", TopMenuObject_Item, AdminMenu_UnWarn, WarnCategory, "sm_unwarn", ADMFLAG_BAN);
	AddToTopMenu(g_hAdminMenu, "sm_resetwarn", TopMenuObject_Item, AdminMenu_ResetWarn, WarnCategory, "sm_resetwarn", ADMFLAG_BAN);
	AddToTopMenu(g_hAdminMenu, "sm_checkwarn", TopMenuObject_Item, AdminMenu_CheckWarn, WarnCategory, "sm_checkwarn", ADMFLAG_BAN);
}

public void Handle_AdminCategory(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayTitle:
		{
			FormatEx(buffer, maxlength, "%T", "AdminMenuTitle", param);
		}
		case TopMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlength, "%T", "AdminMenuOption", param);
		}
	}
}

public void AdminMenu_Warn(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlength, "%T", "WarnAdminmenuTitle", param);
		}
		case TopMenuAction_SelectOption:
		{
			DisplayWarnTargetMenu(param);
		}
	}
}

public void AdminMenu_UnWarn(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlength, "%T", "UnwarnAdminmenuTitle", param);
		}
		case TopMenuAction_SelectOption:
		{
			DisplayUnWarnTargetMenu(param);
		}
	}
}

public void AdminMenu_ResetWarn(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlength, "%T", "warn_resetwarn_adminmenu_title", param);
		}
		case TopMenuAction_SelectOption:
		{
			DisplayResetWarnTargetMenu(param);
		}
	}
}

public void AdminMenu_CheckWarn(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlength, "%T", "CheckwarnAdminmenuTitle", param);
		}
		case TopMenuAction_SelectOption:
		{
			DisplayCheckWarnTargetMenu(param);
		}
	}
}

public void DisplayWarnTargetMenu(int iClient) 
{
	Menu hMenu = new Menu(MenuHandler_Warn, MENU_ACTIONS_ALL);
	SetMenuTitle(hMenu, "%T", "WarnTargetMenuTitle", iClient);
	SetMenuExitBackButton(hMenu, true);
	AddTargetsToMenu2(hMenu, iClient, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public void DisplayUnWarnTargetMenu(int iClient) 
{
	Menu hMenu = new Menu(MenuHandler_UnWarn, MENU_ACTIONS_ALL);
	SetMenuTitle(hMenu, "%T", "UnwarnTargetMenuTitle", iClient);
	SetMenuExitBackButton(hMenu, true);
	AddTargetsToMenu2(hMenu, iClient, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public void DisplayResetWarnTargetMenu(int iClient) 
{
	Menu hMenu = new Menu(MenuHandler_ResetWarn, MENU_ACTIONS_ALL);
	SetMenuTitle(hMenu, "%T", "warn_resetwarn_targetmenutitle", iClient);
	SetMenuExitBackButton(hMenu, true);
	AddTargetsToMenu2(hMenu, iClient, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public void DisplayCheckWarnTargetMenu(int iClient) 
{
	Menu hMenu = new Menu(MenuHandler_CheckWarn, MENU_ACTIONS_ALL);
	SetMenuTitle(hMenu, "%T", "CheckwarnTargetMenuTitle", iClient);
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
				PrintToChat(param1, "\x03[WarnSystem] \x01%t", "warn_notavailable");
			else if (!CanUserTarget(param1, iTarget))
				PrintToChat(param1, "\x03[WarnSystem] \x01%t", "warn_canttarget");
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
				PrintToChat(param1, "\x03[WarnSystem] \x01%t", "warn_notavailable");
			else if (!CanUserTarget(param1, iTarget))
				PrintToChat(param1, "\x03[WarnSystem] \x01%t", "warn_canttarget");
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
				PrintToChat(param1, "\x03[WarnSystem] \x01%t", "warn_notavailable");
			else if (!CanUserTarget(param1, iTarget))
				PrintToChat(param1, "\x03[WarnSystem] \x01%t", "warn_canttarget");
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
				PrintToChat(param1, "\x03[WarnSystem] \x01%t", "warn_notavailable");
			else if (!CanUserTarget(param1, iTarget))
				PrintToChat(param1, "\x03[WarnSystem] \x01%t", "warn_canttarget");
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
	SetMenuTitle(hMenu, "%T", "warn_warn_reasontitle", iClient);
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
	SetMenuTitle(hMenu, "%T", "warn_unwarn_reasontitle", iClient);
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
	SetMenuTitle(hMenu, "%T", "warn_resetwarn_reasontitle", iClient);
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
			WarnPlayer(param1, g_iTarget[param1], sInfo);
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
			UnWarnPlayer(param1, g_iTarget[param1], sInfo);
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
			ResetPlayerWarns(param1, g_iTarget[param1], sInfo);
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
	FormatEx(sTitle, sizeof(sTitle), "[WarnSystem] %T", "warn_agreement_title", iClient);
	FormatEx(sAgree, sizeof(sAgree), "%T", "warn_agreement_agree", iClient);
	
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
			PrintToChat(param1, "\x03[WarnSystem] \x01%t", "warn_agreement_message");
			SetEntityMoveType(param1, MOVETYPE_WALK);
		}
		case MenuAction_End:
		{
			CloseHandle(hMenu);
		}
	}
}