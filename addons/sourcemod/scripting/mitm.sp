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

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <clientprefs>
#include <dhooks>
#include <tf2attributes>
#include <tf_econ_data>
#include <tf2utils>
#include <loadsoundscript>
#include <cbasenpc>
#include <cbasenpc/tf/nav>
#include <morecolors>
#include <smmem>
#include <sourcescramble>
#include <vscript>
#include <mitm>

// Uncomment this for diagnostic messages in server console (very verbose)
// #define DEBUG

#define PLUGIN_VERSION	"1.0.0"

// Global entities
CPopulationManager g_pPopulationManager = view_as<CPopulationManager>(INVALID_ENT_REFERENCE);
CTFObjectiveResource g_pObjectiveResource = view_as<CTFObjectiveResource>(INVALID_ENT_REFERENCE);
CTFGameRules g_pGameRules = view_as<CTFGameRules>(INVALID_ENT_REFERENCE);

// Other globals
Handle g_hWarningHudSync;
bool g_bInWaitingForPlayers;
bool g_bAllowTeamChange;	// Bypass CTFGameRules::GetTeamAssignmentOverride?
bool g_bForceFriendlyFire;
bool g_bInEndlessRollEscalation;

// Plugin ConVars
ConVar sm_mitm_developer;
ConVar sm_mitm_defender_count;
ConVar sm_mitm_custom_upgrades_file;
ConVar sm_mitm_spawn_hurry_time;
ConVar sm_mitm_queue_points;
ConVar sm_mitm_rename_robots;
ConVar sm_mitm_annotation_lifetime;
ConVar sm_mitm_invader_allow_suicide;
ConVar sm_mitm_party_enabled;
ConVar sm_mitm_party_max_size;
ConVar sm_mitm_setup_time;
ConVar sm_mitm_max_spawn_deaths;

// Game ConVars
ConVar tf_avoidteammates_pushaway;
ConVar tf_deploying_bomb_delay_time;
ConVar tf_deploying_bomb_time;
ConVar tf_bot_engineer_building_health_multiplier;
ConVar tf_mvm_miniboss_scale;
ConVar tf_mvm_min_players_to_start;
ConVar tf_mvm_bot_allow_flag_carrier_to_fight;
ConVar tf_mvm_bot_flag_carrier_health_regen;
ConVar tf_mvm_bot_flag_carrier_interval_to_1st_upgrade;
ConVar tf_mvm_bot_flag_carrier_interval_to_2nd_upgrade;
ConVar tf_mvm_bot_flag_carrier_interval_to_3rd_upgrade;
ConVar tf_mvm_engineer_teleporter_uber_duration;
ConVar tf_populator_debug;
ConVar tf_bot_suicide_bomb_range;
ConVar tf_bot_suicide_bomb_friendly_fire;
ConVar tf_bot_taunt_victim_chance;
ConVar tf_bot_always_full_reload;
ConVar tf_bot_flag_kill_on_touch;
ConVar tf_bot_melee_only;
ConVar mp_tournament_redteamname;
ConVar mp_tournament_blueteamname;
ConVar mp_waitingforplayers_time;
ConVar sv_stepsize;
ConVar phys_pushscale;

#include "mitm/shareddefs.sp"

#include "mitm/clientprefs.sp"
#include "mitm/console.sp"
#include "mitm/convars.sp"
#include "mitm/data.sp"
#include "mitm/dhooks.sp"
#include "mitm/entity.sp"
#include "mitm/events.sp"
#include "mitm/forwards.sp"
#include "mitm/hooks.sp"
#include "mitm/mempatches.sp"
#include "mitm/party.sp"
#include "mitm/queue.sp"
#include "mitm/offsets.sp"
#include "mitm/menus.sp"
#include "mitm/natives.sp"
#include "mitm/sdkcalls.sp"
#include "mitm/sdkhooks.sp"
#include "mitm/tf_bot_squad.sp"
#include "mitm/util.sp"

