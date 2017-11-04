Handle g_hGFwd_OnClientLoaded;
Handle g_hGFwd_OnClientWarn;

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_Max)
{
	CreateNative("WarnSystem_Warn", Native_WarnPlayer);
	CreateNative("WarnSystem_UnWarn", Native_UnWarnPlayer);
	CreateNative("WarnSystem_ResetWarn", Native_ResetWarnPlayer);
	CreateNative("WarnSystem_GetDatabase", Native_GetDatabase);
	
	g_hGFwd_OnClientLoaded = CreateGlobalForward("Fwd_OnClientLoaded", ET_Ignore, Param_Cell);
	g_hGFwd_OnClientWarn = CreateGlobalForward("Fwd_OnClientWarn", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	
	MarkNativeAsOptional("SBBanPlayer");
	
	RegPluginLibrary("warnsystem");
	
	return APLRes_Success;
}

public int Native_GetDatabase(Handle hPlugin, int iNumParams) {return view_as<int>(CloneHandle(g_hDatabase, hPlugin));}

public int Native_WarnPlayer(Handle hPlugin, int iNumParams)
{
	int iLen;
	GetNativeStringLength(2, iLen);
	if (!iLen) return;
	int iClient = GetNativeCell(1);
	char sReason[64];
	GetNativeString(2, sReason, iLen);
	WarnPlayer(0, iClient, sReason);
}

public int Native_UnWarnPlayer(Handle hPlugin, int iNumParams)
{
	int iLen;
	GetNativeStringLength(2, iLen);
	if (!iLen) return;
	int iClient = GetNativeCell(1);
	char sReason[64];
	GetNativeString(2, sReason, iLen);
	UnWarnPlayer(0, iClient, sReason);
}

public int Native_ResetWarnPlayer(Handle hPlugin, int iNumParams)
{
	int iLen;
	GetNativeStringLength(2, iLen);
	if (!iLen) return;
	int iClient = GetNativeCell(1);
	char sReason[64];
	GetNativeString(2, sReason, iLen);
	ResetPlayerWarns(0, iClient, sReason);
}

void Fwd_OnClientLoaded(int iClient)
{
    Call_StartForward(g_hGFwd_OnClientLoaded);
    Call_PushCell(iClient);
    Call_Finish();
}

void Fwd_OnClientWarn(int iAdmin, int iClient, char sReason[64])
{
	Call_StartForward(g_hGFwd_OnClientWarn);
	Call_PushCell(iAdmin);
	Call_PushCell(iClient);
	Call_PushString(sReason);
	Call_Finish();
}