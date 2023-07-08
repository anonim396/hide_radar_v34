#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <clientprefs>

bool g_bRadar[MAXPLAYERS+1];
float fDuration;

Handle gH_RadarCookie;

bool gB_Late;

public Plugin myinfo = 
{
    name = "Toggle Radar",
    author = "",
    description = "Does not need a description",
	version     = "1.0",
    url = ""
};

public void OnPluginStart() 
{
	HookEvent("player_blind", Event_PlayerBlind, EventHookMode_Post);
	HookEvent("player_spawn", Player_Spawn);
	
	gH_RadarCookie = RegClientCookie("radar_enabled", "radar enabled", CookieAccess_Protected);
	
	RegConsoleCmd("sm_radar", cmd_radar);
	
	if (gB_Late)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}

			if (!AreClientCookiesCached(i))
			{
				continue;
			}

			OnClientCookiesCached(i);
		}
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	gB_Late = late;
	return APLRes_Success;
}

public void OnClientCookiesCached(int client)
{
	if (!GetClientCookieBool(client, gH_RadarCookie, g_bRadar[client]))
	{
		g_bRadar[client] = false;
		SetClientCookieBool(client, gH_RadarCookie, false);
	}
}

public void Player_Spawn(Handle event, char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.0, RemoveRadar, client);
} 

public Action cmd_radar(int client, int args)
{
	if(!client)
		return Plugin_Handled;
		
	g_bRadar[client] = !g_bRadar[client];
	
	SetClientCookieBool(client, gH_RadarCookie, g_bRadar[client]);
	
	CSSHideRadar(client);
	PrintToChat(client, "Your Radar is now %s.", g_bRadar[client] ? "Disable" : "Enable");
		
	return Plugin_Handled;
}

public void OnClientDisconnect(int client)
{
	g_bRadar[client] = false;
}

public Action RemoveRadar(Handle timer, any client) 
{    
	CSSHideRadar(client);
	return Plugin_Handled;
} 

public void Event_PlayerBlind(Handle event, char[] name, bool dontBroadcast)
{
	int userid = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userid);
	
	if (client && GetClientTeam(client) > 1)
	{
		fDuration = GetEntPropFloat(client, Prop_Send, "m_flFlashDuration");
		CreateTimer(fDuration, RemoveRadar, client);
	}
}

stock void CSSHideRadar(int client)
{
	if(!client)
		return;
	
	if (g_bRadar[client])
	{
		SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 3600.0);
		SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
	}
	else
	{
		SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 0.0);
		SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.0);
	}
}

stock void SetClientCookieBool(int client, Handle cookie, bool value)
{
	SetClientCookie(client, cookie, value ? "1" : "0");
}

stock bool GetClientCookieBool(int client, Handle cookie, bool& value)
{
	char buffer[8];
	GetClientCookie(client, cookie, buffer, sizeof(buffer));

	if (buffer[0] == '\0')
	{
		return false;
	}

	value = StringToInt(buffer) != 0;
	return true;
}