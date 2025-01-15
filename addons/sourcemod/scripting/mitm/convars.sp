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
	CreateConVar("mitm_version", PLUGIN_VERSION, "Plugin version.", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	CreateConVar("mitm_enabled", "1", "Whether the plugin is enabled.");
	mitm_developer = CreateConVar("mitm_developer", "0", "Toggle plugin developer mode.");
	mitm_custom_upgrades_file = CreateConVar("mitm_custom_upgrades_file", "", "Path to custom upgrades file, set to an empty string to use the default.");
	mitm_bot_spawn_hurry_time = CreateConVar("mitm_bot_spawn_hurry_time", "10", "The base time invaders have to leave their spawn, in seconds.");
	mitm_queue_points = CreateConVar("mitm_queue_points", "5", "Amount of queue points awarded to players that did not become defenders.", _, true, 1.0);
	mitm_rename_robots = CreateConVar("mitm_rename_robots", "0", "Whether to rename robots as they spawn.");
	mitm_bot_allow_suicide = CreateConVar("mitm_bot_allow_suicide", "0", "Whether to allow bots to suicide.");
	mitm_party_enabled = CreateConVar("mitm_party_enabled", "1", "Whether to allow players to create and join parties.");
	mitm_party_max_size = CreateConVar("mitm_party_max_size", "0", "Maximum size of player parties.", _, true, 0.0, true, 10.0);
	mitm_setup_time = CreateConVar("mitm_setup_time", "150", "Time for defenders to set up before the round automatically starts.");
	mitm_max_spawn_deaths = CreateConVar("mitm_max_spawn_deaths", "3", "How many times a player can die to the spawn timer before getting kicked.");
	mitm_defender_ping_limit = CreateConVar("mitm_defender_ping_limit", "200", "Maximum ping a client can have to play on the defender team.");
	mitm_shield_damage_drain_rate = CreateConVar("mitm_shield_damage_drain_rate", "0.05", "How much energy to drain for each point of damage to the shield.");
	mitm_bot_taunt_on_upgrade = CreateConVar("mitm_bot_taunt_on_upgrade", "1", "Whether bots should automatically taunt when the bomb levels up.");
	mitm_romevision = CreateConVar("mitm_romevision", "1", "Whether to allow romevision items to be generated.");
	
	tf_avoidteammates_pushaway = FindConVar("tf_avoidteammates_pushaway");
	tf_deploying_bomb_delay_time = FindConVar("tf_deploying_bomb_delay_time");
	tf_deploying_bomb_time = FindConVar("tf_deploying_bomb_time");
	tf_mvm_defenders_team_size = FindConVar("tf_mvm_defenders_team_size");
	tf_mvm_miniboss_scale = FindConVar("tf_mvm_miniboss_scale");
	tf_mvm_min_players_to_start = FindConVar("tf_mvm_min_players_to_start");
	tf_mvm_bot_allow_flag_carrier_to_fight = FindConVar("tf_mvm_bot_allow_flag_carrier_to_fight");
	tf_mvm_bot_flag_carrier_health_regen = FindConVar("tf_mvm_bot_flag_carrier_health_regen");
	tf_mvm_bot_flag_carrier_interval_to_1st_upgrade = FindConVar("tf_mvm_bot_flag_carrier_interval_to_1st_upgrade");
	tf_mvm_bot_flag_carrier_interval_to_2nd_upgrade = FindConVar("tf_mvm_bot_flag_carrier_interval_to_2nd_upgrade");
	tf_mvm_bot_flag_carrier_interval_to_3rd_upgrade = FindConVar("tf_mvm_bot_flag_carrier_interval_to_3rd_upgrade");
	tf_mvm_engineer_teleporter_uber_duration = FindConVar("tf_mvm_engineer_teleporter_uber_duration");
	tf_populator_debug = FindConVar("tf_populator_debug");
	tf_bot_difficulty = FindConVar("tf_bot_difficulty");
	tf_bot_engineer_building_health_multiplier = FindConVar("tf_bot_engineer_building_health_multiplier");
	tf_bot_suicide_bomb_range = FindConVar("tf_bot_suicide_bomb_range");
	tf_bot_suicide_bomb_friendly_fire = FindConVar("tf_bot_suicide_bomb_friendly_fire");
	tf_bot_taunt_victim_chance = FindConVar("tf_bot_taunt_victim_chance");
	tf_bot_always_full_reload = FindConVar("tf_bot_always_full_reload");
	tf_bot_flag_kill_on_touch = FindConVar("tf_bot_flag_kill_on_touch");
	tf_bot_melee_only = FindConVar("tf_bot_melee_only");
	mp_tournament_redteamname = FindConVar("mp_tournament_redteamname");
	mp_tournament_blueteamname = FindConVar("mp_tournament_blueteamname");
	mp_waitingforplayers_time = FindConVar("mp_waitingforplayers_time");
	phys_pushscale = FindConVar("phys_pushscale");
	
	char value[12];
	IntToString(MaxClients, value, sizeof(value));
	PSM_AddEnforcedConVar("tf_mvm_max_connected_players", value);
	
	PSM_AddPluginStateChangedHook(ConVars_OnPluginStateChanged);
}

static void ConVars_OnPluginStateChanged(bool bEnable)
{
	if (bEnable)
	{
		mitm_custom_upgrades_file.AddChangeHook(ConVarChanged_CustomUpgradesFile);
		mitm_party_enabled.AddChangeHook(ConVarChanged_PartyEnabled);
		tf_mvm_min_players_to_start.AddChangeHook(ConVarChanged_MinPlayersToStart);
	}
	else
	{
		mitm_custom_upgrades_file.RemoveChangeHook(ConVarChanged_CustomUpgradesFile);
		mitm_party_enabled.RemoveChangeHook(ConVarChanged_PartyEnabled);
		tf_mvm_min_players_to_start.RemoveChangeHook(ConVarChanged_MinPlayersToStart);
	}
}

static void ConVarChanged_CustomUpgradesFile(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (!g_pGameRules.IsValid())
		return;
	
	g_pGameRules.SetCustomUpgradesFile(newValue[0] ? newValue : DEFAULT_UPGRADES_FILE);
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
