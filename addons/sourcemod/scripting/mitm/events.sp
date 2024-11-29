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
	PSM_AddEventHook("player_spawn", EventHook_PlayerSpawn);
	PSM_AddEventHook("player_death", EventHook_PlayerDeath);
	PSM_AddEventHook("player_team", EventHook_PlayerTeam, EventHookMode_Pre);
	PSM_AddEventHook("post_inventory_application", EventHook_PostInventoryApplication);
	PSM_AddEventHook("player_builtobject", EventHook_PlayerBuiltObject);
	PSM_AddEventHook("teamplay_point_captured", EventHook_TeamplayPointCaptured);
	PSM_AddEventHook("teamplay_flag_event", EventHook_TeamplayFlagEvent);
	PSM_AddEventHook("teams_changed", EventHook_TeamsChanged);
	PSM_AddEventHook("pve_win_panel", EventHook_PVEWinPanel);
	PSM_AddEventHook("mvm_wave_complete", EventHook_MvMWaveComplete);
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
		CTFPlayer(victim).HideAnnotation(MITM_HINT_MASK | victim);
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
	if (!CTFPlayer(client).EquipRequiredWeapon())
	{
		SDKCall_CBaseCombatCharacter_SwitchToNextBestWeapon(client, -1);
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
			
			CTFPlayer player = CTFPlayer(client);
			
			// hide current annotation and recreate later
			player.HideAnnotation(MITM_HINT_MASK | client);
			player.m_annotationTimer = CreateTimer(1.0, Timer_CheckGateBotAnnotation, GetClientUserId(client), TIMER_REPEAT);
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

static void EventHook_PVEWinPanel(Event event, const char[] name, bool dontBroadcast)
{
	TFTeam iWinningTeam = view_as<TFTeam>(event.GetInt("winning_team"));
	if (iWinningTeam == TFTeam_Invaders)
		g_nNumConsecutiveWipes++;
	
	int points = sm_mitm_queue_points.IntValue;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		CTFPlayer player = CTFPlayer(client);
		
		if (player.m_hasDisabledDefenderThisRound)
		{
			player.m_hasDisabledDefenderThisRound = false;
			
			// Don't let players earn queue points if they disabled the queue this round.
			// Some cheeky bastards buffer up queue points to play together anyway.
			if (!sm_mitm_party_enabled.BoolValue)
				continue;
		}
		
		if (!player.IsInvader())
			continue;
		
		if (player.HasPreference(PREF_DEFENDER_DISABLE_QUEUE))
			continue;
		
		if (!Forwards_OnIsValidDefender(client))
			continue;
		
		player.AddQueuePoints(points);
		CPrintToChat(client, "%s %t", PLUGIN_TAG, "Queue_AwardedQueuePoints", points, player.GetQueuePoints());
	}
}

static void EventHook_MvMWaveComplete(Event event, const char[] name, bool dontBroadcast)
{
	g_nNumConsecutiveWipes = 0;
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
