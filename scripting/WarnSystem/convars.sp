ConVar g_hCvarMaxWarns, g_hCvarMaxPunishment, g_hCvarBanLength, g_hCvarPunishment, g_hCvarSlapDamage, g_hCvarPrintToAdmins,
		g_hCvarLogWarnings, g_hCvarWarnSound, g_hCvarWarnSoundPath, g_hCvarResetWarnings;

bool g_bResetWarnings, g_bWarnSound, g_bPrintToAdmins, g_bLogWarnings;
int g_iMaxWarns, g_iPunishment, g_iMaxPunishment, g_iBanLenght, g_iSlapDamage;
char g_sWarnSoundPath[PLATFORM_MAX_PATH];

public void InitializeConVars()
{
	(g_hCvarResetWarnings = CreateConVar("sm_warn_resetwarnings", "0", "Reset warnings when they reach the max warnings: 0 - Keep warnings, 1 - Delete warnings", _, true, 0.0, true, 1.0)).AddChangeHook(ChangeCvar_ResetWarnings);
	(g_hCvarMaxWarns = CreateConVar("sm_warn_maxwarns", "3", "Max warnings before punishment", _, true, 1.0, true, 10.0)).AddChangeHook(ChangeCvar_MaxWarns);
	(g_hCvarPunishment = CreateConVar("sm_warn_punishment", "4", "On warn: 1 - message player, 2 - slap player and message, 3 - slay player and message, 4 - Popup agreement and message, 5 - kick player with reason, 6 - ban player with reason", _, true, 1.0, true, 6.0)).AddChangeHook(ChangeCvar_Punishment);
	(g_hCvarMaxPunishment = CreateConVar("sm_warn_maxpunishment", "1", "On max warns: 1 - kick, 2 - ban", _, true, 1.0, true, 2.0)).AddChangeHook(ChangeCvar_MaxPunishment);
	(g_hCvarBanLength = CreateConVar("sm_warn_banlength", "60", "Time to ban target(minutes): 0 - permanent")).AddChangeHook(ChangeCvar_BanLength);
	(g_hCvarSlapDamage = CreateConVar("sm_warn_slapdamage", "0", "Slap player with damage: 0 - no damage", _, true, 0.0, true, 300.0)).AddChangeHook(ChangeCvar_SlapDamage);
	
	(g_hCvarWarnSound = CreateConVar("sm_warn_warnsound", "1", "Play a sound when a user receives a warning: 0 - disabled, 1 - enabled", _, true, 0.0, true, 1.0)).AddChangeHook(ChangeCvar_WarnSound);
	(g_hCvarWarnSoundPath = CreateConVar("sm_warn_warnsoundpath", "buttons/weapon_cant_buy.wav", "Path to the sound that will play when a user receives a warning")).AddChangeHook(ChangeCvar_WarnSoundPath);
	
	(g_hCvarPrintToAdmins = CreateConVar("sm_warn_printtoadmins", "1", "Print previous warnings on client connect to admins: 0 - disabled, 1 - enabled", _, true, 0.0, true, 1.0)).AddChangeHook(ChangeCvar_PrintToAdmins);
	(g_hCvarLogWarnings = CreateConVar("sm_warn_logwarnings", "1", "Log the admin commands: 0 - disabled, 1 - enabled", _, true, 0.0, true, 1.0)).AddChangeHook(ChangeCvar_LogWarnings);
	
	AutoExecConfig(true, "WarnSystem");
}

public void OnConfigsExecuted()
{
	g_bResetWarnings = g_hCvarResetWarnings.BoolValue;
	g_iMaxWarns = g_hCvarMaxWarns.IntValue;
	g_iPunishment = g_hCvarPunishment.IntValue;
	if (g_iPunishment > 6 || g_iPunishment < 1)
		LogWarnings("[WarnSystem] ConVar sm_warn_punishment contains incorrect value(%i)", g_iMaxPunishment);
	g_iMaxPunishment = g_hCvarMaxPunishment.IntValue;
	g_iBanLenght = g_hCvarBanLength.IntValue;
	g_iSlapDamage = g_hCvarSlapDamage.IntValue;
	g_bWarnSound = g_hCvarWarnSound.BoolValue;
	g_hCvarWarnSoundPath.GetString(g_sWarnSoundPath, sizeof(g_sWarnSoundPath));
	g_bPrintToAdmins = g_hCvarPrintToAdmins.BoolValue;
	g_bLogWarnings = g_hCvarLogWarnings.BoolValue;
}

public void ChangeCvar_ResetWarnings(ConVar convar, const char[] oldValue, const char[] newValue){g_bResetWarnings = convar.BoolValue;}
public void ChangeCvar_MaxWarns(ConVar convar, const char[] oldValue, const char[] newValue){g_iMaxWarns = convar.IntValue;}
public void ChangeCvar_Punishment(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iPunishment = convar.IntValue;
	if (g_iPunishment > 6 || g_iPunishment < 1)
		LogWarnings("[WarnSystem] ConVar sm_warn_punishment contains incorrect value(%i)", g_iMaxPunishment);
}
public void ChangeCvar_MaxPunishment(ConVar convar, const char[] oldValue, const char[] newValue){g_iMaxPunishment = convar.IntValue;}
public void ChangeCvar_BanLength(ConVar convar, const char[] oldValue, const char[] newValue){g_iBanLenght = convar.IntValue;}
public void ChangeCvar_SlapDamage(ConVar convar, const char[] oldValue, const char[] newValue){g_iSlapDamage = convar.IntValue;}
public void ChangeCvar_WarnSound(ConVar convar, const char[] oldValue, const char[] newValue){g_bWarnSound = convar.BoolValue;}
public void ChangeCvar_WarnSoundPath(ConVar convar, const char[] oldValue, const char[] newValue){convar.GetString(g_sWarnSoundPath, sizeof(g_sWarnSoundPath));}
public void ChangeCvar_PrintToAdmins(ConVar convar, const char[] oldValue, const char[] newValue){g_bPrintToAdmins = convar.BoolValue;}
public void ChangeCvar_LogWarnings(ConVar convar, const char[] oldValue, const char[] newValue){g_bLogWarnings = convar.BoolValue;}