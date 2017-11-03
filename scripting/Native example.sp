#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <WarnSystem>

public Plugin myinfo = 
{
    name = "WarnSystem natives example",
    author = "vadrozh, ecca",
    description = "",
    version = "1.0",
    url = "hlmod.ru"
};

public void OnPluginStart() 
{
    RegConsoleCmd("sm_warnexample", Command_warnexample);
}

public Action Command_warnexample(int client, int args) 
{
    WarnSystem_Warn(client, "Bad boy");
}
