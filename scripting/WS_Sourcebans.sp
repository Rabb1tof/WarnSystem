#pragma semicolon 1
#include <WarnSystem>

#if defined _sourcebans_included
	#tryinclude <sourcebans>
#endif

#if defined _materialadmin_included
	#tryinclude <materialadmin>
#endif
#pragma newdecls required

int g_iSbType;
//ConVar g_cSbType;

public Plugin myinfo =
{
	name = "[WarnSystem] Sourcebans support (all version)",
	author = "vadrozh, Rabb1t",
	description = "Module adds support of sb (all)",
	version = "1.1",
	url = "hlmod.ru"
};

/*public void OnPluginStart()
{
	g_cSbType = CreateConVar("sm_warnsystem_sb_support_type", "1", "1 - MaterialAdmin, 2 - SB++, 3 - SB(Old).", _, true, 1.0, true, 3.0);
	HookConVarChange(g_cSbType, OnCvarChanged);
	
	AutoExecConfig(true, "sourcebans_support", "warnsystem");
}

public void OnConfigsExecuted() {
	OnCvarChanged(g_cSbType, NULL_STRING, NULL_STRING);
}

public void OnCvarChanged(ConVar hCvar, const char[] szOV, const char[] szNV) {
	if(g_cSbType == hCvar) {
		g_iSbType = hCvar.IntValue;
		return;
	}
}*/

public void OnLibraryAdded(const char[] sName) {SetPluginDetection(sName);}

public void OnLibraryRemoved(const char[] sName){SetPluginDetection(sName);}

void SetPluginDetection(const char[] sName) {
    if (StrEqual(sName, "sourcebans"))
        g_iSbType = 2;
	else if(StrEqual(sName, "materialadmin"))
		g_iSbType = 1;
}

public Action WarnSystem_WarnPunishment(int iAdmin, int iClient, int iBanLenght, char sReason[129])
{
	switch(g_iSbType){
		#if defined _materialadmin_included
		case 1:     MABanPlayer(iAdmin, iClient, MA_BAN_STEAM, iBanLenght, sReason);
		#endif
		#if defined _sourcebans_included
		case 2:     SourceBans_BanPlayer(iAdmin, iClient, iBanLenght, sReason);
		//case 3:     SBBanPlayer(iAdmin, iClient, iBanLenght, sReason);
		#endif
	}
	
	return Plugin_Handled;
}

public Action WarnSystem_WarnMaxPunishment(int iAdmin, int iClient, int iBanLenght, char sReason[129])
{
	switch(g_iSbType){
		#if defined _materialadmin_included
		case 1:     MABanPlayer(iAdmin, iClient, MA_BAN_STEAM, iBanLenght, sReason);
		#endif
		#if defined _sourcebans_included
		case 2:     SourceBans_BanPlayer(iAdmin, iClient, iBanLenght, sReason);
		//case 3:     SBBanPlayer(iAdmin, iClient, iBanLenght, sReason);
		#endif
	}
	
	return Plugin_Handled;
}