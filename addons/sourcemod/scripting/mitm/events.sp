/**
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

void EventHook_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (TF2_GetClientTeam(client) == TFTeam_Invaders)
	{
		if (TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			CTFBotSpyLeaveSpawnRoom_OnStart(client);
		}
		
		CreateTimer(0.1, Timer_UpdatePlayerGlow, GetClientUserId(client));
	}
}

Action Timer_UpdatePlayerGlow(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client != 0)
	{
		if (TF2_GetClientTeam(client) == TFTeam_Invaders && IsPlayerAlive(client))
		{
			// Create a new glow
			CreateEntityGlow(client);
		}
	}
	
	return Plugin_Continue;
}

void EventHook_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int victim = GetClientOfUserId(userid);
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if (TF2_GetClientTeam(victim) == TFTeam_Invaders)
	{
		// Replicate behavior of CTFBotDead::Update
		CreateTimer(5.0, Timer_DeadTimer, userid);
		
		// Remove any glows attached to us
		RemoveEntityGlow(victim);
	}
	else if (IsEntityClient(attacker) && TF2_GetClientTeam(victim) == TFTeam_Defenders && TF2_GetClientTeam(attacker) == TFTeam_Invaders)
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

Action EventHook_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	TFTeam team = view_as<TFTeam>(event.GetInt("team"));
	
	// Only show when a new defender joins
	bool bSilent = (team == TFTeam_Spectator) || (team == TFTeam_Invaders);
	event.SetInt("silent", bSilent);
	
	Player(client).SetPrevMission(NO_MISSION);
	TF2Attrib_RemoveAll(client);
	// Clear Sound
	Player(client).StopIdleSound();
	
	if (team == TFTeam_Invaders)
	{
		SetEntityFlags(client, GetEntityFlags(client) | FL_FAKECLIENT);
	}
	else
	{
		Player(client).ResetOnTeamChange();
		Player(client).ResetName();
		
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		
		SetEntityFlags(client, GetEntityFlags(client) & ~FL_FAKECLIENT);
	}
	
	return Plugin_Changed;
}

void EventHook_PostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	
	if (TF2_GetClientTeam(client) == TFTeam_Invaders)
	{
		// wait a frame before applying weapon restrictions
		RequestFrame(RequestFrameCallback_ApplyWeaponRestrictions, userid);
	}
}

void RequestFrameCallback_ApplyWeaponRestrictions(int userid)
{
	int client = GetClientOfUserId(userid);
	if (client)
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
		
		// equip our required weapon
		Player(client).EquipRequiredWeapon();
		
		// switch to special secondary weapon if we have one
		int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if (weapon != -1)
		{
			int weaponID = TF2Util_GetWeaponID(weapon);
			if (weaponID == TF_WEAPON_MEDIGUN ||
				weaponID == TF_WEAPON_BUFF_ITEM ||
				weaponID == TF_WEAPON_LUNCHBOX ||
				weaponID == TF_WEAPON_JAR ||
				weaponID == TF_WEAPON_JAR_MILK ||
				weaponID == TF_WEAPON_JAR_GAS ||
				weaponID == TF_WEAPON_ROCKETPACK ||
				weaponID == TF_WEAPON_MECHANICAL_ARM ||
				weaponID == TF_WEAPON_LASER_POINTER)
			{
				SDKCall_WeaponSwitch(client, weapon);
			}
		}
	}
}

void EventHook_PlayerBuiltObject(Event event, const char[] name, bool dontBroadcast)
{
	int builder = GetClientOfUserId(event.GetInt("userid"));
	TFObjectType type = view_as<TFObjectType>(event.GetInt("object"));
	int index = event.GetInt("index");
	
	if (TF2_GetClientTeam(builder) == TFTeam_Invaders)
	{
		float origin[3];
		GetEntPropVector(index, Prop_Data, "m_vecAbsOrigin", origin);
		
		// CTFBotMvMEngineerBuildTeleportExit
		if (type == TFObject_Teleporter && TF2_GetObjectMode(index) == TFObjectMode_Exit)
		{
			SDKCall_PushAllPlayersAway(origin, 400.0, 500.0, TFTeam_Red);
			
			Entity(index).SetTeleportWhere(Player(builder).m_teleportWhereName);
			
			// engineer bots create level 1 teleporters with increased health
			int iHealth = RoundToFloor(SDKCall_GetMaxHealthForCurrentLevel(index) * tf_bot_engineer_building_health_multiplier.FloatValue);
			SetEntProp(index, Prop_Data, "m_iMaxHealth", iHealth);
			SetEntProp(index, Prop_Data, "m_iHealth", iHealth);
			
			// the teleporter owns this hint now
			int hint = GetNestTeleporterHint(builder);
			if (hint != -1)
			{
				SetEntityOwner(hint, index);
			}
		}
		// CTFBotMvMEngineerBuildSentryGun
		else if (type == TFObject_Sentry)
		{
			SDKCall_PushAllPlayersAway(origin, 400.0, 500.0, TFTeam_Red);
			
			// engineer bots create pre-built level 3 sentry guns
			SetEntProp(index, Prop_Data, "m_nDefaultUpgradeLevel", 2);
			
			// the sentry owns this hint now
			int hint = GetNestSentryHint(builder);
			if (hint != -1)
			{
				SetEntityOwner(hint, index);
			}
		}
	}
}

void EventHook_TeamplayRoundStart(Event event, const char[] name, bool dontBroadcast)
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
	}
}

void EventHook_TeamplayFlagEvent(Event event, const char[] name, bool dontBroadcast)
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
				tf_avoidteammates_pushaway.ReplicateToClient(player, "0");
			}
			
			CTFBotDeliverFlag_OnStart(player);
		}
		case TF_FLAGEVENT_DROPPED, TF_FLAGEVENT_CAPTURED:
		{
			if (!IsFakeClient(player))
			{
				tf_avoidteammates_pushaway.ReplicateToClient(player, "1");
			}
			
			CTFBotDeliverFlag_OnEnd(player);
		}
	}
}

Action Timer_OnWaitingForPlayersEnd(Handle timer)
{
	if (!g_bInWaitingForPlayers)
		return Plugin_Continue;
	
	tf_mvm_min_players_to_start.IntValue = 0;
	g_bInWaitingForPlayers = false;
	
	GetPopulationManager().ResetMap();
	
	return Plugin_Continue;
}

Action Timer_DeadTimer(Handle timer, int userid)
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