#include "mitm/behavior/engineer/mvm_engineer/tf_bot_mvm_engineer_idle.sp"
#include "mitm/behavior/engineer/mvm_engineer/tf_bot_mvm_engineer_teleport_spawn.sp"
#include "mitm/behavior/medic/tf_bot_medic_heal.sp"
#include "mitm/behavior/missions/tf_bot_mission_suicide_bomber.sp"
#include "mitm/behavior/scenario/capture_the_flag/tf_bot_deliver_flag.sp"
#include "mitm/behavior/scenario/capture_the_flag/tf_bot_fetch_flag.sp"
#include "mitm/behavior/scenario/capture_the_flag/tf_bot_push_to_capture_point.sp"
#include "mitm/behavior/sniper/tf_bot_sniper_lurk.sp"
#include "mitm/behavior/spy/tf_bot_spy_leave_spawn_room.sp"
#include "mitm/behavior/squad/tf_bot_escort_squad_leader.sp"
#include "mitm/behavior/tf_bot_behavior.sp"
#include "mitm/behavior/tf_bot_dead.sp"
#include "mitm/behavior/tf_bot_mvm_deploy_bomb.sp"
#include "mitm/behavior/tf_bot_scenario_monitor.sp"
#include "mitm/behavior/tf_bot_tactical_monitor.sp"
#include "mitm/behavior/tf_bot_taunt.sp"
#include "mitm/behavior/tf_bot_use_item.sp"

public Plugin myinfo =
{
	name = "Mann in the Machine",
	author = "Mikusch",
	description = "Mann vs. Machine, but as a 32-player PvP gamemode.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Mikusch/MannInTheMachine"
}

public void OnPluginStart()
{
	g_hWarningHudSync = CreateHudSynchronizer();
	
	LoadTranslations("common.phrases");
	LoadTranslations("mitm.phrases");
	
	// Init bot actions
	CTFBotMainAction.Init();
	CTFBotDead.Init();
	CTFBotDeliverFlag.Init();
	CTFBotEscortSquadLeader.Init();
	CTFBotFetchFlag.Init();
	CTFBotMedicHeal.Init();
	CTFBotMissionSuicideBomber.Init();
	CTFBotMvMDeployBomb.Init();
	CTFBotMvMEngineerIdle.Init();
	CTFBotMvMEngineerTeleportSpawn.Init();
	CTFBotPushToCapturePoint.Init();
	CTFBotScenarioMonitor.Init();
	CTFBotSniperLurk.Init();
	CTFBotSpyLeaveSpawnRoom.Init();
	CTFBotTacticalMonitor.Init();
	CTFBotTaunt.Init();
	CTFBotUseItem.Init();
	
	// Install player action factory
	CEntityFactory hEntityFactory = new CEntityFactory("player");
	hEntityFactory.DeriveFromClass("player");
	hEntityFactory.AttachNextBot(CreateNextBotPlayer);
	hEntityFactory.SetInitialActionFactory(CTFBotMainAction.GetFactory());
	hEntityFactory.Install();
	
	// Init plugin functions
	Console_Init();
	ConVars_Init();
	Events_Init();
	Forwards_Init();
	Hooks_Init();
	ClientPrefs_Init();
	Party_Init();
	
	GameData hGameData = new GameData("mitm");
	if (hGameData)
	{
		// Init plugin functions requiring gamedata
		DHooks_Init(hGameData);
		MemPatches_Init(hGameData);
		Offsets_Init(hGameData);
		SDKCalls_Init(hGameData);
		
		delete hGameData;
	}
	else
	{
		SetFailState("Could not find mitm gamedata");
	}
	
	for (int client = 1; client <= MaxClients; client++)
	{
		// Init player properties
		CTFPlayer(client).Init();
		
		if (IsClientInGame(client))
		{
			OnClientPutInServer(client);
		}
	}
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		char classname[64];
		if (GetEntityClassname(entity, classname, sizeof(classname)))
		{
			OnEntityCreated(entity, classname);
		}
	}
}

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int maxlen)
{
	RegPluginLibrary("mitm");
	
	Natives_Init();
	
	return APLRes_Success;
}

