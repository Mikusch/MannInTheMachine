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

void Events_Init()
{
	HookEvent("player_spawn", EventHook_PlayerSpawn);
	HookEvent("player_death", EventHook_PlayerDeath);
	HookEvent("player_team", EventHook_PlayerTeam, EventHookMode_Pre);
	HookEvent("post_inventory_application", EventHook_PostInventoryApplication);
	HookEvent("player_builtobject", EventHook_PlayerBuiltObject);
	HookEvent("object_destroyed", EventHook_ObjectDestroyed);
	HookEvent("object_detonated", EventHook_ObjectDestroyed);
	HookEvent("teamplay_point_captured", EventHook_TeamplayPointCaptured);
	HookEvent("teamplay_flag_event", EventHook_TeamplayFlagEvent);
	HookEvent("teams_changed", EventHook_TeamsChanged);
}

static void EventHook_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client == 0)
		return;
	
	CTFPlayer(client).Spawn();
	
	CTFPlayer(client).m_annotationTimer = CreateTimer(1.0, Timer_CheckGateBotAnnotation, GetClientUserId(client), TIMER_REPEAT);
}

static void EventHook_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (victim == 0)
		return;
	
	if (TF2_GetClientTeam(victim) == TFTeam_Invaders)
	{
		HideAnnotation(victim, MITM_HINT_MASK | victim);
	}
}

static Action EventHook_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client == 0)
		return Plugin_Continue;
	
	TFTeam team = view_as<TFTeam>(event.GetInt("team"));
	
	// Only show when a new defender joins
	bool bSilent = team != TFTeam_Defenders;
	event.SetInt("silent", bSilent);
	
	if (IsMannVsMachineMode())
	{
		CTFPlayer(client).SetPrevMission(NO_MISSION);
		CTFPlayer(client).ClearAllAttributes();
		// Clear Sound
		CTFPlayer(client).StopIdleSound();
		
		if (team != TFTeam_Invaders)
		{
			SetVariantString("");
			AcceptEntityInput(client, "SetCustomModel");
			
			CTFPlayer(client).ResetOnTeamChange();
		}
	}
	
	return Plugin_Changed;
}

static void EventHook_PostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	
	int client = GetClientOfUserId(userid);
	if (client == 0)
		return;
	
	if (TF2_GetClientTeam(client) == TFTeam_Invaders)
	{
		// wait a frame before applying weapon restrictions
		RequestFrame(RequestFrameCallback_ApplyWeaponRestrictions, userid);
	}
}

static void RequestFrameCallback_ApplyWeaponRestrictions(int userid)
{
	int client = GetClientOfUserId(userid);
	if (client == 0)
		return;
	
	// equip our required weapon
	CTFPlayer(client).EquipRequiredWeapon();
	
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
			TF2Util_SetPlayerActiveWeapon(client, weapon);
		}
	}
}

static void EventHook_PlayerBuiltObject(Event event, const char[] name, bool dontBroadcast)
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
			SDKCall_CTFGameRules_PushAllPlayersAway(origin, 400.0, 500.0, TFTeam_Red);
			
			Entity(index).SetTeleportWhere(CTFPlayer(builder).m_teleportWhereName);
			
			// engineer bots create level 1 teleporters with increased health
			int iHealth = RoundToFloor(SDKCall_CBaseObject_GetMaxHealthForCurrentLevel(index) * tf_bot_engineer_building_health_multiplier.FloatValue);
			SetEntProp(index, Prop_Data, "m_iMaxHealth", iHealth);
			SetEntProp(index, Prop_Data, "m_iHealth", iHealth);
			
			// the teleporter owns this hint now
			int hint = FindTeleporterHintForPlayer(builder);
			if (hint != -1)
			{
				SetEntityOwner(hint, index);
			}
		}
		// CTFBotMvMEngineerBuildSentryGun
		else if (type == TFObject_Sentry)
		{
			SDKCall_CTFGameRules_PushAllPlayersAway(origin, 400.0, 500.0, TFTeam_Red);
			
			// engineer bots create pre-built level 3 sentry guns
			SetEntProp(index, Prop_Data, "m_nDefaultUpgradeLevel", 2);
			
			// the sentry owns this hint now
			int hint = FindSentryHintForPlayer(builder);
			if (hint != -1)
			{
				SetEntityOwner(hint, index);
			}
		}
	}
}

static void EventHook_ObjectDestroyed(Event event, const char[] name, bool dontBroadcast)
{
	int index = event.GetInt("index");
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		if (CTFPlayer(client).HasMission(MISSION_DESTROY_SENTRIES) && index == CTFPlayer(client).GetMissionTarget())
		{
			char text[64];
			Format(text, sizeof(text), "%T", "Invader_DestroySentries_DetonateHere", client);
			
			float worldPos[3];
			GetEntPropVector(index, Prop_Data, "m_vecAbsOrigin", worldPos);
			
			ShowAnnotation(client, MITM_HINT_MASK | client, text, _, worldPos, sm_mitm_annotation_lifetime.FloatValue, "coach/coach_go_here.wav");
		}
	}
}

static void EventHook_TeamplayPointCaptured(Event event, const char[] name, bool dontBroadcast)
{
	TFTeam team = view_as<TFTeam>(event.GetInt("team"));
	
	if (team == TFTeam_Invaders)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client))
				continue;
			
			if (!IsPlayerAlive(client))
				continue;
			
			if (TF2_GetClientTeam(client) != team)
				continue;
			
			// hide current annotation and recreate later
			HideAnnotation(client, MITM_HINT_MASK | client);
			CTFPlayer(client).m_annotationTimer = CreateTimer(1.0, Timer_CheckGateBotAnnotation, GetClientUserId(client), TIMER_REPEAT);
		}
	}
}

void EventHook_TeamplayFlagEvent(Event event, const char[] name, bool dontBroadcast)
{
	int player = event.GetInt("player");
	int eventtype = event.GetInt("eventtype");
	TFTeam team = view_as<TFTeam>(event.GetInt("team"));
	
	if (team == TFTeam_Invaders && eventtype == TF_FLAGEVENT_CAPTURED)
	{
		CPrintToChatAll("%s %t", PLUGIN_TAG, "Invader_Deployed", player, GetEntProp(player, Prop_Data, "m_iHealth"), TF2Util_GetEntityMaxHealth(player));
	}
}

static void EventHook_TeamsChanged(Event event, const char[] name, bool dontBroadcast)
{
	if (g_pObjectiveResource.GetMannVsMachineIsBetweenWaves() && GameRules_GetRoundState() != RoundState_GameOver && !sm_mitm_developer.BoolValue)
	{
		RequestFrame(RequestFrameCallback_FindReplacementDefender);
	}
}

static void RequestFrameCallback_FindReplacementDefender()
{
	FindReplacementDefender();
}

static Action Timer_CheckGateBotAnnotation(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if (client == 0)
		return Plugin_Stop;
	
	if (timer != CTFPlayer(client).m_annotationTimer)
		return Plugin_Stop;
	
	if (!IsClientInGame(client))
		return Plugin_Stop;
	
	if (!IsPlayerAlive(client))
		return Plugin_Stop;
	
	if (TF2_GetClientTeam(client) != TFTeam_Invaders)
		return Plugin_Stop;
	
	// we are gate stunned - wait until it wears off
	if (TF2_IsPlayerInCondition(client, TFCond_MVMBotRadiowave))
		return Plugin_Continue;
	
	ShowGateBotAnnotation(client);
	return Plugin_Stop;
}
