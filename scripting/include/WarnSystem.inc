#if defined _warnsystem_included
  #endinput
#endif
#define _warnsystem_included

/*********************************************************
 * Issue a warning on a player
 *
 * @param iClient		The client to issue a warning on
 * @param sReason		The reason why you issue a warning on client
 * @noreturn		
 *********************************************************/
native void WarnSystem_Warn(int iClient, char sReason[64]);

/*********************************************************
 * Remove a warning on a player
 *
 * @param iClient		The client to remove the warning on
 * @param sReason		The reason why you remove the warning
 * @noreturn		
 *********************************************************/
native void WarnSystem_UnWarn(int iClient, char sReason[64]);

/*********************************************************
 * Reset a players warnings
 *
 * @param client		The client to reset the warnings on
 * @param reason		The reason why you reset the warnings
 * @noreturn		
 *********************************************************/
native void WarnSystem_ResetWarn(int iClient, char sReason[64]);

/*********************************************************
 * Returns database handle
 *
 * @noparam
 * @return Database	handle	
 *********************************************************/
 native Database WarnSystem_GetDatabase();