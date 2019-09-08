ConVar g_hCvarMaxWarns, g_hCvarMaxPunishment, g_hCvarBanLength, g_hCvarPunishment, g_hCvarSlapDamage, g_hCvarPrintToAdmins,
        g_hCvarLogWarnings, g_hCvarWarnSound, g_hCvarWarnSoundPath, g_hCvarResetWarnings, g_hCvarPrintToChat, g_hCvarDeleteExpired, 
        g_hCharLogQuery, g_hCvarWarnLength, g_hCvarRistictUnwarn, g_hCvarFlagUnRistict,
        g_hCvarSeparationDB;

bool g_bResetWarnings, g_bWarnSound, g_bPrintToAdmins, g_bLogWarnings, g_bPrintToChat, g_bDeleteExpired,
        g_bLogQuery, g_bRistictUnwarn, g_bSeparationDB;
int g_iMaxWarns, g_iPunishment, g_iMaxPunishment, g_iBanLenght, g_iSlapDamage, g_iWarnLength;
char g_sWarnSoundPath[PLATFORM_MAX_PATH], g_sFlagUnRistict[22];

public void InitializeConVars()
{
    (g_hCvarResetWarnings = CreateConVar("sm_warns_resetwarnings", "0", "Delete warns then player reach max warns: 0 - Keep warns(set it expired), 1 - Delete warns", _, true, 0.0, true, 1.0)).AddChangeHook(ChangeCvar_ResetWarnings);
    (g_hCvarMaxWarns = CreateConVar("sm_warns_maxwarns", "3", "Max warnings before punishment", _, true, 1.0, true, 10.0)).AddChangeHook(ChangeCvar_MaxWarns);
    (g_hCvarPunishment = CreateConVar("sm_warns_punishment", "4", "On warn: 1 - message player, 2 - slap player and message, 3 - slay player and message, 4 - Popup agreement and message, 5 - kick player with reason, 6 - ban player with reason, 7 - ban(or do something) with module", _, true, 1.0, true, 7.0)).AddChangeHook(ChangeCvar_Punishment);
    (g_hCvarMaxPunishment = CreateConVar("sm_warns_maxpunishment", "1", "On max warns: 1 - kick, 2 - ban, 3 - ban(or do something) with module, 4 - nothing", _, true, 1.0, true, 4.0)).AddChangeHook(ChangeCvar_MaxPunishment);
    (g_hCvarBanLength = CreateConVar("sm_warns_banlength", "60", "Time to ban target(minutes): 0 - permanent")).AddChangeHook(ChangeCvar_BanLength);
    (g_hCvarSlapDamage = CreateConVar("sm_warns_slapdamage", "0", "Slap player with damage: 0 - no damage", _, true, 0.0, true, 300.0)).AddChangeHook(ChangeCvar_SlapDamage);
    
    (g_hCvarWarnSound = CreateConVar("sm_warns_warnsound", "1", "Play a sound when a user receives a warning: 0 - disabled, 1 - enabled", _, true, 0.0, true, 1.0)).AddChangeHook(ChangeCvar_WarnSound);
    (g_hCvarWarnSoundPath = CreateConVar("sm_warns_warnsoundpath", "buttons/weapon_cant_buy.wav", "Path to the sound that'll play when a user receives a warning")).AddChangeHook(ChangeCvar_WarnSoundPath);
    
    (g_hCvarPrintToAdmins = CreateConVar("sm_warns_printtoadmins", "1", "Print previous warnings on client connect to admins: 0 - disabled, 1 - enabled", _, true, 0.0, true, 1.0)).AddChangeHook(ChangeCvar_PrintToAdmins);
    (g_hCvarPrintToChat = CreateConVar("sm_warns_printtochat", "1", "Print to all, then somebody warned/unwarned: 0 - print only to admins, 1 - print to all", _, true, 0.0, true, 1.0)).AddChangeHook(ChangeCvar_PrintToChat);
    (g_hCvarLogWarnings = CreateConVar("sm_warns_enablelogs", "1", "Log errors and warns: 0 - disabled, 1 - enabled", _, true, 0.0, true, 1.0)).AddChangeHook(ChangeCvar_LogWarnings);
    (g_hCvarDeleteExpired = CreateConVar("sm_warns_delete_expired", "1", "Delete expired warnings of DB: 0 - disabled, 1 - enabled", _, true, 0.0, true, 1.0)).AddChangeHook(ChangeCvar_DeleteExpired);
    (g_hCharLogQuery = CreateConVar("sm_warns_enable_querylog", "0", "Logging query to DB: 0 - disabled, 1 - enabled", _, true, 0.0, true, 1.0)).AddChangeHook(ChangeCvar_LogQuery);
    (g_hCvarWarnLength = CreateConVar("sm_warns_warnlength", "86400", "Duration of the issued warning in seconds (0 - permanent).")).AddChangeHook(ChangeCvar_WarnLength);

    g_hCvarRistictUnwarn = CreateConVar("sm_warns_ristict_unwarn", "0", "Ristiction unwarns and reset warns: (0 - unristict, 1 - ristict", _, true, 0.0, true, 1.0);
    g_hCvarFlagUnRistict = CreateConVar("sm_warns_unristict_flags", "z", "Need flag to unristict unwarns (e.x. 'z').");
    g_hCvarSeparationDB = CreateConVar("sm_warns_split_db", "0", "Separation the database into servers: 1 - yes, 0 - no.", _, true, 0.0, true, 1.0);

    g_hCvarRistictUnwarn.AddChangeHook(ChangeCvar_Risticted);
    g_hCvarFlagUnRistict.AddChangeHook(ChangeCvar_FlagUnRistict);
    g_hCvarSeparationDB.AddChangeHook(ChangeCvar_SeparationDB);
    
    AutoExecConfig(true, "core", "warnsystem");
}

