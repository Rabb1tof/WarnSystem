#pragma semicolon 1
#include <WarnSystem>
#include <sourcebans>
#include <materialadmin>
#pragma newdecls required

int g_iSbType;
ConVar g_cSbType;

public Plugin myinfo =
{
    name = "[WS] Sourcebans Support",
    author = "vadrozh, Rabb1t",
    description = "Module adds support of sb (all)",
    version = "1.1",
    url = "hlmod.ru"
};

public void OnPluginStart()
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
}

public void OnLibraryAdded(const char[] sName) {SetPluginDetection(sName);}

public void OnLibraryRemoved(const char[] sName){SetPluginDetection(sName);}

void SetPluginDetection(const char[] sName) {
    if (!StrEqual(sName, "sourcebans") || !StrEqual(sName, "materialadmin"))
        SetFailState("Can't find MaterialAdmin or SourceBans++ or SourceBans(Old).");
}

public Action WarnSystem_WarnPunishment(int iAdmin, int iClient, int iBanLenght, char sReason[129])
{
    switch(g_iSbType){
        case 1:     MABanPlayer(iAdmin, iClient, MA_BAN_STEAM, iBanLenght, sReason);
        case 2:     SourceBans_BanPlayer(iAdmin, iClient, iBanLenght, sReason);
        case 3:     SBBanPlayer(iAdmin, iClient, iBanLenght, sReason);
    }
    return Plugin_Handled;
}

public Action WarnSystem_WarnMaxPunishment(int iAdmin, int iClient, int iBanLenght, char sReason[129])
{
    switch(g_iSbType){
        case 1:     MABanPlayer(iAdmin, iClient, MA_BAN_STEAM, iBanLenght, sReason);
        case 2:     SourceBans_BanPlayer(iAdmin, iClient, iBanLenght, sReason);
        case 3:     SBBanPlayer(iAdmin, iClient, iBanLenght, sReason);
    }
    return Plugin_Handled;
}