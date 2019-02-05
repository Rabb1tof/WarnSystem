#if defined _warnsystem_included
  #endinput
#endif

#define _warnsystem_included
#define APIVERSION "1.4"

public SharedPlugin __pl_WarnSystem = {
    name = "WarnSystem",
    file = "WarnSystem.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_DynamicMOTD_SetNTVOptional() {
    MarkNativeAsOptional("WarnSystem_Warn");
    MarkNativeAsOptional("WarnSystem_UnWarn");
    MarkNativeAsOptional("WarnSystem_ResetWarn");
    MarkNativeAsOptional("WarnSystem_GetDatabase");
    MarkNativeAsOptional("WarnSystem_GetPlayerWarns");
	MarkNativeAsOptional("WarnSystem_GetMaxWarns");
	MarkNativeAsOptional("WarnSystem_PrintToAdmins");
}
#endif

/*********************************************************
 * Issue a warning on a player
 *
 * @param iAdmin		The admin who issued a warning
 * @param iClient		The client to issue a warning on
 * @param sReason		The reason why you issue a warning on client
 * @noreturn		
 *********************************************************/
native void WarnSystem_Warn(int iAdmin, int iClient, char sReason[129]);

/*********************************************************
 * Remove a warning on a player
 *
 * @param iAdmin		The admin who issued a warning
 * @param iClient		The client to remove the warning on
 * @param sReason		The reason why you remove the warning
 * @noreturn		
 *********************************************************/
native void WarnSystem_UnWarn(int iAdmin, int iClient, char sReason[129]);

/*********************************************************
 * Reset a players warnings
 *
 * @param iAdmin		The admin who issued a warning
 * @param iClient		The client to reset the warnings on
 * @param sReason		The reason why you reset the warnings
 * @noreturn		
 *********************************************************/
native void WarnSystem_ResetWarn(int iAdmin, int iClient, char sReason[129]);

/*********************************************************
 * Returns database handle
 *
 * @noparam
 * @return Database	handle	
 *********************************************************/
 native Database WarnSystem_GetDatabase();
 
 /*********************************************************
 * Returns count of player warns
 *
 * @param 	iClient
 * @return 	Count of client warnings
 *********************************************************/
 native int WarnSystem_GetPlayerWarns(int iClient);
 
  /*********************************************************
 * Returns count of max warns
 *
 * @noparam
 * @return 	Count of client warnings
 *********************************************************/
 native int WarnSystem_GetMaxWarns();
 
 /*********************************************************
 * Prints message to admins.
 *
 * @param 	sMessage
 * @noreturn
 *********************************************************/
 native void WarnSystem_PrintToAdmins(char sMessage[256]);
 
 /*********************************************************
 * Calling then client data loaded successfully
 *
 * @param iClient		Client
 * @param iWarnings		Count of client warns
 * @param g_iMaxWarns	Count of max allowed warns
 * @noreturn
 *********************************************************/
 forward void WarnSystem_OnClientLoaded(int iClient, int iWarnings, int g_iMaxWarns);
 
 /*********************************************************
 * Calling then admin issues a warn
 *
 * @param iAdmin		The admin who issued a warning
 * @param iClient		The client to warn
 * @param sReason		The reason why he warns
 * @noreturn	
 *********************************************************/
 forward void WarnSystem_OnClientWarn(int iAdmin, int iClient, char sReason[129]);
 
 /*********************************************************
 * Calling then admin issues a unwarn
 *
 * @param iAdmin		The admin who issued a unwarning
 * @param iClient		The client to unwarn
 * @param sReason		The reason why he un6warns
 * @noreturn	
 *********************************************************/
 forward void WarnSystem_OnClientUnWarn(int iAdmin, int iClient, char sReason[129]);
 
 /*********************************************************
 * Calling then admin issues a warn reset
 *
 * @param iAdmin		The admin who issued a warn reset
 * @param iClient		The client to reset warns
 * @param sReason		The reason why he reset warns
 * @noreturn	
 *********************************************************/
 forward void WarnSystem_OnClientResetWarns(int iAdmin, int iClient, char sReason[129]);
 
 /*********************************************************
 * Calling on warn to punish player
 *
 * @param iAdmin		The admin who issued warn
 * @param iClient		The client
 * @param sReason		The ban reason
 * @return Return Plugin_Stop or core will log error
 *********************************************************/
 forward Action WarnSystem_WarnPunishment(int iAdmin, int iClient, int iBanLenght, char sReason[129]);
 
 /*********************************************************
 * Calling on maxwarns to punish player
 *
 * @param iAdmin		The admin who issued warn
 * @param iClient		The client
 * @param sReason		The ban reason
 * @return Return Plugin_Stop or core will log error
 *********************************************************/
 forward Action WarnSystem_WarnMaxPunishment(int iAdmin, int iClient, int iBanLenght, char sReason[129]);