public void OnConfigsExecuted()
{
    g_bResetWarnings = g_hCvarResetWarnings.BoolValue;
    g_iMaxWarns = g_hCvarMaxWarns.IntValue;
    g_iPunishment = g_hCvarPunishment.IntValue;
    g_iMaxPunishment = g_hCvarMaxPunishment.IntValue;
    g_iBanLenght = g_hCvarBanLength.IntValue;
    g_iSlapDamage = g_hCvarSlapDamage.IntValue;
    g_iWarnLength = g_hCvarWarnLength.IntValue;
    
    g_bWarnSound = g_hCvarWarnSound.BoolValue;
    g_hCvarWarnSoundPath.GetString(g_sWarnSoundPath, sizeof(g_sWarnSoundPath));
    g_hCvarFlagUnRistict.GetString(g_sFlagUnRistict, sizeof(g_sFlagUnRistict));
    
    g_bPrintToAdmins = g_hCvarPrintToAdmins.BoolValue;
    g_bPrintToChat = g_hCvarPrintToChat.BoolValue;
    g_bLogWarnings = g_hCvarLogWarnings.BoolValue;
    g_bLogQuery = g_hCharLogQuery.BoolValue;
    g_bDeleteExpired = g_hCvarDeleteExpired.BoolValue;
    g_bRistictUnwarn = g_hCvarRistictUnwarn.BoolValue;
    g_bSeparationDB = g_hCvarSeparationDB.BoolValue;
}

public void ChangeCvar_ResetWarnings(ConVar convar, const char[] oldValue, const char[] newValue){g_bResetWarnings = convar.BoolValue;}
public void ChangeCvar_MaxWarns(ConVar convar, const char[] oldValue, const char[] newValue){g_iMaxWarns = convar.IntValue;}
public void ChangeCvar_Punishment(ConVar convar, const char[] oldValue, const char[] newValue){g_iPunishment = convar.IntValue;}
public void ChangeCvar_MaxPunishment(ConVar convar, const char[] oldValue, const char[] newValue){g_iMaxPunishment = convar.IntValue;}
public void ChangeCvar_BanLength(ConVar convar, const char[] oldValue, const char[] newValue){g_iBanLenght = convar.IntValue;}
public void ChangeCvar_WarnLength(ConVar convar, const char[] oldValue, const char[] newValue){g_iWarnLength = convar.IntValue;}
public void ChangeCvar_SlapDamage(ConVar convar, const char[] oldValue, const char[] newValue){g_iSlapDamage = convar.IntValue;}
public void ChangeCvar_WarnSound(ConVar convar, const char[] oldValue, const char[] newValue){g_bWarnSound = convar.BoolValue;}
public void ChangeCvar_WarnSoundPath(ConVar convar, const char[] oldValue, const char[] newValue){convar.GetString(g_sWarnSoundPath, sizeof(g_sWarnSoundPath));}
public void ChangeCvar_PrintToAdmins(ConVar convar, const char[] oldValue, const char[] newValue){g_bPrintToAdmins = convar.BoolValue;}
public void ChangeCvar_PrintToChat(ConVar convar, const char[] oldValue, const char[] newValue){g_bPrintToChat = convar.BoolValue;}
public void ChangeCvar_LogWarnings(ConVar convar, const char[] oldValue, const char[] newValue){g_bLogWarnings = convar.BoolValue;}
public void ChangeCvar_DeleteExpired(ConVar convar, const char[] oldValue, const char[] newValue){g_bDeleteExpired = convar.BoolValue;}
public void ChangeCvar_LogQuery(ConVar convar, const char[] oldValue, const char[] newValue){g_bLogQuery = convar.BoolValue;}
public void ChangeCvar_FlagUnRistict(ConVar convar, const char[] oldValue, const char[] newValue){ convar.GetString(g_sFlagUnRistict, sizeof(g_sFlagUnRistict));}
public void ChangeCvar_Risticted(ConVar convar, const char[] oldValue, const char[] newValue){g_bRistictUnwarn = convar.BoolValue;}
public void ChangeCvar_SeparationDB(ConVar convar, const char[] oldValue, const char[] newValue){g_bSeparationDB = convar.BoolValue;}