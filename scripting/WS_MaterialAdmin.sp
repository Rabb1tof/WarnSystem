#pragma semicolon 1
#include <WarnSystem>
#include <materialadmin>
#pragma newdecls required

bool g_bIsMAAvailable;

public Plugin myinfo = 
{
    name = "[WarnSystem] MaterialAdmin support",
    author = "vadrozh",
    description = "Module adds support of ma",
    version = "1.0",
    url = "hlmod.ru"
};

public void OnLibraryAdded(const char[] sName) {SetPluginDetection(sName, true);}

public void OnLibraryRemoved(const char[] sName){SetPluginDetection(sName, false);}

void SetPluginDetection(const char[] sName, bool bBool) {
	if (StrEqual(sName, "materialadmin"))
		g_bIsMAAvailable = bBool;
}

public Action WarnSystem_WarnPunishment(int iAdmin, int iClient, int iBanLenght, char sReason[64])
{
	if (g_bIsMAAvailable)
		MABanPlayer(iAdmin, iClient, MA_BAN_STEAM, iBanLenght, sReason);
	return Plugin_Stop;
}

public Action WarnSystem_WarnMaxPunishment(int iAdmin, int iClient, int iBanLenght, char sReason[64])
{
	if (g_bIsMAAvailable)
		MABanPlayer(iAdmin, iClient, MA_BAN_STEAM, iBanLenght, sReason);
	return Plugin_Stop;
}