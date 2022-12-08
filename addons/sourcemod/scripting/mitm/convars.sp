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
	mitm_developer = CreateConVar("mitm_developer", "0", "Toggle plugin developer mode.");
	mitm_defender_min_count = CreateConVar("mitm_defender_min_count", "6", "Minimum amount of defenders, regardless of player count.", _, _, _, true, 10.0);
	mitm_defender_max_count = CreateConVar("mitm_defender_max_count", "8", "Maximum amount of defenders on a full server.", _, _, _, true, 10.0);
	mitm_min_spawn_hurry_time = CreateConVar("mitm_min_spawn_hurry_time", "20.0", "The minimum time invaders have to leave their spawn, in seconds.");
	mitm_max_spawn_hurry_time = CreateConVar("mitm_max_spawn_hurry_time", "45.0", "The maximum time invaders have to leave their spawn, in seconds.");
	mitm_queue_points = CreateConVar("mitm_queue_points", "5", "Amount of queue points awarded to players that did not become defenders.", _, true, 1.0);
	mitm_rename_robots = CreateConVar("mitm_rename_robots", "0", "Whether to rename robots as they spawn.");
	mitm_annotation_lifetime = CreateConVar("mitm_annotation_lifetime", "30.0", "The lifetime of annotations shown to clients, in seconds.", _, true, 1.0);
	mitm_invader_allow_suicide = CreateConVar("mitm_invader_allow_suicide", "0", "Whether to allow invaders to suicide.");
	mitm_party_max_size = CreateConVar("mitm_party_max_size", "6", "Maximum size of player parties.", _, _, _, true, 10.0);
	mitm_setup_time = CreateConVar("mitm_setup_time", "150", "Time for defenders to set up before the round automatically starts.");
	mitm_disable_explosive_gas = CreateConVar("mitm_disable_explosive_gas", "1", "Whether to disable the 'Explode on Ignite' upgrade for the Gas Passer.");
	mitm_max_spawn_deaths = CreateConVar("mitm_max_spawn_deaths", "2", "How many times a player can die to the spawn timer before getting kicked.");
	
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
	mp_tournament_redteamname = FindConVar("mp_tournament_redteamname");
	mp_tournament_blueteamname = FindConVar("mp_tournament_blueteamname");
	mp_waitingforplayers_time = FindConVar("mp_waitingforplayers_time");
	sv_stepsize = FindConVar("sv_stepsize");
	phys_pushscale = FindConVar("phys_pushscale");
	
	tf_mvm_min_players_to_start.AddChangeHook(ConVarChanged_MinPlayersToStart);
}

static void ConVarChanged_MinPlayersToStart(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (g_bInWaitingForPlayers)
	{
		// Don't allow maps to modify this using point_servercommand
		convar.IntValue = MaxClients + 1;
	}
}
