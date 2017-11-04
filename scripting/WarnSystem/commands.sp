public void InitializeCommands()
{
	RegAdminCmd("sm_warn", Command_WarnPlayer, ADMFLAG_BAN);
	RegAdminCmd("sm_unwarn", Command_UnWarnPlayer, ADMFLAG_BAN);
	RegAdminCmd("sm_checkwarn", Command_CheckWarnPlayer, ADMFLAG_BAN);
	RegAdminCmd("sm_resetwarn", Command_WarnReset, ADMFLAG_BAN);
	RegConsoleCmd("sm_warns", Command_Warns);
}

public Action Command_WarnPlayer(int iClient, int iArgs)
{
	if (iArgs < 2)
	{
		ReplyToCommand(iClient, "\x03[WarnSystem] \x01%t", "warn_arguments");
		return Plugin_Handled;
	}
	char sArgument[32], sReason[64], sBuffer[64];
	GetCmdArg(1, sArgument, sizeof(sArgument));
	for(int i = 2; i <= iArgs; ++i)
	{
		GetCmdArg(i, sBuffer, sizeof(sBuffer));
		Format(sReason, sizeof(sReason), "%s %s", sReason, sBuffer);
	}
	int iTarget = FindTarget(iClient, sArgument, true, true);
	WarnPlayer(iClient, iTarget, sReason);
	return Plugin_Handled;
}

public Action Command_UnWarnPlayer(int iClient, int iArgs)
{
	if (iArgs < 2)
	{
		ReplyToCommand(iClient, "\x03[WarnSystem] \x01%t", "warn_arguments2");
		return Plugin_Handled;
	}
	char sArgument[32], sReason[64], sBuffer[64];
	GetCmdArg(1, sArgument, sizeof(sArgument));
	for(int i = 2; i <= iArgs; ++i)
	{
		GetCmdArg(i, sBuffer, sizeof(sBuffer));
		Format(sReason, sizeof(sReason), "%s %s", sReason, sBuffer);
	}
	int iTarget = FindTarget(iClient, sArgument, true, true);
	UnWarnPlayer(iClient, iTarget, sReason);
	return Plugin_Handled;
}

public Action Command_WarnReset(int iClient, int iArgs)
{
	if(!g_bResetWarnings)
	{
		ReplyToCommand(iClient, "\x03[WarnSystem] \x01You don't have access to this command");
		return Plugin_Handled;
	}
	if (iArgs < 2)
	{
		ReplyToCommand(iClient, "\x03[WarnSystem] \x01%t", "warn_arguments4");
		return Plugin_Handled;
	}
	char sArgument[32], sReason[64], sBuffer[64];
	GetCmdArg(1, sArgument, sizeof(sArgument));
	for(int i = 2; i <= iArgs; ++i)
	{
		GetCmdArg(i, sBuffer, sizeof(sBuffer));
		Format(sReason, sizeof(sReason), "%s %s", sReason, sBuffer);
	}
	int iTarget = FindTarget(iClient, sArgument, true, true);
	ResetPlayerWarns(iClient, iTarget, sReason);
	return Plugin_Handled;
}

public Action Command_CheckWarnPlayer(int iClient, int iArgs)
{
	if (!iClient)
	{
		PrintToServer("[WarnSystem] In-game command only!");
		return Plugin_Handled;
	}
	if (!iArgs)
	{
		ReplyToCommand(iClient, "\x03[WarnSystem] \x01%t", "warn_arguments3");
		return Plugin_Handled;
	}
	char sArgument[32];
	GetCmdArg(1, sArgument, sizeof(sArgument));
	int iTarget = FindTarget(iClient, sArgument, true, true);
	CheckPlayerWarns(iClient, iTarget);
	return Plugin_Handled;
}

public Action Command_Warns(int iClient, int iArgs)
{
	if (!iClient)
	{
		PrintToServer("[WarnSystem] In-game command only!");
		return Plugin_Handled;
	}
	if (!iArgs)
	{
		ReplyToCommand(iClient, "\x03[WarnSystem] \x01%t", "warn_arguments3");
		return Plugin_Handled;
	}
	char sArgument[32];
	GetCmdArg(1, sArgument, sizeof(sArgument));
	int iTarget = FindTarget(iClient, sArgument, true, true);
	PrintToChat(iClient, "%t", g_iWarnings[iTarget]);
	return Plugin_Handled;
}