public void InitializeCommands()
{
	RegConsoleCmd("sm_warn", Command_WarnPlayer);
	RegConsoleCmd("sm_unwarn", Command_UnWarnPlayer);
	RegConsoleCmd("sm_checkwarn", Command_CheckWarnPlayer);
	RegConsoleCmd("sm_resetwarn", Command_WarnReset);
}

public Action Command_WarnPlayer(int iClient, int iArgs)
{
	if(GetUserFlagBits(iClient) || VIP_GetClientFeatureStatus(iClient, "Warns") == ENABLED)
	{
		if (iArgs < 2)
		{
			ReplyToCommand(iClient, " %t %t", "WS_Prefix", "WS_WarnArguments");
			return Plugin_Handled;
		}
		char sBuffer[128], sReason[129];
		GetCmdArg(1, sBuffer, sizeof(sBuffer));
		int iTarget = FindTarget(iClient, sBuffer, true, true);
		if (!iTarget)
			return Plugin_Handled;
		
		GetCmdArg(2, sReason, sizeof(sReason));
		if (iArgs > 2)
			for (int i = 3; i <= iArgs; ++i)
			{
				GetCmdArg(i, sBuffer, sizeof(sBuffer));
				Format(sReason, sizeof(sReason), "%s %s", sReason, sBuffer);
			}
		
		WarnPlayer(iClient, iTarget, sReason);
		return Plugin_Handled;
	} 	return Plugin_Continue;
}

public Action Command_UnWarnPlayer(int iClient, int iArgs)
{
	if(GetUserFlagBits(iClient) || VIP_GetClientFeatureStatus(iClient, "Unwarns") == ENABLED)
	{
		if (iArgs < 2)
		{
			ReplyToCommand(iClient, " %t %t", "WS_Prefix", "WS_UnWarnArguments");
			return Plugin_Handled;
		}
		char sBuffer[128], sReason[129];
		GetCmdArg(1, sBuffer, sizeof(sBuffer));
		int iTarget = FindTarget(iClient, sBuffer, true, true);
		if (!iTarget)
			return Plugin_Handled;
		
		GetCmdArg(2, sReason, sizeof(sReason));
		if (iArgs > 2)
			for (int i = 3; i <= iArgs; ++i)
			{
				GetCmdArg(i, sBuffer, sizeof(sBuffer));
				Format(sReason, sizeof(sReason), "%s %s", sReason, sBuffer);
			}
		
		UnWarnPlayer(iClient, iTarget, sReason);
		return Plugin_Handled;
	} 	return Plugin_Continue;
}

public Action Command_WarnReset(int iClient, int iArgs)
{
	if(GetUserFlagBits(iClient) || VIP_GetClientFeatureStatus(iClient, "Resetwarns") == ENABLED)
	{
		if(!g_bResetWarnings)
		{
			ReplyToCommand(iClient, " %t %t", "WS_Prefix", "No Access");
			return Plugin_Handled;
		}
		if (iArgs < 2)
		{
			ReplyToCommand(iClient, " %t %t", "WS_Prefix", "WS_ResetWarnArguments");
			return Plugin_Handled;
		}
		char sBuffer[128], sReason[129];
		GetCmdArg(1, sBuffer, sizeof(sBuffer));
		int iTarget = FindTarget(iClient, sBuffer, true, true);
		if (!iTarget)
			return Plugin_Handled;
		
		GetCmdArg(2, sReason, sizeof(sReason));
		if (iArgs > 2)
			for (int i = 3; i <= iArgs; ++i)
			{
				GetCmdArg(i, sBuffer, sizeof(sBuffer));
				Format(sReason, sizeof(sReason), "%s %s", sReason, sBuffer);
			}
		
		ResetPlayerWarns(iClient, iTarget, sReason);
		return Plugin_Handled;
	} return Plugin_Continue;
}

public Action Command_CheckWarnPlayer(int iClient, int iArgs)
{
	if (!iClient)
	{
		PrintToServer(" %t %t", "WS_Prefix", "Command is in-game only");
		return Plugin_Handled;
	}
	if (!iArgs)
	{
		ReplyToCommand(iClient, " %t %t", "WS_Prefix", "WS_CheckWarnArguments");
		return Plugin_Handled;
	}
	char sBuffer[128];
	GetCmdArg(1, sBuffer, sizeof(sBuffer));
	int iTarget = FindTarget(iClient, sBuffer, true, true);
	if (!iTarget)
		return Plugin_Handled;
	CheckPlayerWarns(iClient, iTarget);
	return Plugin_Handled;
}