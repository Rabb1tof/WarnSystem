#pragma semicolon 1
#include <sourcebans>
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <adminmenu>

char g_sPathWarnReasons[PLATFORM_MAX_PATH], g_sPathUnwarnReasons[PLATFORM_MAX_PATH],
	 g_sPathResetReasons[PLATFORM_MAX_PATH], g_sPathAgreePanel[PLATFORM_MAX_PATH], g_sLogPath[PLATFORM_MAX_PATH];
bool g_bUseSourcebans;

#include "WarnSystem/convars.sp"
#include "WarnSystem/database.sp"
#include "WarnSystem/api.sp"
#include "WarnSystem/commands.sp"
#include "WarnSystem/menus.sp"

public Plugin myinfo =
{
	name = "WarnSystem",
	author = "vadrozh",
	description = "Warn players when they are doing something wrong.",
	version = "1.0",
	url = "hlmod.ru"
};
	 
public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("WarnSystem.phrases");
	
	BuildPath(Path_SM, g_sPathWarnReasons, sizeof(g_sPathWarnReasons), "configs/WarnSystem/WarnReasons.cfg");
	BuildPath(Path_SM, g_sPathUnwarnReasons, sizeof(g_sPathUnwarnReasons), "configs/WarnSystem/UnwarnReasons.cfg");
	BuildPath(Path_SM, g_sPathResetReasons, sizeof(g_sPathResetReasons), "configs/WarnSystem/ResetWarnReasons.cfg");
	BuildPath(Path_SM, g_sPathAgreePanel, sizeof(g_sPathAgreePanel), "configs/WarnSystem/WarnAgreement.cfg");
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/WarnSystem.log");
	
	InitializeConVars();
	InitializeDatabase();
	InitializeCommands();
	
	Handle topmenu;
	if (LibraryExists("adminmenu") && (topmenu = GetAdminTopMenu()))
		InitializeMenu(topmenu);
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("sourcebans"))
		g_bUseSourcebans = true;
}

public void OnLibraryAdded(const char[] sName)
{
	if (!strcmp(sName, "sourcebans", false))
		g_bUseSourcebans = true;
}

public void OnLibraryRemoved(const char[] sName)
{
	if (strcmp(sName, "sourcebans", false))
		g_bUseSourcebans = false;
	if(strcmp(sName, "adminmenu", false))
		g_hAdminMenu = INVALID_HANDLE;
}

public void OnMapStart()
{
	if(g_bWarnSound)
		PrecacheSound(g_sWarnSoundPath, true);
}

public void OnAdminMenuReady(Handle topmenu) {InitializeMenu(topmenu);}

public void OnClientPostAdminCheck(int iClient)
{
	if(!IsFakeClient(iClient))
	{
		char sSteamID[32], dbQuery[64];
		GetClientAuthId(iClient, AuthId_Steam2, sSteamID, sizeof(sSteamID));
		FormatEx(dbQuery, sizeof(dbQuery),  "SELECT * FROM WarnSystem WHERE targetid='%s' AND expired != '1'", sSteamID);
		SQL_TQuery(g_hDatabase, SQL_CheckWarnings, dbQuery, iClient);
		Fwd_OnClientLoaded(iClient);
	}
}

public void PrintToAdmins(char[] sFormat, any ...)
{
	char sBuffer[255];
	for (int i = 1; i<=MaxClients; ++i)
	{
		if (CheckCommandAccess(i, "sm_warn_printtoadmins", ADMFLAG_BAN) && IsClientInGame(i))
		{
			VFormat(sBuffer, sizeof(sBuffer), sFormat, 2);
			PrintToChat(i, "%s", sBuffer);
		}
	}
}

public void LogWarnings(const char[] sFormat, any ...)
{
	char sBuffer[255];
	VFormat(sBuffer, sizeof(sBuffer), sFormat, 2);
	LogToFileEx(g_sLogPath, "%s", sBuffer);
}

public void WarnPlayer(int iClient, int iTarget, char sReason[64])
{
	if (iTarget && IsClientInGame(iTarget) && !IsFakeClient(iTarget))
	{
		char sTSteamID[32], dbQuery[128];
		GetClientAuthId(iTarget, AuthId_Steam2, sTSteamID, sizeof(sTSteamID));
		Handle hWarnData = CreateDataPack();
		WritePackCell(hWarnData, GetClientUserId(iTarget));
		WritePackString(hWarnData, sReason);
		ResetPack(hWarnData);
		FormatEx(dbQuery, sizeof(dbQuery),  "SELECT * FROM WarnSystem WHERE targetid='%s' AND expired != '1'", sTSteamID);
		SQL_TQuery(g_hDatabase, SQL_WarnPlayer, dbQuery, hWarnData);
		PrintToChatAll("\x03[WarnSystem] \x01", "%t", "warn_warnplayer", iClient, iTarget, sReason);
		if(g_bWarnSound)
			EmitSoundToClient(iTarget, g_sWarnSoundPath);
		Fwd_OnClientWarn(iClient, iTarget, sReason);
	}
}

