public void InitializeCommands()
{
	RegAdminCmd("sm_warn", Command_WarnPlayer, WARNFLAG);
	RegAdminCmd("sm_unwarn", Command_UnWarnPlayer, UNWARNFLAG);
	RegAdminCmd("sm_checkwarn", Command_CheckWarnPlayer, CHECKWARNFLAG);
	RegAdminCmd("sm_resetwarn", Command_WarnReset, RESETWARNSFLAG);
}

public Action Command_WarnPlayer(int iClient, int iArgs)
{
	if (iArgs < 2)
	{
		ReplyToCommand(iClient, "%t %t", "WS_Prefix", "WS_WarnArguments");
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
		ReplyToCommand(iClient, "%t %t", "WS_Prefix", "WS_UnWarnArguments");
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
		ReplyToCommand(iClient, "%t %t", "WS_Prefix", "No Access");
		return Plugin_Handled;
	}
	if (iArgs < 2)
	{
		ReplyToCommand(iClient, "%t %t", "WS_Prefix", "WS_ResetWarnArguments");
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
		PrintToServer("%t %t", "WS_Prefix", "Command is in-game only");
		return Plugin_Handled;
	}
	if (!iArgs)
	{
		ReplyToCommand(iClient, "%t %t", "WS_Prefix", "WS_CheckWarnArguments");
		return Plugin_Handled;
	}
	char sArgument[32];
	GetCmdArg(1, sArgument, sizeof(sArgument));
	int iTarget = FindTarget(iClient, sArgument, true, true);
	CheckPlayerWarns(iClient, iTarget);
	return Plugin_Handled;
}