public void OnMapStart()
{
	g_bInWaitingForPlayers = false;
	
	PrecacheSound("ui/system_message_alert.wav");
	PrecacheSound(")mvm/mvm_tele_activate.wav");
	
	DHooks_HookGamerules();
	
	// Add bot icons to the downloads table
	DirectoryListing directory = OpenDirectory("materials/hud");
	if (directory)
	{
		char file[PLATFORM_MAX_PATH];
		FileType type;
		while (directory.GetNext(file, sizeof(file), type))
		{
			Format(file, sizeof(file), "materials/hud/%s", file);
			AddFileToDownloadsTable(file);
		}
	}
	delete directory;
}

public void OnConfigsExecuted()
{
	char path[PLATFORM_MAX_PATH];
	sm_mitm_custom_upgrades_file.GetString(path, sizeof(path));
	
	if (path[0] && g_pGameRules.IsValid())
	{
		g_pGameRules.SetCustomUpgradesFile(path);
	}
}

public void OnClientPutInServer(int client)
{
	DHooks_OnClientPutInServer(client);
	SDKHooks_OnClientPutInServer(client);
	
	CTFPlayer(client).Reset();
	
	if (AreClientCookiesCached(client))
	{
		OnClientCookiesCached(client);
	}
}

public void OnClientDisconnect(int client)
{
	if (!IsClientInGame(client))
		return;
	
	if (TF2_GetClientTeam(client) == TFTeam_Invaders)
	{
		// Progress the wave and drop their cash before disconnect
		ForcePlayerSuicide(client);
	}
	
	if (CTFPlayer(client).IsInAParty())
	{
		Party party = CTFPlayer(client).GetParty();
		party.OnPartyMemberLeave(client);
	}
}

public void OnClientCookiesCached(int client)
{
	ClientPrefs_RefreshQueue(client);
	ClientPrefs_RefreshPreferences(client);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	DHooks_OnEntityCreated(entity, classname);
	SDKHooks_OnEntityCreated(entity, classname);
	
	// Store the references of entities that should only exist once
	if (StrEqual(classname, "info_populator"))
	{
		g_pPopulationManager = CPopulationManager(EntIndexToEntRef(entity));
	}
	else if (StrEqual(classname, "tf_objective_resource"))
	{
		g_pObjectiveResource = CTFObjectiveResource(EntIndexToEntRef(entity));
	}
	else if (StrEqual(classname, "tf_gamerules"))
	{
		g_pGameRules = CTFGameRules(EntIndexToEntRef(entity));
	}
}

public void OnEntityDestroyed(int entity)
{
	Entity(entity).Destroy();
}

