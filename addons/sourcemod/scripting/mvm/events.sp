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
	HookEvent("player_death", EventHook_PlayerDeath);
	HookEvent("player_team", EventHook_PlayerTeam);
	HookEvent("teamplay_round_start", EventHook_TeamplayRoundStart);
}

public void EventHook_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	TFTeam team = view_as<TFTeam>(event.GetInt("team"));
	
	TF2Attrib_RemoveAll(client);
	// Clear Sound
	Player(client).StopIdleSound();
	
	if (team == TFTeam_Spectator)
	{
		Player(client).Reset();
	}
	else if (team == TFTeam_Red)
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
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

public void EventHook_TeamplayRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bWaitingForPlayersOver)
		return;
	
	// Set to a high value to prevent readying up
	tf_mvm_min_players_to_start.IntValue = MaxClients + 1;
	
	CreateTimer(mp_waitingforplayers_time.FloatValue, Timer_BeginGame);
}

public Action Timer_BeginGame(Handle timer)
{
	g_bWaitingForPlayersOver = true;
	
	// Let defenders ready up
	tf_mvm_min_players_to_start.IntValue = 0;
	
	SDKCall_ResetMap(GetPopulator());
	
	return Plugin_Continue;
}

public Action Timer_DeadTimer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if (client != 0 && !IsPlayerAlive(client))
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
