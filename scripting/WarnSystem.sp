#pragma semicolon 1
#include <colors>

#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <sourcebans>
#tryinclude <materialadmin>
#define REQUIRE_EXTENSIONS
#define REQUIRE_PLUGIN
//sb and ma not required for compile, but bans with this plugins w'll be unavailable

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
//Admin flags for features.

char g_sPathWarnReasons[PLATFORM_MAX_PATH], g_sPathUnwarnReasons[PLATFORM_MAX_PATH],
	 g_sPathResetReasons[PLATFORM_MAX_PATH], g_sPathAgreePanel[PLATFORM_MAX_PATH], g_sLogPath[PLATFORM_MAX_PATH];

bool g_bUseSourcebans, g_bUseMaterialAdmin, g_bIsCSGO;

Database g_hDatabase;

int g_iWarnings[MAXPLAYERS+1];

#define LogWarnings(%0) LogToFileEx(g_sLogPath, %0)

#include "WarnSystem/convars.sp"
#include "WarnSystem/api.sp"
#include "WarnSystem/database.sp"
#include "WarnSystem/commands.sp"
#include "WarnSystem/menus.sp"

public Plugin myinfo =
{
	name = "WarnSystem",
	author = "vadrozh, ecca",
	description = "Warn players when they are doing something wrong",
	version = "1.0",
	url = "hlmod.ru"
};

//----------------------------------------------------INITIALIZING---------------------------------------------------

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	LoadTranslations("WarnSystem.phrases");
	
	g_bIsCSGO = (GetEngineVersion() == Engine_CSGO);
	
	BuildPath(Path_SM, g_sPathWarnReasons, sizeof(g_sPathWarnReasons), "configs/WarnSystem/WarnReasons.cfg");
	BuildPath(Path_SM, g_sPathUnwarnReasons, sizeof(g_sPathUnwarnReasons), "configs/WarnSystem/UnWarnReasons.cfg");
	BuildPath(Path_SM, g_sPathResetReasons, sizeof(g_sPathResetReasons), "configs/WarnSystem/ResetWarnReasons.cfg");
	BuildPath(Path_SM, g_sPathAgreePanel, sizeof(g_sPathAgreePanel), "configs/WarnSystem/WarnAgreement.cfg");
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/WarnSystem.log");
	
	InitializeConVars();
	InitializeDatabase();
	InitializeCommands();
	
	Handle hAdminMenu;
	if (LibraryExists("adminmenu") && (hAdminMenu = GetAdminTopMenu()))
		InitializeMenu(hAdminMenu);
	
	strcopy(g_sClientIP[0], 32, "localhost");
	g_iAccountID[0] = -1;
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("sourcebans"))
		g_bUseSourcebans = true;
	if (LibraryExists("materialadmin"))
		g_bUseMaterialAdmin = true;
}

public void OnLibraryAdded(const char[] sName) {SetPluginDetection(sName, true);}

public void OnLibraryRemoved(const char[] sName){SetPluginDetection(sName, false);}

void SetPluginDetection(const char[] sName, bool bBool) {
	if (StrEqual(sName, "sourcebans"))
		g_bUseSourcebans = bBool;
	if (StrEqual(sName, "materialadmin"))
		g_bUseMaterialAdmin = bBool;
	if (StrEqual(sName, "adminmenu") && !bBool)
		g_hAdminMenu = INVALID_HANDLE;
}

public void OnMapStart()
{
	if(g_bWarnSound)
	{
		char sBuffer[PLATFORM_MAX_PATH];
		FormatEx(sBuffer, sizeof(sBuffer), "sound/%s", g_sWarnSoundPath);
		if(FileExists(sBuffer, true) || FileExists(sBuffer))
		{
			AddFileToDownloadsTable(sBuffer);
			if(g_bIsCSGO)
			{
				FormatEx(sBuffer, sizeof(sBuffer), "*/%s", g_sWarnSoundPath);
				AddToStringTable(FindStringTable("soundprecache"), sBuffer);
			}
			else
				PrecacheSound(g_sWarnSoundPath, true);
		}
	}
}

public void OnAdminMenuReady(Handle topmenu) {InitializeMenu(topmenu);}

public void OnClientAuthorized(int iClient) {LoadPlayerData(iClient);}

//----------------------------------------------------SOME FEATURES---------------------------------------------------

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

//----------------------------------------------------PUNISHMENTS---------------------------------------------------

public void PunishPlayerOnMaxWarns(int iClient, char sReason[64])
{
	if (iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
		switch (g_iMaxPunishment)
		{
			case 1:
				KickClient(iClient, " %t %t", "WS_Prefix", "WS_MaxKick");
			case 2:
			{
				char sBanReason[64];
				FormatEx(sBanReason, sizeof(sBanReason), " %t %t", "WS_Prefix", "WS_MaxBan", sReason);
				if (g_bUseSourcebans)
					SBBanPlayer(0, iClient, g_iBanLenght, sBanReason);
				else
					BanClient(iClient, g_iBanLenght, BANFLAG_AUTO, sBanReason, sBanReason, "WarnSystem");
			}
			//case 3:
			//I'll be add support of modules with punishments
	}
}

public void PunishPlayer(int iAdmin, int iClient, char sReason[64])
{
	if (iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
		switch (g_iPunishment)
		{
			case 1:
				CPrintToChat(iClient, " %t %t", "WS_Prefix", "WS_Message");
			case 2:
			{
				if (IsPlayerAlive(iClient))
					SlapPlayer(iClient, g_iSlapDamage, true);
				CPrintToChat(iClient, " %t %t", "WS_Prefix", "WS_Message");
			}
			case 3:
			{
				if (IsPlayerAlive(iClient))
					ForcePlayerSuicide(iClient);
				CPrintToChat(iClient, " %t %t", "WS_Prefix", "WS_Message");
			}
			case 4:
			{
				if (IsPlayerAlive(iClient))
					SetEntityMoveType(iClient, MOVETYPE_NONE);
				BuildAgreement(iClient);
				CPrintToChat(iClient, " %t %t", "WS_Prefix", "WS_Message");
			}
			case 5:
			{
				char sKickReason[64];
				FormatEx(sKickReason, sizeof(sKickReason), " %t %t", "WS_Prefix", "WS_PunishKick", sReason);
				KickClient(iClient, sKickReason);
			}
			case 6:
			{
				char sBanReason[64];
				FormatEx(sBanReason, sizeof(sBanReason), " %t %t", "WS_Prefix", "WS_PunishBan", sReason);
				if (g_bUseSourcebans)
					SBBanPlayer(iAdmin, iClient, g_iBanLenght, sBanReason);
				else if (g_bUseMaterialAdmin)
					MABanPlayer(iAdmin, iClient, MA_BAN_STEAM, g_iBanLenght, sBanReason);
				else
					BanClient(iClient, g_iBanLenght, BANFLAG_AUTO, sBanReason, sBanReason, "WarnSystem");
			}
			//case 7:
			//I'll be add support of modules with punishments
		}
}