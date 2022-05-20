/*
 * Copyright (C) 2022  Mikusch
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#pragma semicolon 1
#pragma newdecls required

void Events_Initialize()
{
	HookEvent("player_spawn", EventHook_PlayerSpawn);
	HookEvent("player_death", EventHook_PlayerDeath);
	HookEvent("player_team", EventHook_PlayerTeam, EventHookMode_Pre);
	HookEvent("post_inventory_application", EventHook_PostInventoryApplication);
	HookEvent("player_builtobject", EventHook_PlayerBuiltObject);
	HookEvent("teamplay_round_start", EventHook_TeamplayRoundStart);
	HookEvent("teamplay_flag_event", EventHook_TeamplayFlagEvent);
}

public void EventHook_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (TF2_GetClientTeam(client) == TFTeam_Invaders)
	{
		if (TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			SpyLeaveSpawnRoomStart(client);
		}
	}
}

public void EventHook_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int victim = GetClientOfUserId(userid);
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if (TF2_GetClientTeam(victim) == TFTeam_Invaders)
	{
		// Replicate behavior of CTFBotDead::Update
		CreateTimer(5.0, Timer_DeadTimer, userid);
	}
	else if (0 < attacker <= MaxClients && TF2_GetClientTeam(victim) == TFTeam_Defenders && TF2_GetClientTeam(attacker) == TFTeam_Invaders)
	{
		bool isTaunting = !SDKCall_HasTheFlag(attacker) && GetRandomFloat(0.0, 100.0) <= tf_bot_taunt_victim_chance.FloatValue;
		
		if (GetEntProp(attacker, Prop_Send, "m_bIsMiniBoss"))
		{
			// Bosses don't taunt puny humans
			isTaunting = false;
		}
		
		if (isTaunting)
		{
			// we just killed a human - taunt!
			FakeClientCommand(attacker, "taunt");
		}
	}
}

public Action EventHook_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	TFTeam team = view_as<TFTeam>(event.GetInt("team"));
	
	// Only show when a new defender joins
	bool bSilent = (team == TFTeam_Spectator) || (team == TFTeam_Invaders);
	event.SetInt("silent", bSilent);
	
	TF2Attrib_RemoveAll(client);
	// Clear Sound
	Player(client).StopIdleSound();
	
	if (team == TFTeam_Spectator || team == TFTeam_Red)
	{
		Player(client).Reset();
		
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
	}
	
	return Plugin_Changed;
}

public void EventHook_PostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (TF2_GetClientTeam(client) == TFTeam_Invaders)
	{
		// remove any weapons we aren't supposed to have
		for (int iItemSlot = LOADOUT_POSITION_PRIMARY; iItemSlot < CLASS_LOADOUT_POSITION_COUNT; iItemSlot++)
		{
			int entity = TF2Util_GetPlayerLoadoutEntity(client, iItemSlot);
			if (Player(client).IsWeaponRestricted(entity))
			{
				RemovePlayerItem(client, entity);
				RemoveEntity(entity);
			}
		}
	}
	
	// equip our required weapon
	Player(client).EquipRequiredWeapon();
}

public void EventHook_PlayerBuiltObject(Event event, const char[] name, bool dontBroadcast)
{
	int builder = GetClientOfUserId(event.GetInt("userid"));
	TFObjectType type = view_as<TFObjectType>(event.GetInt("object"));
	int index = event.GetInt("index");
	
	if (TF2_GetClientTeam(builder) == TFTeam_Invaders)
	{
		if (type == TFObject_Teleporter && TF2_GetObjectMode(index) == TFObjectMode_Exit)
		{
			CObjectTeleporter(index).SetTeleportWhere(Player(builder).m_teleportWhereName);
		}
	}
}

public void EventHook_TeamplayRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (GetCurrentWaveIndex() == 0 && !g_hWaitingForPlayersTimer)
	{
		g_bInWaitingForPlayers = true;
		
		// Show the "Waiting For Players" text
		tf_mvm_min_players_to_start.IntValue = MaxClients + 1;
		
		g_hWaitingForPlayersTimer = CreateTimer(mp_waitingforplayers_time.FloatValue, Timer_OnWaitingForPlayersEnd);
	}
	else
	{
		tf_mvm_min_players_to_start.IntValue = 0;
		g_bInWaitingForPlayers = false;
		
		PrintToChatAll("Selecting a new set of defenders...");
	}
}

public void EventHook_TeamplayFlagEvent(Event event, const char[] name, bool dontBroadcast)
{
	int player = event.GetInt("player");
	int eventtype = event.GetInt("eventtype");
	
	switch (eventtype)
	{
		case TF_FLAGEVENT_PICKEDUP:
		{
			if (!IsFakeClient(player))
			{
				// Prevent the bomb carrier from being pushed around
				tf_avoidteammates_pushaway.ReplicateToClient(player, "1");
			}
			
			Player(player).UpgradeStart();
		}
		case TF_FLAGEVENT_DROPPED:
		{
			if (!IsFakeClient(player))
			{
				tf_avoidteammates_pushaway.ReplicateToClient(player, "0");
			}
		}
	}
}

public Action Timer_OnWaitingForPlayersEnd(Handle timer)
{
	if (!g_bInWaitingForPlayers)
		return Plugin_Continue;
	
	tf_mvm_min_players_to_start.IntValue = 0;
	g_bInWaitingForPlayers = false;
	
	SDKCall_ResetMap(GetPopulator());
	
	return Plugin_Continue;
}

public Action Timer_DeadTimer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if (client != 0 && IsClientInGame(client) && !IsPlayerAlive(client))
	{
		if (Player(client).HasAttribute(REMOVE_ON_DEATH))
		{
			ServerCommand("kickid %d", userid);
		}
		else if (Player(client).HasAttribute(BECOME_SPECTATOR_ON_DEATH))
		{
			g_bAllowTeamChange = true;
			TF2_ChangeClientTeam(client, TFTeam_Spectator);
			g_bAllowTeamChange = false;
		}
	}
	
	return Plugin_Continue;
}
