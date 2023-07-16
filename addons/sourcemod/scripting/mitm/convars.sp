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

void ConVars_Init()
{
	CreateConVar("sm_mitm_version", PLUGIN_VERSION, "Plugin version.", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	sm_mitm_developer = CreateConVar("sm_mitm_developer", "0", "Toggle plugin developer mode.");
	sm_mitm_defender_count = CreateConVar("sm_mitm_defender_count", "6", "Amount of defenders.", _, true, 1.0, true, 10.0);
	sm_mitm_custom_upgrades_file = CreateConVar("sm_mitm_custom_upgrades_file", "", "Path to custom upgrades file, set to an empty string to use the default.");
	sm_mitm_spawn_hurry_time = CreateConVar("sm_mitm_spawn_hurry_time", "10", "The base time invaders have to leave their spawn, in seconds.");
	sm_mitm_queue_points = CreateConVar("sm_mitm_queue_points", "5", "Amount of queue points awarded to players that did not become defenders.", _, true, 1.0);
	sm_mitm_rename_robots = CreateConVar("sm_mitm_rename_robots", "0", "Whether to rename robots as they spawn.");
	sm_mitm_annotation_lifetime = CreateConVar("sm_mitm_annotation_lifetime", "60", "The lifetime of annotations shown to clients, in seconds.", _, true, 1.0);
	sm_mitm_invader_allow_suicide = CreateConVar("sm_mitm_invader_allow_suicide", "0", "Whether to allow invaders to suicide.");
	sm_mitm_party_enabled = CreateConVar("sm_mitm_party_enabled", "1", "Whether to allow players to create and join parties.");
	sm_mitm_party_max_size = CreateConVar("sm_mitm_party_max_size", "0", "Maximum size of player parties.", _, true, 0.0, true, 10.0);
	sm_mitm_setup_time = CreateConVar("sm_mitm_setup_time", "150", "Time for defenders to set up before the round automatically starts.");
	sm_mitm_max_spawn_deaths = CreateConVar("sm_mitm_max_spawn_deaths", "2", "How many times a player can die to the spawn timer before getting kicked.");
	mitm_use_bot_viewmodels = CreateConVar("mitm_use_bot_viewmodels", "1", "Whether to use custom bot viewmodels.");
	
	tf_avoidteammates_pushaway = FindConVar("tf_avoidteammates_pushaway");
	tf_deploying_bomb_delay_time = FindConVar("tf_deploying_bomb_delay_time");
	tf_deploying_bomb_time = FindConVar("tf_deploying_bomb_time");
	tf_bot_engineer_building_health_multiplier = FindConVar("tf_bot_engineer_building_health_multiplier");
	tf_mvm_miniboss_scale = FindConVar("tf_mvm_miniboss_scale");
	tf_mvm_min_players_to_start = FindConVar("tf_mvm_min_players_to_start");
	tf_mvm_bot_allow_flag_carrier_to_fight = FindConVar("tf_mvm_bot_allow_flag_carrier_to_fight");
	tf_mvm_bot_flag_carrier_health_regen = FindConVar("tf_mvm_bot_flag_carrier_health_regen");
	tf_mvm_bot_flag_carrier_interval_to_1st_upgrade = FindConVar("tf_mvm_bot_flag_carrier_interval_to_1st_upgrade");
	tf_mvm_bot_flag_carrier_interval_to_2nd_upgrade = FindConVar("tf_mvm_bot_flag_carrier_interval_to_2nd_upgrade");
	tf_mvm_bot_flag_carrier_interval_to_3rd_upgrade = FindConVar("tf_mvm_bot_flag_carrier_interval_to_3rd_upgrade");
	tf_mvm_engineer_teleporter_uber_duration = FindConVar("tf_mvm_engineer_teleporter_uber_duration");
	tf_populator_debug = FindConVar("tf_populator_debug");
	tf_bot_suicide_bomb_range = FindConVar("tf_bot_suicide_bomb_range");
	tf_bot_suicide_bomb_friendly_fire = FindConVar("tf_bot_suicide_bomb_friendly_fire");
	tf_bot_taunt_victim_chance = FindConVar("tf_bot_taunt_victim_chance");
	tf_bot_always_full_reload = FindConVar("tf_bot_always_full_reload");
	tf_bot_flag_kill_on_touch = FindConVar("tf_bot_flag_kill_on_touch");
	tf_bot_melee_only = FindConVar("tf_bot_melee_only");
	mp_tournament_redteamname = FindConVar("mp_tournament_redteamname");
	mp_tournament_blueteamname = FindConVar("mp_tournament_blueteamname");
	mp_waitingforplayers_time = FindConVar("mp_waitingforplayers_time");
	sv_stepsize = FindConVar("sv_stepsize");
	phys_pushscale = FindConVar("phys_pushscale");
	
	sm_mitm_custom_upgrades_file.AddChangeHook(ConVarChanged_CustomUpgradesFile);
	sm_mitm_party_enabled.AddChangeHook(ConVarChanged_PartyEnabled);
	tf_mvm_min_players_to_start.AddChangeHook(ConVarChanged_MinPlayersToStart);
}

static void ConVarChanged_CustomUpgradesFile(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (!g_pGameRules.IsValid())
		return;
	
	g_pGameRules.SetCustomUpgradesFile(newValue[0] ? newValue : "scripts/items/mvm_upgrades.txt");
}

static void ConVarChanged_PartyEnabled(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar.BoolValue)
		return;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!CTFPlayer(client).IsInAParty())
			continue;
		
		CTFPlayer(client).LeaveParty();
		CancelClientMenu(client);
	}
}

static void ConVarChanged_MinPlayersToStart(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (!g_bInWaitingForPlayers)
		return;
	
	// Don't allow maps to modify this using point_servercommand
	convar.IntValue = MaxClients + 1;
}
