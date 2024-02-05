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

enum struct ConVarData
{
	char name[COMMAND_MAX_LENGTH];
	char value[COMMAND_MAX_LENGTH];
	char prev_value[COMMAND_MAX_LENGTH];
}

static StringMap g_hConVars;

void ConVars_Init()
{
	g_hConVars = new StringMap();
	
	CreateConVar("sm_mitm_version", PLUGIN_VERSION, "Plugin version.", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	sm_mitm_enabled = CreateConVar("sm_mitm_enabled", "1", "Whether the plugin is enabled.");
	sm_mitm_enabled.AddChangeHook(ConVarChanged_PluginEnabled);
	sm_mitm_developer = CreateConVar("sm_mitm_developer", "0", "Toggle plugin developer mode.");
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
	sm_mitm_defender_ping_limit = CreateConVar("sm_mitm_defender_ping_limit", "200", "Maximum ping a client can have to play on the defender team.");
	sm_mitm_shield_damage_drain_rate = CreateConVar("sm_mitm_shield_damage_drain_rate", "0.03", "How much energy to drain for each point of damage to the shield.");
	
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
	sv_stepsize = FindConVar("sv_stepsize");
	phys_pushscale = FindConVar("phys_pushscale");
	
	char value[12];
	IntToString(MaxClients, value, sizeof(value));
	ConVars_AddConVar("tf_mvm_max_connected_players", value);
}

void ConVars_Toggle(bool bEnable)
{
	if (bEnable)
	{
		sm_mitm_custom_upgrades_file.AddChangeHook(ConVarChanged_CustomUpgradesFile);
		sm_mitm_party_enabled.AddChangeHook(ConVarChanged_PartyEnabled);
		tf_mvm_min_players_to_start.AddChangeHook(ConVarChanged_MinPlayersToStart);
	}
	else
	{
		sm_mitm_custom_upgrades_file.RemoveChangeHook(ConVarChanged_CustomUpgradesFile);
		sm_mitm_party_enabled.RemoveChangeHook(ConVarChanged_PartyEnabled);
		tf_mvm_min_players_to_start.RemoveChangeHook(ConVarChanged_MinPlayersToStart);
	}
	
	StringMapSnapshot snapshot = g_hConVars.Snapshot();
	for (int i = 0; i < snapshot.Length; i++)
	{
		int size = snapshot.KeyBufferSize(i);
		char[] key = new char[size];
		snapshot.GetKey(i, key, size);
		
		if (bEnable)
		{
			ConVars_Enable(key);
		}
		else
		{
			ConVars_Disable(key);
		}
	}
	delete snapshot;
}

static void ConVars_AddConVar(const char[] name, const char[] value)
{
	ConVar convar = FindConVar(name);
	if (convar)
	{
		ConVarData data;
		strcopy(data.name, sizeof(data.name), name);
		strcopy(data.value, sizeof(data.value), value);
		g_hConVars.SetArray(name, data, sizeof(data));
		
		if (g_bEnabled)
		{
			ConVars_Enable(name);
		}
	}
	else
	{
		LogError("Failed to find convar: %s", name);
	}
}

static void ConVars_Enable(const char[] name)
{
	ConVarData data;
	if (g_hConVars.GetArray(name, data, sizeof(data)))
	{
		ConVar convar = FindConVar(data.name);
		
		// Store the current value so we can later reset the convar to it
		convar.GetString(data.prev_value, sizeof(data.prev_value));
		g_hConVars.SetArray(name, data, sizeof(data));
		
		// Update the current value
		convar.SetString(data.value);
		convar.AddChangeHook(ConVarChanged_OnTrackedConVarChanged);
	}
	else
	{
		LogError("Failed to enable convar: %s", name);
	}
}

static void ConVars_Disable(const char[] name)
{
	ConVarData data;
	if (g_hConVars.GetArray(name, data, sizeof(data)))
	{
		g_hConVars.SetArray(name, data, sizeof(data));
		
		// Restore the convar value
		ConVar convar = FindConVar(data.name);
		convar.RemoveChangeHook(ConVarChanged_OnTrackedConVarChanged);
		convar.SetString(data.prev_value);
	}
	else
	{
		LogError("Failed to disable convar: %s", name);
	}
}

static void ConVarChanged_OnTrackedConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	char[] name = new char[sizeof(ConVarData::name)];
	convar.GetName(name, sizeof(ConVarData::name));
	
	ConVarData data;
	if (g_hConVars.GetArray(name, data, sizeof(data)))
	{
		if (!StrEqual(newValue, data.value))
		{
			strcopy(data.prev_value, sizeof(data.prev_value), newValue);
			g_hConVars.SetArray(name, data, sizeof(data));
			
			// Restore our wanted value
			convar.SetString(data.value);
		}
	}
}

static void ConVarChanged_PluginEnabled(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (g_bEnabled != convar.BoolValue)
	{
		TogglePlugin(convar.BoolValue);
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