public void OnGameFrame()
{
	static ArrayList s_prevQueue;
	
	ArrayList queue = GetInvaderQueue();
	queue.Resize(Min(queue.Length, 8));
	
	if (queue.Length > 0)
	{
		// Only send the hint if the visible queue has changed or we are between waves
		if (g_pObjectiveResource.GetMannVsMachineIsBetweenWaves() || (s_prevQueue && !ArrayListEquals(s_prevQueue, queue)))
		{
			for (int client = 1; client <= MaxClients; client++)
			{
				if (!IsClientInGame(client))
					continue;
				
				if (!CTFPlayer(client).IsInvader())
					continue;
				
				if (IsPlayerAlive(client))
					continue;
				
				char text[MAX_USER_MSG_DATA];
				Format(text, sizeof(text), "%T\n", "Invader_Queue_Header", client);
				
				for (int i = 0; i < queue.Length; i++)
				{
					int other = queue.Get(i);
					if (other == client)
					{
						Format(text, sizeof(text), "%s\n➤ %N", text, other);
					}
					else
					{
						Format(text, sizeof(text), "%s\n%N", text, other);
					}
				}
				
				PrintKeyHintText(client, text);
			}
		}
	}
	
	// Store old queue list for comparison
	delete s_prevQueue;
	s_prevQueue = queue.Clone();
	delete queue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || TF2_GetClientTeam(client) != TFTeam_Invaders)
		return Plugin_Continue;
	
	if (CTFPlayer(client).m_inputButtons != 0)
	{
		buttons |= CTFPlayer(client).m_inputButtons;
		CTFPlayer(client).m_inputButtons = 0;
	}
	
	if (!CTFPlayer(client).m_fireButtonTimer.IsElapsed())
		buttons |= IN_ATTACK;
	
	if (!CTFPlayer(client).m_altFireButtonTimer.IsElapsed())
		buttons |= IN_ATTACK2;
	
	if (!CTFPlayer(client).m_specialFireButtonTimer.IsElapsed())
		buttons |= IN_ATTACK3;
	
	if (CTFPlayer(client).HasAttribute(ALWAYS_FIRE_WEAPON))
		buttons |= IN_ATTACK;
	
	if (CTFPlayer(client).ShouldAutoJump())
	{
		buttons |= IN_JUMP;
		SetEntProp(client, Prop_Data, "m_nOldButtons", GetEntProp(client, Prop_Data, "m_nOldButtons") & ~IN_JUMP);
	}
	
	ApplyRobotWeaponRestrictions(client, buttons);
	
	return Plugin_Changed;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (!IsClientInGame(client) || TF2_GetClientTeam(client) != TFTeam_Invaders)
		return;
	
	if (CTFPlayer(client).HasAttribute(ALWAYS_CRIT) && !TF2_IsPlayerInCondition(client, TFCond_CritCanteen))
	{
		TF2_AddCondition(client, TFCond_CritCanteen);
	}
	
	if (CTFPlayer(client).IsInASquad())
	{
		if (CTFPlayer(client).GetSquad().GetMemberCount() <= 1 || CTFPlayer(client).GetSquad().GetLeader() == -1)
		{
			// squad has collapsed - disband it
			CTFPlayer(client).LeaveSquad();
		}
	}
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	if (TF2_GetClientTeam(client) == TFTeam_Invaders)
	{
		if (CTFPlayer(client).HasAttribute(ALWAYS_CRIT))
		{
			result = true;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	switch (condition)
	{
		case TFCond_SpawnOutline:
		{
			if (TF2_GetClientTeam(client) == TFTeam_Invaders)
			{
				// Remove spawn outline for robots
				TF2_RemoveCondition(client, condition);
			}
		}
		case TFCond_KnockedIntoAir:
		{
			if (TF2_GetClientTeam(client) == TFTeam_Invaders)
			{
				CTFNavArea myArea = view_as<CTFNavArea>(CBaseCombatCharacter(client).GetLastKnownArea());
				TFNavAttributeType spawnRoomFlag = TF2_GetClientTeam(client) == TFTeam_Red ? RED_SPAWN_ROOM : BLUE_SPAWN_ROOM;
				
				if (myArea && myArea.HasAttributeTF(spawnRoomFlag))
				{
					// If we are being airblasted in spawn, give more time to leave
					if (CTFPlayer(client).m_flSpawnTimeLeft != 1.0)
					{
						CTFPlayer(client).m_flSpawnTimeLeft += 5.0;
						CTFPlayer(client).m_flSpawnTimeLeftMax += 5.0;
					}
				}
			}
		}
	}
}

static INextBot CreateNextBotPlayer(Address entity)
{
	ToolsNextBotPlayer nextbot = ToolsNextBotPlayer(entity);
	nextbot.IsDormantWhenDead = false;
	return nextbot;
}

static void ApplyRobotWeaponRestrictions(int client, int &buttons)
{
	if (!IsPlayerAlive(client))
		return;
	
	int myWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (myWeapon == -1)
		return;
	
	if (CTFPlayer(client).IsBarrageAndReloadWeapon(myWeapon))
	{
		if (CTFPlayer(client).HasAttribute(HOLD_FIRE_UNTIL_FULL_RELOAD) || tf_bot_always_full_reload.BoolValue)
		{
			if (SDKCall_CBaseCombatWeapon_Clip1(myWeapon) <= 0)
			{
				CTFPlayer(client).m_isWaitingForFullReload = true;
			}
			
			if (CTFPlayer(client).m_isWaitingForFullReload)
			{
				if (SDKCall_CBaseCombatWeapon_Clip1(myWeapon) < TF2Util_GetWeaponMaxClip(myWeapon))
				{
					LockWeapon(client, myWeapon, buttons);
					return;
				}
				
				UnlockWeapon(myWeapon);
				
				// we are fully reloaded
				CTFPlayer(client).m_isWaitingForFullReload = false;
			}
		}
	}
	
	if (CTFPlayer(client).HasMission(MISSION_DESTROY_SENTRIES))
	{
		LockWeapon(client, myWeapon, buttons);
		return;
	}
	else if (CTFPlayer(client).GetPrevMission() == MISSION_DESTROY_SENTRIES)
	{
		UnlockWeapon(myWeapon);
	}
	
	int weaponID = TF2Util_GetWeaponID(myWeapon);
	
	// Vaccinator resistance preference for robot medics
	if (weaponID == TF_WEAPON_MEDIGUN)
	{
		ArrayList attributes = TF2Econ_GetItemStaticAttributes(GetEntProp(myWeapon, Prop_Send, "m_iItemDefinitionIndex"));
		int index = attributes.FindValue(144); // set_weapon_mode
		if (index != -1 && attributes.Get(index, 1) == float(MEDIGUN_RESIST))
		{
			bool preferBullets = CTFPlayer(client).HasAttribute(PREFER_VACCINATOR_BULLETS);
			bool preferBlast = CTFPlayer(client).HasAttribute(PREFER_VACCINATOR_BLAST);
			bool preferFire = CTFPlayer(client).HasAttribute(PREFER_VACCINATOR_FIRE);
			
			if (preferBullets)
			{
				SetEntProp(myWeapon, Prop_Send, "m_nChargeResistType", MEDIGUN_CHARGE_BULLET_RESIST + MEDIGUN_CHARGE_BULLET_RESIST);
			}
			else if (preferBlast)
			{
				SetEntProp(myWeapon, Prop_Send, "m_nChargeResistType", MEDIGUN_CHARGE_BLAST_RESIST + MEDIGUN_CHARGE_BULLET_RESIST);
			}
			else if (preferFire)
			{
				SetEntProp(myWeapon, Prop_Send, "m_nChargeResistType", MEDIGUN_CHARGE_FIRE_RESIST + MEDIGUN_CHARGE_BULLET_RESIST);
			}
			
			if (preferBullets || preferBlast || preferFire)
			{
				delete attributes;
				
				// Prevent switching resistance types
				buttons &= ~IN_RELOAD;
				return;
			}
		}
		delete attributes;
	}
	
	if (weaponID == TF_WEAPON_MEDIGUN || weaponID == TF_WEAPON_LUNCHBOX || weaponID == TF_WEAPON_BUFF_ITEM || weaponID == TF_WEAPON_BAT_WOOD)
	{
		// Allow robots to use certain weapons at all times
		return;
	}
	
	static bool isAttackBlocked[MAXPLAYERS + 1];
	
	if (CTFPlayer(client).MyNextBotPointer().GetIntentionInterface().ShouldAttack(INVALID_ENT_REFERENCE) == ANSWER_NO && !CTFPlayer(client).HasAttribute(ALWAYS_FIRE_WEAPON))
	{
		isAttackBlocked[client] = true;
		
		LockWeapon(client, myWeapon, buttons);
		return;
	}
	
	if (isAttackBlocked[client])
	{
		// The active weapon might have switched, remove attributes from all
		int numWeapons = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
		for (int i = 0; i < numWeapons; i++)
		{
			int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
			if (weapon == -1)
				continue;
			
			UnlockWeapon(weapon);
		}
		
		isAttackBlocked[client] = false;
	}
}
