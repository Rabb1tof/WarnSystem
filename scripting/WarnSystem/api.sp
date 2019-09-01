Handle g_hGFwd_OnClientLoaded, g_hGFwd_OnClientWarn, g_hGFwd_OnClientUnWarn, g_hGFwd_OnClientResetWarns,
		g_hGFwd_WarnPunishment, g_hGFwd_WarnMaxPunishment, g_hGFwd_OnClientWarn_Pre, g_hGFwd_OnClientUnWarn_Pre, 
		g_hGFwd_OnClientResetWarns_Pre;
bool g_bIsLateLoad;

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_Max)
{
	CreateNative("WarnSystem_Warn", Native_WarnPlayer);
	CreateNative("WarnSystem_UnWarn", Native_UnWarnPlayer);
	CreateNative("WarnSystem_ResetWarn", Native_ResetWarnPlayer);
	CreateNative("WarnSystem_GetDatabase", Native_GetDatabase);
	CreateNative("WarnSystem_GetPlayerWarns", Native_GetPlayerWarns);
	CreateNative("WarnSystem_PrintToAdmins", Native_PrintToAdmins);
	CreateNative("WarnSystem_GetMaxWarns", Native_GetMaxWarns);
	CreateNative("WarnSystem_StartSelectReason", Native_StartSelectReason);
	
	g_hGFwd_OnClientLoaded = CreateGlobalForward("WarnSystem_OnClientLoaded", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hGFwd_OnClientWarn = CreateGlobalForward("WarnSystem_OnClientWarn", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	g_hGFwd_OnClientUnWarn = CreateGlobalForward("WarnSystem_OnClientUnWarn", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	g_hGFwd_OnClientResetWarns = CreateGlobalForward("WarnSystem_OnClientResetWarns", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	g_hGFwd_OnClientWarn_Pre = CreateGlobalForward("WarnSystem_OnClientWarnPre", ET_Hook, Param_Cell, Param_Cell, Param_String);
	g_hGFwd_OnClientUnWarn_Pre = CreateGlobalForward("WarnSystem_OnClientUnWarnPre", ET_Hook, Param_Cell, Param_Cell, Param_String);
	g_hGFwd_OnClientResetWarns_Pre = CreateGlobalForward("WarnSystem_OnClientResetWarnsPre", ET_Hook, Param_Cell, Param_Cell, Param_String);
	g_hGFwd_WarnPunishment = CreateGlobalForward("WarnSystem_WarnPunishment", ET_Hook, Param_Cell, Param_Cell, Param_Cell, Param_String);
	g_hGFwd_WarnMaxPunishment = CreateGlobalForward("WarnSystem_WarnMaxPunishment", ET_Hook, Param_Cell, Param_Cell, Param_Cell, Param_String);
	
	RegPluginLibrary("WarnSystem");
	
	g_bIsLateLoad = bLate;
	
	return APLRes_Success;
}

public int Native_WarnPlayer(Handle hPlugin, int iNumParams)
{
	int iAdmin = GetNativeCell(1);
	int iClient = GetNativeCell(2);
	char sReason[129];
	GetNativeString(3, sReason, sizeof(sReason));
	if (IsValidClient(iClient) && -1<iAdmin<=MaxClients)
		WarnPlayer(iAdmin, iClient, sReason);
	else
		ThrowNativeError(1, "Native_WarnPlayer: Client or admin index is invalid.");
}

public int Native_UnWarnPlayer(Handle hPlugin, int iNumParams)
{
	int iAdmin = GetNativeCell(1);
	int iClient = GetNativeCell(2);
	char sReason[129];
	GetNativeString(3, sReason, sizeof(sReason));
	if (IsValidClient(iClient) && -1<iAdmin<=MaxClients)
		UnWarnPlayer(iAdmin, iClient, sReason);
	else
		ThrowNativeError(2, "Native_UnWarnPlayer: Client or admin index is invalid.");
}

public int Native_ResetWarnPlayer(Handle hPlugin, int iNumParams)
{
	int iAdmin = GetNativeCell(1);
	int iClient = GetNativeCell(2);
	char sReason[129];
	GetNativeString(3, sReason, sizeof(sReason));
	if (IsValidClient(iClient) && -1<iAdmin<=MaxClients)
		ResetPlayerWarns(iAdmin, iClient, sReason);
	else
		ThrowNativeError(3, "Native_ResetWarnPlayer: Client or admin index is invalid.");
}

public int Native_GetDatabase(Handle hPlugin, int iNumParams) {return view_as<int>(CloneHandle(g_hDatabase, hPlugin));}

public int Native_GetPlayerWarns(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	return g_iWarnings[iClient];
}

public int Native_GetMaxWarns(Handle hPlugin, int iNumParams){return g_iMaxWarns;}

public int Native_PrintToAdmins(Handle hPlugin, int iNumParams)
{
	char sMessage[256];
	GetNativeString(1, sMessage, sizeof(sMessage));
	PrintToAdmins("%s", sMessage);
}

void WarnSystem_OnClientLoaded(int iClient)
{
	Call_StartForward(g_hGFwd_OnClientLoaded);
	Call_PushCell(iClient);
	Call_PushCell(g_iWarnings[iClient]);
	Call_PushCell(g_iMaxWarns);
	Call_Finish();
}

void WarnSystem_OnClientWarn(int iAdmin, int iClient, char sReason[129])
{
	Call_StartForward(g_hGFwd_OnClientWarn);
	Call_PushCell(iAdmin);
	Call_PushCell(iClient);
	Call_PushString(sReason);
	Call_Finish();
}

void WarnSystem_OnClientUnWarn(int iAdmin, int iClient, char sReason[129])
{
	Call_StartForward(g_hGFwd_OnClientUnWarn);
	Call_PushCell(iAdmin);
	Call_PushCell(iClient);
	Call_PushString(sReason);
	Call_Finish();
}

void WarnSystem_OnClientResetWarns(int iAdmin, int iClient, char sReason[129])
{
	Call_StartForward(g_hGFwd_OnClientResetWarns);
	Call_PushCell(iAdmin);
	Call_PushCell(iClient);
	Call_PushString(sReason);
	Call_Finish();
}

Action WarnSystem_OnClientWarnPre(int iAdmin, int iClient, char sReason[129])
{
	Action act = Plugin_Continue;
	Call_StartForward(g_hGFwd_OnClientWarn_Pre);
	Call_PushCell(iAdmin);
	Call_PushCell(iClient);
	Call_PushString(sReason);
	Call_Finish(act);
	return act;
}

Action WarnSystem_OnClientUnWarnPre(int iAdmin, int iClient, char sReason[129])
{
	Action act = Plugin_Continue;
	Call_StartForward(g_hGFwd_OnClientUnWarn_Pre);
	Call_PushCell(iAdmin);
	Call_PushCell(iClient);
	Call_PushString(sReason);
	Call_Finish(act);
	return act;
}

Action WarnSystem_OnClientResetWarnsPre(int iAdmin, int iClient, char sReason[129])
{
	Action act = Plugin_Continue;
	Call_StartForward(g_hGFwd_OnClientResetWarns_Pre);
	Call_PushCell(iAdmin);
	Call_PushCell(iClient);
	Call_PushString(sReason);
	Call_Finish(act);
	return act;
}

Action WarnSystem_WarnPunishment(int iAdmin, int iClient, int iBanLenght,  char sReason[129])
{
	Action act = Plugin_Continue;
	Call_StartForward(g_hGFwd_WarnPunishment);
	Call_PushCell(iAdmin);
	Call_PushCell(iClient);
	Call_PushCell(iBanLenght);
	Call_PushString(sReason);
	Call_Finish(act);
	return act;
}

Action WarnSystem_WarnMaxPunishment(int iAdmin, int iClient, int iBanLenght, char sReason[129])
{
	Action act = Plugin_Continue;
	Call_StartForward(g_hGFwd_WarnMaxPunishment);
	Call_PushCell(iAdmin);
	Call_PushCell(iClient);
	Call_PushCell(iBanLenght);
	Call_PushString(sReason);
	Call_Finish(act);
	return act;
}

typedef ReasonSelectedHandler = function void(int iClient, const char[] szReason, int iType);

//void Native_StartSelectReason(int iClient, ReasonSelectedHandler ptrHandler, int iType = 0)
public int Native_StartSelectReason(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iVictim = GetNativeCell(2);
	Function ptrHandler = GetNativeFunction(3);
	int iType = GetNativeCell(4);
	DataPack hPack = new DataPack();
	hPack.WriteCell(hPlugin);
	hPack.WriteFunction(ptrHandler);
	hPack.WriteCell(iType);
	hPack.WriteCell(iVictim);

	#define NONE 		0
	#define WARN 		1
	#define UNWARN 		2
	#define RESETWARN  	3
	#define UNKNOWN 	4

	if(iType <= NONE && iType >= UNKNOWN) {
		hPack.Close();
		ThrowNativeError(SP_ERROR_PARAM, "[WarnSystem] 3th parameter (iType) is invalid! Check WarnSystem.inc.");
	}
	switch(iType)
	{
		case WARN: {
			DisplayWarnReasons(iClient, hPack);
		}
		case UNWARN: {
			DisplayUnWarnReasons(iClient, hPack);
		}
		case RESETWARN: {
			DisplayResetWarnReasons(iClient, hPack);
		}
	}
	#undef NONE 	
	#undef WARN 
	#undef UNWARN 	
	#undef RESETWARN
	#undef UNKNOWN
}