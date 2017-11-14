Handle g_hGFwd_OnClientLoaded, g_hGFwd_OnClientWarn, g_hGFwd_OnClientUnWarn, g_hGFwd_OnClientResetWarns;
bool g_bIsLateLoad;

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_Max)
{
	CreateNative("WarnSystem_Warn", Native_WarnPlayer);
	CreateNative("WarnSystem_UnWarn", Native_UnWarnPlayer);
	CreateNative("WarnSystem_ResetWarn", Native_ResetWarnPlayer);
	CreateNative("WarnSystem_GetDatabase", Native_GetDatabase);
	CreateNative("WarnSystem_GetPlayerWarns", Native_GetPlayerWarns);
	CreateNative("WarnSystem_PrintToAdmins", Native_PrintToAdmins);
	
	g_hGFwd_OnClientLoaded = CreateGlobalForward("WarnSystem_OnClientLoaded", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hGFwd_OnClientWarn = CreateGlobalForward("WarnSystem_OnClientWarn", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	g_hGFwd_OnClientUnWarn = CreateGlobalForward("WarnSystem_OnClientUnWarn", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	g_hGFwd_OnClientResetWarns = CreateGlobalForward("WarnSystem_OnClientResetWarns", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	
	MarkNativeAsOptional("SBBanPlayer");
	MarkNativeAsOptional("MABanPlayer");
	
	RegPluginLibrary("warnsystem");
	
	g_bIsLateLoad = bLate;
	
	return APLRes_Success;
}

public int Native_PrintToAdmins(Handle hPlugin, int iNumParams)
{
	char sMessage[256];
	GetNativeString(1, sMessage, sizeof(sMessage));
	PrintToAdmins(sMessage);
}

public int Native_GetDatabase(Handle hPlugin, int iNumParams) {return view_as<int>(CloneHandle(g_hDatabase, hPlugin));}

public int Native_GetPlayerWarns(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	return g_iWarnings[iClient];
}

public int Native_WarnPlayer(Handle hPlugin, int iNumParams)
{
	int iAdmin = GetNativeCell(1);
	int iClient = GetNativeCell(2);
	char sReason[64];
	GetNativeString(3, sReason, sizeof(sReason));
	if (0<iClient<=MaxClients && IsClientInGame(iClient) && !IsFakeClient(iClient) && -1<iAdmin<=MaxClients)
		WarnPlayer(iAdmin, iClient, sReason);
	else
		ThrowNativeError(1, "Native_WarnPlayer: Client or admin index is invalid.");
}

public int Native_UnWarnPlayer(Handle hPlugin, int iNumParams)
{
	int iAdmin = GetNativeCell(1);
	int iClient = GetNativeCell(2);
	char sReason[64];
	GetNativeString(3, sReason, sizeof(sReason));
	if (0<iClient<=MaxClients && IsClientInGame(iClient) && !IsFakeClient(iClient) && -1<iAdmin<=MaxClients)
		UnWarnPlayer(iAdmin, iClient, sReason);
	else
		ThrowNativeError(2, "Native_UnWarnPlayer: Client or admin index is invalid.");
}

public int Native_ResetWarnPlayer(Handle hPlugin, int iNumParams)
{
	int iAdmin = GetNativeCell(1);
	int iClient = GetNativeCell(2);
	char sReason[64];
	GetNativeString(3, sReason, sizeof(sReason));
	if (0<iClient<=MaxClients && IsClientInGame(iClient) && !IsFakeClient(iClient) && -1<iAdmin<=MaxClients)
		ResetPlayerWarns(iAdmin, iClient, sReason);
	else
		ThrowNativeError(3, "Native_ResetWarnPlayer: Client or admin index is invalid.");
}

void WarnSystem_OnClientLoaded(int iClient)
{
	Call_StartForward(g_hGFwd_OnClientLoaded);
	Call_PushCell(iClient);
	Call_PushCell(g_iWarnings[iClient]);
	Call_PushCell(g_iMaxWarns);
	Call_Finish();
}

void WarnSystem_OnClientWarn(int iAdmin, int iClient, char sReason[64])
{
	Call_StartForward(g_hGFwd_OnClientWarn);
	Call_PushCell(iAdmin);
	Call_PushCell(iClient);
	Call_PushString(sReason);
	Call_Finish();
}

void WarnSystem_OnClientUnWarn(int iAdmin, int iClient, char sReason[64])
{
	Call_StartForward(g_hGFwd_OnClientUnWarn);
	Call_PushCell(iAdmin);
	Call_PushCell(iClient);
	Call_PushString(sReason);
	Call_Finish();
}

void WarnSystem_OnClientResetWarns(int iAdmin, int iClient, char sReason[64])
{
	Call_StartForward(g_hGFwd_OnClientResetWarns);
	Call_PushCell(iAdmin);
	Call_PushCell(iClient);
	Call_PushString(sReason);
	Call_Finish();
}