public void UnWarnPlayer(int iClient, int iTarget, char sReason[64]){
	if (iTarget && IsClientInGame(iTarget) && !IsFakeClient(iTarget))
	{
		char sSteamID[32], dbQuery[128];
		GetClientAuthId(iTarget, AuthId_Steam2, sSteamID, sizeof(sSteamID));
		FormatEx(dbQuery, sizeof(dbQuery),  "SELECT * FROM WarnSystem WHERE targetid='%s' AND expired != '1' ORDER BY time DESC LIMIT 1", sSteamID);
		Handle hUnwarnData = CreateDataPack();
		if (iClient)
			WritePackCell(hUnwarnData, GetClientUserId(iClient));
		else
			WritePackCell(hUnwarnData, 0);
		WritePackCell(hUnwarnData, GetClientUserId(iTarget));
		WritePackString(hUnwarnData, sSteamID);
		WritePackString(hUnwarnData, sReason);
		ResetPack(hUnwarnData);
		SQL_TQuery(g_hDatabase, SQL_UnWarnPlayer, dbQuery, hUnwarnData);
	}
}

public void ResetPlayerWarns(int iClient, int iTarget, char sReason[64]){
	if (iTarget && IsClientInGame(iTarget) && !IsFakeClient(iTarget))
	{
		char sSteamID[32], dbQuery[128];
		GetClientAuthId(iTarget, AuthId_Steam2, sSteamID, sizeof(sSteamID));
		FormatEx(dbQuery, sizeof(dbQuery),  "SELECT * FROM WarnSystem WHERE targetid='%s'", sSteamID);
		Handle hResetWarnData = CreateDataPack(); 
		if (iClient)
			WritePackCell(hResetWarnData, GetClientUserId(iClient));
		else
			WritePackCell(hResetWarnData, 0);
		WritePackCell(hResetWarnData, GetClientUserId(iTarget));
		WritePackString(hResetWarnData, sSteamID);
		WritePackString(hResetWarnData, sReason);
		ResetPack(hResetWarnData);
		SQL_TQuery(g_hDatabase, SQL_ResetWarnPlayer, dbQuery, hResetWarnData);
	}
}

public void CheckPlayerWarns(int iClient, int iTarget){
	if (iTarget && IsClientInGame(iTarget) && !IsFakeClient(iTarget))
	{
		char sSteamID[32], dbQuery[128];
		GetClientAuthId(iTarget, AuthId_Steam2, sSteamID, sizeof(sSteamID));
		FormatEx(dbQuery, sizeof(dbQuery),  "SELECT * FROM WarnSystem WHERE targetid='%s'", sSteamID);
		Handle hCheckData = CreateDataPack(); 
		WritePackCell(hCheckData, GetClientUserId(iClient));
		WritePackCell(hCheckData, GetClientUserId(iTarget));
		ResetPack(hCheckData);
		SQL_TQuery(g_hDatabase, SQL_CheckPlayer, dbQuery, hCheckData);
	}
}

public void PunishPlayerOnMaxWarns(int iClient, char sReason[64])
{
	if (iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
		switch (g_iMaxPunishment)
		{
			case 1:
			{
				KickClient(iClient, "[WarnSystem] %t", "warn_max_kickonly");
			}
			case 2:
			{
				char sBanReason[64];
				FormatEx(sBanReason, sizeof(sBanReason), "[WarnSystem] %t", "warn_max_ban", sReason);
				if (g_bUseSourcebans)
					SBBanPlayer(0, iClient, g_iBanLenght, sBanReason);
				else
				{
					char sKickReason[64];
					FormatEx(sKickReason, sizeof(sKickReason), "[WarnSystem] %t", "warn_max_kick", sReason);
					BanClient(iClient, g_iBanLenght, BANFLAG_AUTO, sBanReason, sKickReason, "WarnSystem");
				}
			}
			default:
			{
				
			}
	}
}

public void PunishPlayer(int iClient, char sReason[64])
{
	if (iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
		switch (g_iPunishment)
		{
			case 1:
			{
				PrintToChat(iClient, "\x03[WarnSystem] \x01%t", "warn_message");
			}
			case 2:
			{
				SlapPlayer(iClient, g_iSlapDamage, true);
				PrintToChat(iClient, "[\x03[WarnSystem] \x01%t", "warn_message");
			}
			case 3:
			{
				ForcePlayerSuicide(iClient);
				PrintToChat(iClient, "\x03[WarnSystem] \x01%t", "warn_message");
			}
			case 4:
			{
				SetEntityMoveType(iClient, MOVETYPE_NONE);
				BuildAgreement(iClient);
				PrintToChat(iClient, "\x03[WarnSystem] \x01%t", "warn_message");
			}
			case 5:
			{
				char sKickReason[64];
				FormatEx(sKickReason, sizeof(sKickReason), "[WarnSystem] %t", "warn_punish_kick", sReason);
				KickClient(iClient, sKickReason);
			}
			case 6:
			{
				char sBanReason[64];
				FormatEx(sBanReason, sizeof(sBanReason), "[WarnSystem] %t", "warn_punish_ban", sReason);
				if (g_bUseSourcebans)
					SBBanPlayer(0, iClient, g_iBanLenght, sBanReason);
				else
				{
					char sKickReason[64];
					FormatEx(sKickReason, sizeof(sKickReason), "[WarnSystem] %t", "warn_punish_kickban", sReason);
					BanClient(iClient, g_iBanLenght, BANFLAG_AUTO, sBanReason, sKickReason, "WarnSystem");
				}
			}
			default:
			{
				
			}
		}
}