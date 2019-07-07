//---------------------------------DEFINES--------------------------------
#pragma semicolon 1

#define PLUGIN_NAME         "[WarnSystem] Core"
#define PLUGIN_AUTHOR       "vadrozh, Rabb1t"
#define PLUGIN_VERSION      "1.4.2"
#define PLUGIN_DESCRIPTION  "Warn players when they're doing something wrong"
#define PLUGIN_URL          "hlmod.ru/threads/warnsystem.42835/"

#define PLUGIN_BUILDDATE    __DATE__ ... " " ... __TIME__
#define PLUGIN_COMPILEDBY   SOURCEMOD_V_MAJOR ... "." ... SOURCEMOD_V_MINOR ... "." ... SOURCEMOD_V_RELEASE

#include <colors>
#include <sdktools_sound>
#include <sdktools_stringtables>
#include <sdktools_functions>
#include <dbi>
#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <adminmenu>
#tryinclude <vip_core>
#tryinclude <SteamWorks>
#define REQUIRE_PLUGINS
#define REQUIRE_EXTENSIONS

//----------------------------------------------------------------------------

char g_sPathWarnReasons[PLATFORM_MAX_PATH], g_sPathUnwarnReasons[PLATFORM_MAX_PATH],
	 g_sPathResetReasons[PLATFORM_MAX_PATH], g_sPathAgreePanel[PLATFORM_MAX_PATH], g_sLogPath[PLATFORM_MAX_PATH], g_szQueryPath[PLATFORM_MAX_PATH], g_sAddress[64];

bool g_bIsFuckingGame;

Database g_hDatabase;

int g_iWarnings[MAXPLAYERS+1], g_iPrintToAdminsOverride, g_iUserID[MAXPLAYERS+1], g_iPort;

#define LogWarnings(%0) LogToFileEx(g_sLogPath, %0)
#define LogQuery(%0)    LogToFileEx(g_szQueryPath, %0)

#if defined _SteamWorks_Included
#include "WarnSystem/stats.sp"
#endif 

#pragma newdecls required



#include "WarnSystem/convars.sp"
#include "WarnSystem/api.sp"
#include "WarnSystem/database.sp"
#include "WarnSystem/commands.sp"
#include "WarnSystem/menus.sp"

public Plugin myinfo =
{
	name = 			PLUGIN_NAME,
	author = 		PLUGIN_AUTHOR,
	description = 	PLUGIN_DESCRIPTION,
	version = 		PLUGIN_VERSION,
	url = 			PLUGIN_URL
};

//----------------------------------------------------INITIALIZING---------------------------------------------------

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	LoadTranslations("warnsystem.phrases");
	
	switch (GetEngineVersion()) {case Engine_CSGO, Engine_Left4Dead, Engine_Left4Dead2: g_bIsFuckingGame = true;}
	
	BuildPath(Path_SM, g_sPathWarnReasons, sizeof(g_sPathWarnReasons), "configs/WarnSystem/WarnReasons.cfg");
	BuildPath(Path_SM, g_sPathUnwarnReasons, sizeof(g_sPathUnwarnReasons), "configs/WarnSystem/UnWarnReasons.cfg");
	BuildPath(Path_SM, g_sPathResetReasons, sizeof(g_sPathResetReasons), "configs/WarnSystem/ResetWarnReasons.cfg");
	BuildPath(Path_SM, g_sPathAgreePanel, sizeof(g_sPathAgreePanel), "configs/WarnSystem/WarnAgreement.cfg");
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/WarnSystem");
	if(!DirExists(g_sLogPath))
		CreateDirectory(g_sLogPath, 511);
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/WarnSystem/WarnSystem.log");
	BuildPath(Path_SM, g_szQueryPath, sizeof(g_szQueryPath), "logs/WarnSystem/WarnSystem_Query.log");
	
	InitializeConVars();
	InitializeDatabase();
	InitializeCommands();
	
	#if defined _SteamWorks_Included
	// Stats work
	if (LibraryExists("SteamWorks"))
		SteamWorks_SteamServersConnected();
	#endif
	
	if (LibraryExists("adminmenu"))
	{
		Handle hAdminMenu;
		if ((hAdminMenu = GetAdminTopMenu()))
			InitializeMenu(hAdminMenu);
	}
	
	GetIPServer();
	GetPort();
		
	strcopy(g_sClientIP[0], 65, "localhost");
	g_iAccountID[0] = -1;
	
	if (!GetCommandOverride("sm_warn", Override_Command, g_iPrintToAdminsOverride))
		g_iPrintToAdminsOverride = ADMFLAG_GENERIC;
}

public void OnLibraryAdded(const char[] sName)
{
	Handle hAdminMenu;
	if (StrEqual(sName, "adminmenu"))
		if ((hAdminMenu = GetAdminTopMenu()))
			InitializeMenu(hAdminMenu);
}

public void OnLibraryRemoved(const char[] sName)
{
	if (StrEqual(sName, "adminmenu"))
		g_hAdminMenu = INVALID_HANDLE;
}

public void OnMapStart()
{
	#if defined _SteamWorks_Included
	// Stats work
	if (LibraryExists("SteamWorks"))
		SteamWorks_SteamServersConnected();
	#endif
	/*for(int iClient = 1; iClient <= MaxClients; ++iClient)
		LoadPlayerData(iClient);*/
	if(g_bWarnSound)
	{
		char sBuffer[PLATFORM_MAX_PATH];
		FormatEx(sBuffer, sizeof(sBuffer), "sound/%s", g_sWarnSoundPath);
		if(FileExists(sBuffer, true) || FileExists(sBuffer))
		{
			AddFileToDownloadsTable(sBuffer);
			if(g_bIsFuckingGame)
			{
				FormatEx(sBuffer, sizeof(sBuffer), "*/%s", g_sWarnSoundPath);
				AddToStringTable(FindStringTable("soundprecache"), sBuffer);
			}
			else
				PrecacheSound(g_sWarnSoundPath, true);
		}
	}
	if(g_bDeleteExpired)
		CheckExpiredWarns();
}

