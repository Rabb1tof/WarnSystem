#pragma semicolon 1

#include <morecolors>

#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <sourcebans>
#tryinclude <materialadmin>
#define REQUIRE_EXTENSIONS
#define REQUIRE_PLUGIN

#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <adminmenu>

#define ADMINMENUFLAG 		ADMFLAG_BAN
#define WARNFLAG 			ADMFLAG_BAN
#define UNWARNFLAG 			ADMFLAG_UNBAN
#define RESETWARNSFLAG		ADMFLAG_UNBAN
#define CHECKWARNFLAG 		ADMFLAG_BAN
#define PRINTTOADMINSFLAG	ADMFLAG_BAN

char g_sPathWarnReasons[PLATFORM_MAX_PATH], g_sPathUnwarnReasons[PLATFORM_MAX_PATH],
	 g_sPathResetReasons[PLATFORM_MAX_PATH], g_sPathAgreePanel[PLATFORM_MAX_PATH], g_sLogPath[PLATFORM_MAX_PATH];

bool g_bUseSourcebans, g_bUseMaterialAdmin;

#include "WarnSystem/convars.sp"
#include "WarnSystem/database.sp"
#include "WarnSystem/api.sp"
#include "WarnSystem/commands.sp"
#include "WarnSystem/menus.sp"

public Plugin myinfo =
{
	name = "WarnSystem",
	author = "vadrozh, ecca",
	description = "Warn players when they are doing something wrong.",
	version = "1.0",
	url = "hlmod.ru"
};
	 
public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	LoadTranslations("WarnSystem.phrases");
	
	BuildPath(Path_SM, g_sPathWarnReasons, sizeof(g_sPathWarnReasons), "configs/WarnSystem/WarnReasons.cfg");
	BuildPath(Path_SM, g_sPathUnwarnReasons, sizeof(g_sPathUnwarnReasons), "configs/WarnSystem/UnWarnReasons.cfg");
	BuildPath(Path_SM, g_sPathResetReasons, sizeof(g_sPathResetReasons), "configs/WarnSystem/ResetWarnReasons.cfg");
	BuildPath(Path_SM, g_sPathAgreePanel, sizeof(g_sPathAgreePanel), "configs/WarnSystem/WarnAgreement.cfg");
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/WarnSystem.log");
	
	InitializeConVars();
	InitializeDatabase();
	InitializeCommands();
	
	Handle topmenu;
	if (LibraryExists("adminmenu") && (topmenu = GetAdminTopMenu()))
		InitializeMenu(topmenu);
	
	strcopy(g_sSteamID[0], 32, "CONSOLE");
	strcopy(g_sClientIP[0], 32, "localhost");
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("sourcebans"))
		g_bUseSourcebans = true;
	if (LibraryExists("materialadmin"))
		g_bUseMaterialAdmin = true;
}

public void OnLibraryAdded(const char[] sName)
{
	if (!strcmp(sName, "sourcebans", false))
		g_bUseSourcebans = true;
	if (!strcmp(sName, "materialadmin", false))
		g_bUseMaterialAdmin = true;
}

public void OnLibraryRemoved(const char[] sName)
{
	if (strcmp(sName, "sourcebans", false))
		g_bUseSourcebans = false;
	if (strcmp(sName, "materialadmin", false))
		g_bUseMaterialAdmin = false;
	if (strcmp(sName, "adminmenu", false))
		g_hAdminMenu = INVALID_HANDLE;
}

public void OnMapStart()
{
	if(g_bWarnSound)
		PrecacheSound(g_sWarnSoundPath, true);
}

public void OnAdminMenuReady(Handle topmenu) {InitializeMenu(topmenu);}

public void OnClientAuthorized(int iClient) {LoadPlayerData(iClient);}

public void PrintToAdmins(char[] sFormat, any ...)
{
	char sBuffer[255];
	for (int i = 1; i<=MaxClients; ++i)
	{
		if (IsClientInGame(i) && (GetUserFlagBits(i) & PRINTTOADMINSFLAG))
		{
			VFormat(sBuffer, sizeof(sBuffer), sFormat, 2);
			CPrintToChat(i, "%s", sBuffer);
		}
	}
}

public void LogWarnings(const char[] sFormat, any ...)
{
	char sBuffer[255];
	VFormat(sBuffer, sizeof(sBuffer), sFormat, 2);
	LogToFileEx(g_sLogPath, "%s", sBuffer);
}

public void PunishPlayerOnMaxWarns(int iClient, char sReason[64])
{
	if (iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
		switch (g_iMaxPunishment)
		{
			case 1:
			{
				KickClient(iClient, "%t %t", "WS_Prefix", "WS_MaxKick");
			}
			case 2:
			{
				char sBanReason[64];
				FormatEx(sBanReason, sizeof(sBanReason), "%t %t", "WS_Prefix", "WS_MaxBan", sReason);
				if (g_bUseSourcebans)
					SBBanPlayer(0, iClient, g_iBanLenght, sBanReason);
				else
					BanClient(iClient, g_iBanLenght, BANFLAG_AUTO, sBanReason, sBanReason, "WarnSystem");
			}
			default:
			{
				LogError("[WarnSystem] ConVar sm_warn_maxpunishment contains incorrect value(%i)", g_iMaxPunishment);
			}
	}
}

public void PunishPlayer(int iAdmin, int iClient, char sReason[64])
{
	if (iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
		switch (g_iPunishment)
		{
			case 1:
			{
				CPrintToChat(iClient, "%t %t", "WS_Prefix", "WS_Message");
			}
			case 2:
			{
				SlapPlayer(iClient, g_iSlapDamage, true);
				CPrintToChat(iClient, "%t %t", "WS_Prefix", "WS_Message");
			}
			case 3:
			{
				ForcePlayerSuicide(iClient);
				CPrintToChat(iClient, "%t %t", "WS_Prefix", "WS_Message");
			}
			case 4:
			{
				SetEntityMoveType(iClient, MOVETYPE_NONE);
				BuildAgreement(iClient);
				CPrintToChat(iClient, "%t %t", "WS_Prefix", "WS_Message");
			}
			case 5:
			{
				char sKickReason[64];
				FormatEx(sKickReason, sizeof(sKickReason), "%t %t", "WS_Prefix", "WS_PunishKick", sReason);
				KickClient(iClient, sKickReason);
			}
			case 6:
			{
				char sBanReason[64];
				FormatEx(sBanReason, sizeof(sBanReason), "%t %t", "WS_Prefix", "WS_PunishBan", sReason);
				if (g_bUseSourcebans)
					SBBanPlayer(iAdmin, iClient, g_iBanLenght, sBanReason);
				else if (g_bUseMaterialAdmin)
					MABanPlayer(iAdmin, iClient, MA_BAN_STEAM, g_iBanLenght, sBanReason);
				else
				{
					BanClient(iClient, g_iBanLenght, BANFLAG_AUTO, sBanReason, sBanReason, "WarnSystem");
				}
			}
			default:
			{
				LogError("[WarnSystem] ConVar sm_warn_punishment contains incorrect value(%i)", g_iMaxPunishment);
			}
		}
}