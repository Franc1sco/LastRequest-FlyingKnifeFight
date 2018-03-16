#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <lastrequest>
#include <hosties>


public Plugin myinfo = 
{
	name = "LR - Flying knife fight", 
	author = "KeidaS and Franc1sco franug", 
	description = "Flying knife fight for last request plugin", 
	version = "1.0", 
	url = "-"
};

bool canFly[MAXPLAYERS];
bool lrActive = false;
new lrId;
new prisoner;
new guard;

#define HEIGHT 1.01

int g_iToolsVelocity;

public void OnPluginStart()
{
	g_iToolsVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");	
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (!canFly[client])return;
	
	canFly[client] = false;
		
	SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
		
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SetEntityMoveType(client, MOVETYPE_WALK);
}

public Action:OnWeaponCanUse(client, weapon)
{	
	return Plugin_Handled;
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (damagetype & DMG_FALL) return Plugin_Handled;
	
	
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) {
	if (IsFakeClient(client)) {
		return Plugin_Continue;
	}
	if (lrActive && IsPlayerAlive(client) && canFly[client]) 
	{
		
		SetEntityMoveType(client, MOVETYPE_FLY);
		if (buttons & IN_JUMP) 
		{
			//PrintToChat(client, "impulso");

			JumpBoostOnClientJumpPost(client);
		}
	}
	return Plugin_Continue;
}

public void OnConfigsExecuted() {
	static bool:addedCustomLr = false;
	if (!addedCustomLr) {
		lrId = AddLastRequestToList(LrStart, LrStop, "Flying knife fight", true);
		addedCustomLr = true;
	}
}

public LrStart(Handle:array, LrNumber) {
	new lrType = GetArrayCell(array, LrNumber, _:Block_LRType);
	if (lrType == lrId) {
		char namePrisoner[64];
		char nameGuard[64];
		prisoner = GetArrayCell(array, LrNumber, _:Block_Prisoner);
		guard = GetArrayCell(array, LrNumber, _:Block_Guard);
		
		canFly[prisoner] = true;
		canFly[guard] = true;
		
		RemoveWeapons(prisoner);
		RemoveWeapons(guard);
		
		GivePlayerItem(prisoner, "weapon_knife");
		GivePlayerItem(guard, "weapon_knife");
		
		SDKHook(prisoner, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKHook(guard, SDKHook_WeaponCanUse, OnWeaponCanUse);
		
		SDKHook(prisoner, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(guard, SDKHook_OnTakeDamage, OnTakeDamage);
		
		SetEntityHealth(prisoner, 100);
		SetEntityMoveType(prisoner, MOVETYPE_FLY);
		
		SetEntityHealth(guard, 100);
		SetEntityMoveType(guard, MOVETYPE_FLY);
		
		GetClientName(prisoner, namePrisoner, sizeof(namePrisoner));
		GetClientName(guard, nameGuard, sizeof(nameGuard));
		
		PrintToChatAll("%s chose to have a Flying Knife Fight with %s", namePrisoner, nameGuard);
		lrActive = true;
	}
}

public LrStop(type, Prisoner, Guard) {
	if (lrActive && type == lrId) {
		prisoner = Prisoner;
		guard = Guard;
		
		canFly[prisoner] = false;
		canFly[guard] = false;
		
		SDKUnhook(prisoner, SDKHook_WeaponCanUse, OnWeaponCanUse);
		SDKUnhook(guard, SDKHook_WeaponCanUse, OnWeaponCanUse);
		
		SetEntityMoveType(prisoner, MOVETYPE_WALK);
		
		CreateTimer(4.0, Timer_NoFall, GetClientUserId(prisoner), TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(4.0, Timer_NoFall, GetClientUserId(guard), TIMER_FLAG_NO_MAPCHANGE);
		
		SetEntityMoveType(guard, MOVETYPE_WALK);
		
		lrActive = false;
	}
}

public Action Timer_NoFall(Handle timer, int id)
{
	int client = GetClientOfUserId(id);
	
	if (!client || !IsClientInGame(client))return;
	
	SDKUnhook(prisoner, SDKHook_OnTakeDamage, OnTakeDamage);
	
}

public void OnPluginEnd() {
	RemoveLastRequestFromList(LrStart, LrStop, "Flying knife fight");
}

stock void RemoveWeapons(int client)
{
	int weapon;
	for (int i = 0; i <= 5; i++)
	{
		if (i > 2 && GetClientTeam(client) == 3)continue;
		
		while((weapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, weapon);
			AcceptEntityInput(weapon, "Kill");
		}
	}
}


/**
 * Client is jumping.
 * 
 * @param client    The client index.
 */
stock JumpBoostOnClientJumpPost(client)
{
    // Get class jump multipliers.
    new Float:distancemultiplier = 1.0;
    new Float:heightmultiplier = HEIGHT;
    
    // If both are set to 1.0, then stop here to save some work.
    if (distancemultiplier == 1.0 && heightmultiplier == 1.0)
    {
        return;
    }
    
    new Float:vecVelocity[3];
    
    // Get client's current velocity.
    ToolsClientVelocity(client, vecVelocity, false);
    
    // Only apply horizontal multiplier if it's not a bhop.
    if (!JumpBoostIsBHop(vecVelocity))
    {
        // Apply horizontal multipliers to jump vector.
        vecVelocity[0] *= distancemultiplier;
        vecVelocity[1] *= distancemultiplier;
    }
    
    // Apply height multiplier to jump vector.
    vecVelocity[2] *= heightmultiplier;
    
    // Set new velocity.
    ToolsClientVelocity(client, vecVelocity, true, false);
}

/**
 * This function detects excessive bunnyhopping.
 * Note: This ONLY catches bunnyhopping that is worse than CS:S already allows.
 * 
 * @param vecVelocity   The velocity of the client jumping.
 * @return              True if the client is bunnyhopping, false if not.
 */
stock bool:JumpBoostIsBHop(const Float:vecVelocity[])
{
    // Calculate the magnitude of jump on the xy plane.
    new Float:magnitude = SquareRoot(Pow(vecVelocity[0], 2.0) + Pow(vecVelocity[1], 2.0));
    
    // Return true if the magnitude exceeds the max.
    new Float:bunnyhopmax = 300.0;
    return (magnitude > bunnyhopmax);
}

stock ToolsClientVelocity(client, Float:vecVelocity[3], bool:apply = true, bool:stack = true)
{
    // If retrieve if true, then get client's velocity.
    if (!apply)
    {
        // x = vector component.
        for (new x = 0; x < 3; x++)
        {
            vecVelocity[x] = GetEntDataFloat(client, g_iToolsVelocity + (x*4));
        }
        
        // Stop here.
        return;
    }
    
    // If stack is true, then add client's velocity.
    if (stack)
    {
        // Get client's velocity.
        new Float:vecClientVelocity[3];
        
        // x = vector component.
        for (new x = 0; x < 3; x++)
        {
            vecClientVelocity[x] = GetEntDataFloat(client, g_iToolsVelocity + (x*4));
        }
        
        AddVectors(vecClientVelocity, vecVelocity, vecVelocity);
    }
    
    // Apply velocity on client.
    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