public void OnAdminMenuReady(Handle hTopMenu) {InitializeMenu(hTopMenu);}

public void OnClientAuthorized(int iClient) {
  IsClientInGame(iClient) &&
	LoadPlayerData(iClient);
}

public void OnClientPutInServer(int iClient) {
  IsClientAuthorized(iClient) &&
	LoadPlayerData(iClient);
}

//---------------------------------------------------SOME FEATURES-------------------------------------------------

stock void PrintToAdmins(char[] sFormat, any ...)
{
	char sBuffer[255];
	for (int i = 1; i<=MaxClients; ++i)
		if (IsClientInGame(i) && (GetUserFlagBits(i) & g_iPrintToAdminsOverride))
		{	
			VFormat(sBuffer, sizeof(sBuffer), sFormat, 2);
			CPrintToChat(i, "%s", sBuffer);
		}
}

//----------------------------------------------------PUNISHMENTS---------------------------------------------------

public void PunishPlayerOnMaxWarns(int iAdmin, int iClient, char sReason[129])
{
	if (iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
		switch (g_iMaxPunishment)
		{
			case 1:
				KickClient(iClient, "[WarnSystem] %t", "WS_MaxKick");
			case 2:
			{
				char sBanReason[129];
				FormatEx(sBanReason, sizeof(sBanReason), "[WarnSystem] %t", "WS_MaxBan", sReason);
				BanClient(iClient, g_iBanLenght, BANFLAG_AUTO, sBanReason, sBanReason, "WarnSystem");
			}
			case 3:
			{
				char sBanReason[129];
				FormatEx(sBanReason, sizeof(sBanReason), "[WarnSystem] %t", "WS_MaxBan", sReason);
				if (WarnSystem_WarnMaxPunishment(iAdmin, iClient, g_iBanLenght, sReason) == Plugin_Continue)
				{
					LogWarnings("Selected max punishment with custom module but module doesn't exists.  Client kicked.");
					KickClient(iClient, "[WarnSystem] %t", "WS_MaxKick");
				}
			}
		}
}

public void PunishPlayer(int iAdmin, int iClient, char sReason[129])
{
	if (iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
		switch (g_iPunishment)
		{
			case 1:
				CPrintToChat(iClient, " %t %t", "WS_ColoredPrefix", "WS_Message");
			case 2:
			{
				if (IsPlayerAlive(iClient))
					SlapPlayer(iClient, g_iSlapDamage, true);
				CPrintToChat(iClient, " %t %t", "WS_ColoredPrefix", "WS_Message");
			}
			case 3:
			{
				if (IsPlayerAlive(iClient))
					ForcePlayerSuicide(iClient);
				CPrintToChat(iClient, " %t %t", "WS_ColoredPrefix", "WS_Message");
			}
			case 4: 
				PunishmentSix(iClient, iAdmin, sReason);
			case 5:
			{
				char sKickReason[129];
				FormatEx(sKickReason, sizeof(sKickReason), "[WarnSystem] %t", "WS_PunishKick", sReason);
				KickClient(iClient, sKickReason);
			}
			case 6:
			{
				char sBanReason[129];
				FormatEx(sBanReason, sizeof(sBanReason), "[WarnSystem] %t", "WS_PunishBan", sReason);
				BanClient(iClient, g_iBanLenght, BANFLAG_AUTO, sBanReason, sBanReason, "WarnSystem");
			}
			case 7:
			{
				char sBanReason[129];
				FormatEx(sBanReason, sizeof(sBanReason), "[WarnSystem] %t", "WS_PunishBan", sReason);
				if (WarnSystem_WarnPunishment(iAdmin, iClient, g_iBanLenght, sReason) == Plugin_Continue)
				{
					LogWarnings("Selected punishment with custom module but module doesn't exists.");
					PunishmentSix(iClient, iAdmin, sReason);
				}
			}
		}

}

public void PunishmentSix(int iClient, int iAdmin, char[] szReason)
{
	if (IsPlayerAlive(iClient))
		SetEntityMoveType(iClient, MOVETYPE_NONE);
	BuildAgreement(iClient, iAdmin, szReason);
	CPrintToChat(iClient, " %t %t", "WS_ColoredPrefix", "WS_Message");
}

stock bool IsValidClient(int iClient) { return (iClient > 0 && iClient < MaxClients && IsClientInGame(iClient) && !IsFakeClient(iClient)); }
stock void GetPort() { g_iPort=FindConVar("hostport").IntValue; }
stock void GetIPServer() { 
	int iHostIP = FindConVar("hostip").IntValue;
	FormatEx(g_sAddress, sizeof(g_sAddress), "%d.%d.%d.%d", (iHostIP >> 24) & 0x000000FF, (iHostIP >> 16) & 0x000000FF, (iHostIP >>  8) & 0x000000FF, iHostIP & 0x000000FF);
}

stock bool CheckAdminFlagsByString(int iClient, const char[] szFlagString)
{
    AdminFlag aFlag;
    int iFlags;

    for (int i = 0; i < strlen(szFlagString); i++)
    {
        if(!FindFlagByChar(szFlagString[i], aFlag))     continue;
        iFlags |= FlagToBit(aFlag);
        if (GetUserFlagBits(iClient) & iFlags)
        {
            return true;
        }
    }
    return false;
}