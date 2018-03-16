#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <lastrequest>
#include <hosties>
#include <entities>


public Plugin myinfo = 
{
	name = "LR - Fliying knife fight", 
	author = "KeidaS", 
	description = "Flying knife fight for last request plugin", 
	version = "1.0", 
	url = "www.hermandadfenix.es"
};

bool canFly[MAXPLAYERS];
bool lrActive = false;
new lrId;
new prisoner;
new guard;

public void OnPluginStart() {
	RegConsoleCmd("fly", fly);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) {
	if (!IsFakeClient(client)) {
		return Plugin_Continue;
	}
	if (lrActive && IsPlayerAlive(client) && canFly[client]) {
		if (buttons & IN_JUMP) {
			new Float:vec[3];
			Entity_GetBaseVelocity(client, vec);
			vec[2] += 8;
			Entity_SetBaseVelocity(client, vec);
			ChangeEdictState(client);
		}
	}
	return Plugin_Continue;
}

public Action fly(int client, int args) {
	if (lrActive && IsPlayerAlive(client) && canFly[client]) {
		SetEntityMoveType(client, MOVETYPE_FLY);
		SetEntityMoveCollide(client, 1);
		ChangeEdictState(client);
	}
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
		
		SetEntityHealth(prisoner, 100);
		SetEntityMoveType(prisoner, MOVETYPE_FLY);
		SetEntityMoveCollide(prisoner, 1);
		ChangeEdictState(prisoner);
		
		SetEntityHealth(guard, 100);
		SetEntityMoveType(guard, MOVETYPE_FLY);
		SetEntityMoveCollide(guard, 1);
		ChangeEdictState(guard);
		
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
		
		SetEntityMoveType(prisoner, MOVETYPE_WALK);
		SetEntityMoveCollide(prisoner, 0);
		ChangeEdictState(prisoner);
		
		SetEntityMoveType(guard, MOVETYPE_WALK);
		SetEntityMoveCollide(guard, 0);
		ChangeEdictState(guard);
		
		lrActive = false;
	}
}

public void OnPLuginEnd() {
	RemoveLastRequestFromList(LrStart, LrStop, "Flying knife fight");
}

public void SetEntityMoveCollide(client, movecollide) {
	SetEntProp(client, Prop_Data, "m_MoveCollide", movecollide);
}

public void RemoveWeapons(int client) {
	if (GetPlayerWeaponSlot(client, 0) != -1) {
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 0));
	}
	if (GetPlayerWeaponSlot(client, 1) != -1) {
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
	}
	if (GetPlayerWeaponSlot(client, 3) != -1) {
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 3));
	}
	if (GetPlayerWeaponSlot(client, 4) != -1) {
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 4));
	}
} 