#pragma semicolon 1
#include <WarnSystem>
#include <sourcebans>
#pragma newdecls required

bool g_bIsSourcebansAvailable;

public Plugin myinfo = 
{
    name = "[WarnSystem] Sourcebans support",
    author = "vadrozh",
    description = "Module adds support of sb",
    version = "1.0",
    url = "hlmod.ru"
};

public void OnLibraryAdded(const char[] sName) {SetPluginDetection(sName, true);}

public void OnLibraryRemoved(const char[] sName){SetPluginDetection(sName, false);}

void SetPluginDetection(const char[] sName, bool bBool) {
	if (StrEqual(sName, "sourcebans"))
		g_bIsSourcebansAvailable = bBool;
}

public Action WarnSystem_WarnPunishment(int iAdmin, int iClient, int iBanLenght, char sReason[64])
{
	if (g_bIsSourcebansAvailable)
		SourceBans_BanPlayer(iAdmin, iClient, iBanLenght, sReason);
	return Plugin_Stop;
}

public Action WarnSystem_WarnMaxPunishment(int iAdmin, int iClient, int iBanLenght, char sReason[64])
{
	if (g_bIsSourcebansAvailable)
		SourceBans_BanPlayer(iAdmin, iClient, iBanLenght, sReason);
	return Plugin_Stop;
}