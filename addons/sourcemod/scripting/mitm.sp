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
#include <tf2>
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
#include <pluginstatemanager>
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

// Cookies
Cookie g_hCookieQueue;
Cookie g_hCookiePreferences;

// Other globals
CEntityFactory g_hEntityFactory;
Handle g_hWarningHudSync;
StringMap g_hSpyWatchOverrides;
bool g_bInWaitingForPlayers;
bool g_bAllowTeamChange;	// Bypass CTFGameRules::GetTeamAssignmentOverride?
bool g_bInEndlessRollEscalation;

// Plugin ConVars
ConVar mitm_developer;
ConVar mitm_custom_upgrades_file;
ConVar mitm_bot_spawn_hurry_time;
ConVar mitm_queue_points;
ConVar mitm_rename_robots;
ConVar mitm_bot_allow_suicide;
ConVar mitm_queue_enabled;
ConVar mitm_party_enabled;
ConVar mitm_party_max_size;
ConVar mitm_setup_time;
ConVar mitm_max_spawn_deaths;
ConVar mitm_defender_ping_limit;
ConVar mitm_shield_damage_drain_rate;
ConVar mitm_bot_taunt_on_upgrade;
ConVar mitm_romevision;

// Game ConVars
ConVar tf_avoidteammates_pushaway;
ConVar tf_deploying_bomb_delay_time;
ConVar tf_deploying_bomb_time;
ConVar tf_mvm_defenders_team_size;
ConVar tf_mvm_miniboss_scale;
ConVar tf_mvm_min_players_to_start;
ConVar tf_mvm_bot_allow_flag_carrier_to_fight;
ConVar tf_mvm_bot_flag_carrier_health_regen;
ConVar tf_mvm_bot_flag_carrier_interval_to_1st_upgrade;
ConVar tf_mvm_bot_flag_carrier_interval_to_2nd_upgrade;
ConVar tf_mvm_bot_flag_carrier_interval_to_3rd_upgrade;
ConVar tf_mvm_engineer_teleporter_uber_duration;
ConVar tf_populator_debug;
ConVar tf_bot_difficulty;
ConVar tf_bot_engineer_building_health_multiplier;
ConVar tf_bot_suicide_bomb_range;
ConVar tf_bot_suicide_bomb_friendly_fire;
ConVar tf_bot_taunt_victim_chance;
ConVar tf_bot_always_full_reload;
ConVar tf_bot_flag_kill_on_touch;
ConVar tf_bot_melee_only;
ConVar mp_waitingforplayers_time;
ConVar phys_pushscale;

#include "mitm/shareddefs.sp"

#include "mitm/console.sp"
#include "mitm/convars.sp"
#include "mitm/data.sp"
#include "mitm/dhooks.sp"
#include "mitm/entity.sp"
#include "mitm/events.sp"
#include "mitm/forwards.sp"
#include "mitm/hooks.sp"
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
	
	g_hSpyWatchOverrides = new StringMap();
	g_hSpyWatchOverrides.SetString("models/weapons/v_models/v_watch_spy.mdl", "models/mvm/weapons/v_models/v_watch_spy_bot.mdl");
	g_hSpyWatchOverrides.SetString("models/weapons/v_models/v_watch_pocket_spy.mdl", "models/mvm/weapons/v_models/v_watch_pocket_spy_bot.mdl");
	g_hSpyWatchOverrides.SetString("models/weapons/v_models/v_watch_leather_spy.mdl", "models/mvm/weapons/v_models/v_watch_leather_spy_bot.mdl");
	g_hSpyWatchOverrides.SetString("models/weapons/v_models/v_ttg_watch_spy.mdl", "models/mvm/weapons/v_models/v_ttg_watch_spy_bot.mdl");
	g_hSpyWatchOverrides.SetString("models/workshop_partner/weapons/v_models/v_hm_watch/v_hm_watch.mdl", "models/mvm/workshop_partner/weapons/v_models/v_hm_watch/v_hm_watch_bot.mdl");
	
	LoadTranslations("common.phrases");
	LoadTranslations("mitm.phrases");
	
	CTFBotDead.Init();
	CTFBotDeliverFlag.Init();
	CTFBotEscortSquadLeader.Init();
	CTFBotFetchFlag.Init();
	CTFBotMainAction.Init();
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
	
	g_hEntityFactory = new CEntityFactory("player");
	g_hEntityFactory.DeriveFromClass("player");
	g_hEntityFactory.AttachNextBot(CreateNextBotPlayer);
	g_hEntityFactory.SetInitialActionFactory(CTFBotMainAction.GetFactory());
	
	g_hCookieQueue = new Cookie("mitm_queue", "Mann in the Machine: Queue Points", CookieAccess_Protected);
	g_hCookiePreferences = new Cookie("mitm_preferences", "Mann in the Machine: Preferences", CookieAccess_Protected);
	
	GameData hGameConf = new GameData("mitm");
	if (!hGameConf)
		SetFailState("Could not find mitm gamedata");
	
	PSM_Init("mitm_enabled", hGameConf);
	PSM_AddPluginStateChangedHook(OnPluginStateChanged);
	
	Entity.Init();
	
	Console_Init();
	ConVars_Init();
	DHooks_Init();
	Events_Init();
	Forwards_Init();
	Hooks_Init();
	Party_Init();
	
	Offsets_Init(hGameConf);
	SDKCalls_Init(hGameConf);
	
	delete hGameConf;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		CTFPlayer(client).Init();
	}
}

public void OnPluginEnd()
{
	PSM_SetPluginState(false);
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
	
	Precache();
	DHooks_HookGameRules();
}

public void VScript_OnScriptVMInitialized()
{
	static bool bInitialized = false;
	
	if (!PSM_IsEnabled() || bInitialized)
		return;
	
	DHooks_VScriptInit();
	SDKCalls_VScriptInit();
	
	bInitialized = true;
}

public void OnConfigsExecuted()
{
	PSM_TogglePluginState();
}

public void OnClientPutInServer(int client)
{
	if (!PSM_IsEnabled())
		return;
	
	CBaseNPC_HookEventKilled(client);
	
	CTFPlayer(client).OnClientPutInServer();
	
	if (AreClientCookiesCached(client))
	{
		OnClientCookiesCached(client);
	}
}

public void OnClientDisconnect(int client)
{
	if (!PSM_IsEnabled())
		return;
	
	if (!IsClientInGame(client))
		return;
	
	if (TF2_GetClientTeam(client) == TFTeam_Invaders)
	{
		// Progress the wave and drop their cash before disconnect
		ForcePlayerSuicide(client);
	}
	
	CTFPlayer player = CTFPlayer(client);
	
	if (player.IsInAParty())
	{
		Party party = player.GetParty();
		party.OnPartyMemberLeave(client);
	}
}

public void OnClientCookiesCached(int client)
{
	if (!PSM_IsEnabled())
		return;
	
	CTFPlayer player = CTFPlayer(client);
	player.m_defenderQueuePoints = g_hCookieQueue.GetInt(client);
	player.m_preferences = g_hCookiePreferences.GetInt(client);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!PSM_IsEnabled())
		return;
	
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
	if (!PSM_IsEnabled())
		return;
	
	PSM_SDKUnhook(entity);
	
	if (Entity.IsEntityTracked(entity))
		Entity(entity).Destroy();
}

public void OnGameFrame()
{
	if (!PSM_IsEnabled())
		return;
	
	ArrayList queue = GetInvaderQueue();
	queue.Resize(Min(queue.Length, 8));
	
	if (queue.Length > 0)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client))
				continue;
			
			if (!CTFPlayer(client).IsInvader())
				continue;
			
			if (!IsClientObserver(client))
				continue;
			
			int iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
			if (iObserverMode == OBS_MODE_DEATHCAM || iObserverMode == OBS_MODE_FREEZECAM)
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
	
	delete queue;
	
	float flTime = GameRules_GetPropFloat("m_flRestartRoundTime") - GetGameTime();
	int nTime = RoundToCeil(flTime);
	
	SetHudTextParams(-1.0, 0.9, GetGameFrameTime(), 255, 255, 255, 255);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsClientObserver(client))
			continue;
		
		if (CTFPlayer(client).HasPreference(PREF_SPECTATOR_MODE))
		{
			ShowSyncHudText(client, g_hWarningHudSync, "%t", "Spectator_Mode");
		}
		else if (g_pObjectiveResource.GetMannVsMachineIsBetweenWaves() && CTFPlayer(client).IsInvader())
		{
			ShowSyncHudText(client, g_hWarningHudSync, "%t", "Invader_WaitingToSpawn", nTime);
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!PSM_IsEnabled())
		return Plugin_Continue;
	
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || TF2_GetClientTeam(client) != TFTeam_Invaders)
		return Plugin_Continue;
	
	CTFPlayer player = CTFPlayer(client);
	
	if (player.m_inputButtons != 0)
	{
		buttons |= player.m_inputButtons;
		player.m_inputButtons = 0;
	}
	
	if (!player.m_fireButtonTimer.IsElapsed())
		buttons |= IN_ATTACK;
	
	if (!player.m_altFireButtonTimer.IsElapsed())
		buttons |= IN_ATTACK2;
	
	if (!player.m_specialFireButtonTimer.IsElapsed())
		buttons |= IN_ATTACK3;
	
	if (player.HasAttribute(ALWAYS_FIRE_WEAPON))
		buttons |= IN_ATTACK;
	
	if (player.ShouldAutoJump())
	{
		buttons |= IN_JUMP;
		SetEntProp(client, Prop_Data, "m_nOldButtons", GetEntProp(client, Prop_Data, "m_nOldButtons") & ~IN_JUMP);
	}
	
	ApplyRobotWeaponRestrictions(client, buttons);
	
	return Plugin_Changed;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (!PSM_IsEnabled())
		return;
	
	if (!IsClientInGame(client) || TF2_GetClientTeam(client) != TFTeam_Invaders)
		return;
	
	CTFPlayer player = CTFPlayer(client);
	
	if (player.HasAttribute(ALWAYS_CRIT) && !TF2_IsPlayerInCondition(client, TFCond_CritCanteen))
	{
		TF2_AddCondition(client, TFCond_CritCanteen);
	}
	
	if (player.IsInASquad())
	{
		if (player.GetSquad().GetMemberCount() <= 1 || player.GetSquad().GetLeader() == -1)
		{
			// squad has collapsed - disband it
			player.LeaveSquad();
		}
	}
	
	if (buttons & IN_JUMP)
	{
		if (TF2Attrib_HookValueInt(0, "bot_custom_jump_particle", client))
		{
			static char szEffectName[] = "rocketjump_smoke";
			TE_TFParticleEffectAttachment(szEffectName, client, PATTACH_POINT_FOLLOW, "foot_L");
			TE_TFParticleEffectAttachment(szEffectName, client, PATTACH_POINT_FOLLOW, "foot_R");
		}
	}
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	if (!PSM_IsEnabled())
		return Plugin_Continue;
	
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
	if (!PSM_IsEnabled())
		return;
	
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
	}
}

public Action CBaseCombatCharacter_EventKilled(int entity, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!PSM_IsEnabled())
		return Plugin_Continue;
	
	// Replicate behavior of CTFBot::Event_Killed
	if (!IsEntityClient(entity) || TF2_GetClientTeam(entity) != TFTeam_Invaders)
		return Plugin_Continue;
	
	// announce Spies
	if (IsMannVsMachineMode())
	{
		if (TF2_GetPlayerClass(entity) == TFClass_Spy)
		{
			ArrayList playerList = new ArrayList();
			CollectPlayers(playerList, TFTeam_Invaders, COLLECT_ONLY_LIVING_PLAYERS);
			
			int spyCount = 0;
			for (int i = 0; i < playerList.Length; ++i)
			{
				if (TF2_GetPlayerClass(playerList.Get(i)) == TFClass_Spy)
				{
					++spyCount;
				}
			}
			
			delete playerList;
			
			Event event = CreateEvent("mvm_mission_update");
			if (event)
			{
				event.SetInt("class", view_as<int>(TFClass_Spy));
				event.SetInt("count", spyCount);
				event.Fire();
			}
		}
		else if (TF2_GetPlayerClass(entity) == TFClass_Engineer)
		{
			// in MVM, when an engineer dies, we need to decouple his objects so they stay alive when his bot slot gets recycled
			while (TF2Util_GetPlayerObjectCount(entity) > 0)
			{
				// set to not have owner
				int obj = TF2Util_GetPlayerObject(entity, 0);
				if (obj != -1)
				{
					SetEntityOwner(obj, -1);
					SetEntPropEnt(obj, Prop_Send, "m_hBuilder", -1);
				}
				SDKCall_CTFPlayer_RemoveObject(entity, obj);
			}
			
			// unown engineer nest if owned any
			int hint = -1;
			while ((hint = FindEntityByClassname(hint, "bot_hint_*")) != -1)
			{
				if (GetEntPropEnt(hint, Prop_Send, "m_hOwnerEntity") == entity)
				{
					SetEntityOwner(hint, -1);
				}
			}
			
			ArrayList playerList = new ArrayList();
			CollectPlayers(playerList, TFTeam_Invaders, COLLECT_ONLY_LIVING_PLAYERS);
			bool bShouldAnnounceLastEngineerBotDeath = CTFPlayer(entity).HasAttribute(TELEPORT_TO_HINT);
			if (bShouldAnnounceLastEngineerBotDeath)
			{
				for (int i = 0; i < playerList.Length; ++i)
				{
					if (playerList.Get(i) != entity && TF2_GetPlayerClass(playerList.Get(i)) == TFClass_Engineer)
					{
						bShouldAnnounceLastEngineerBotDeath = false;
						break;
					}
				}
			}
			delete playerList;
			
			if (bShouldAnnounceLastEngineerBotDeath)
			{
				bool bEngineerTeleporterInTheWorld = false;
				int obj = -1;
				while ((obj = FindEntityByClassname(obj, "obj_teleporter")) != -1)
				{
					if (TF2_GetObjectType(obj) == TFObject_Teleporter && view_as<TFTeam>(GetEntProp(obj, Prop_Data, "m_iTeamNum")) == TFTeam_Invaders)
					{
						bEngineerTeleporterInTheWorld = true;
						break;
					}
				}
				
				if (bEngineerTeleporterInTheWorld)
				{
					BroadcastSound(255, "Announcer.MVM_An_Engineer_Bot_Is_Dead_But_Not_Teleporter");
				}
				else
				{
					BroadcastSound(255, "Announcer.MVM_An_Engineer_Bot_Is_Dead");
				}
			}
		}
		
		if (CTFPlayer(entity).IsInASquad())
		{
			CTFPlayer(entity).LeaveSquad();
		}
		
		CTFPlayer(entity).StopIdleSound();
	}
	
	return Plugin_Continue;
}

static void OnPluginStateChanged(bool bEnabled)
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		if (bEnabled)
		{
			char classname[64];
			if (!GetEntityClassname(entity, classname, sizeof(classname)))
				continue;
			
			OnEntityCreated(entity, classname);
		}
		else
		{
			if (Entity.IsEntityTracked(entity))
				Entity(entity).Destroy();
		}
	}
	
	if (bEnabled)
	{
		g_hEntityFactory.Install();
		
		if (g_pGameRules.IsValid())
		{
			char path[PLATFORM_MAX_PATH];
			mitm_custom_upgrades_file.GetString(path, sizeof(path));
			
			if (path[0])
			{
				g_pGameRules.SetCustomUpgradesFile(path);
			}
		}
		
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client))
				continue;
			
			OnClientPutInServer(client);
		}
		
		OnMapStart();
		
		if (VScript_IsScriptVMInitialized())
			VScript_OnScriptVMInitialized();
	}
	else
	{
		g_hEntityFactory.Uninstall();
		
		if (g_pGameRules.IsValid())
		{
			g_pGameRules.SetCustomUpgradesFile(DEFAULT_UPGRADES_FILE);
		}
	}
}

static void Precache()
{
	PrecacheSound("ui/system_message_alert.wav");
	PrecacheSound(")mvm/mvm_tele_activate.wav");
	
	SuperPrecacheModel(GUNSLINGER_ENGINEER_ARMS_OVERRIDE);
	SuperPrecacheModel("models/mvm/weapons/c_models/c_engineer_bot_gunslinger_animations.mdl");
	
	SuperPrecacheModel(PDA_SPY_ARMS_OVERRIDE);
	SuperPrecacheModel("models/mvm/weapons/v_models/v_pda_spy_bot_animations.mdl");
	
	SuperPrecacheModel("models/mvm/weapons/v_models/v_ttg_watch_spy_bot.mdl");
	SuperPrecacheModel("models/mvm/weapons/v_models/v_watch_leather_spy_bot.mdl");
	SuperPrecacheModel("models/mvm/weapons/v_models/v_watch_pocket_spy_bot.mdl");
	SuperPrecacheModel("models/mvm/weapons/v_models/v_watch_pocket_spy_bot_animations.mdl");
	SuperPrecacheModel("models/mvm/weapons/v_models/v_watch_spy_bot.mdl");
	SuperPrecacheModel("models/mvm/weapons/v_models/v_watch_spy_bot_animations.mdl");
	SuperPrecacheModel("models/mvm/workshop_partner/weapons/v_models/v_hm_watch/v_hm_watch_bot.mdl");
	
	for (int i = 0; i < sizeof(g_aBotArmModels); i++)
	{
		if (g_aBotArmModels[i][0])
			SuperPrecacheModel(g_aBotArmModels[i]);
	}
	
	for (int i = 0; i < sizeof(g_aRawPlayerClassNamesShort); i++)
	{
		if (g_aRawPlayerClassNamesShort[i][0])
		{
			char szModel[PLATFORM_MAX_PATH];
			Format(szModel, sizeof(szModel), "models/mvm/weapons/c_models/c_%s_bot_animations.mdl", g_aRawPlayerClassNamesShort[i]);
			if (FileExists(szModel))
				SuperPrecacheModel(szModel);
			
			PrecacheViewModelMaterialsForClass(g_aRawPlayerClassNamesShort[i]);
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
	
	CTFPlayer player = CTFPlayer(client);
	
	if (player.IsBarrageAndReloadWeapon(myWeapon))
	{
		if (player.HasAttribute(HOLD_FIRE_UNTIL_FULL_RELOAD) || tf_bot_always_full_reload.BoolValue)
		{
			if (SDKCall_CBaseCombatWeapon_Clip1(myWeapon) <= 0)
			{
				player.m_isWaitingForFullReload = true;
			}
			
			if (player.m_isWaitingForFullReload)
			{
				if (SDKCall_CBaseCombatWeapon_Clip1(myWeapon) < TF2Util_GetWeaponMaxClip(myWeapon))
				{
					LockWeapon(client, myWeapon, buttons);
					return;
				}
				
				UnlockWeapon(myWeapon);
				
				// we are fully reloaded
				player.m_isWaitingForFullReload = false;
			}
		}
	}
	
	int weaponID = TF2Util_GetWeaponID(myWeapon);
	
	// Vaccinator resistance preference for robot medics
	if (weaponID == TF_WEAPON_MEDIGUN)
	{
		ArrayList attributes = TF2Econ_GetItemStaticAttributes(GetEntProp(myWeapon, Prop_Send, "m_iItemDefinitionIndex"));
		int index = attributes.FindValue(144); // set_weapon_mode
		if (index != -1 && attributes.Get(index, 1) == float(MEDIGUN_RESIST))
		{
			bool bPreferBullets = player.HasAttribute(PREFER_VACCINATOR_BULLETS);
			bool bPreferBlast = player.HasAttribute(PREFER_VACCINATOR_BLAST);
			bool bPreferFire = player.HasAttribute(PREFER_VACCINATOR_FIRE);
			
			if (bPreferBullets)
			{
				SetEntProp(myWeapon, Prop_Send, "m_nChargeResistType", MEDIGUN_CHARGE_BULLET_RESIST + MEDIGUN_CHARGE_BULLET_RESIST);
			}
			else if (bPreferBlast)
			{
				SetEntProp(myWeapon, Prop_Send, "m_nChargeResistType", MEDIGUN_CHARGE_BLAST_RESIST + MEDIGUN_CHARGE_BULLET_RESIST);
			}
			else if (bPreferFire)
			{
				SetEntProp(myWeapon, Prop_Send, "m_nChargeResistType", MEDIGUN_CHARGE_FIRE_RESIST + MEDIGUN_CHARGE_BULLET_RESIST);
			}
			
			if (bPreferBullets || bPreferBlast || bPreferFire)
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
	
	static bool s_bIsAttackBlocked[MAXPLAYERS + 1];
	
	if (player.MyNextBotPointer().GetIntentionInterface().ShouldAttack(INVALID_ENT_REFERENCE) == ANSWER_NO && !player.HasAttribute(ALWAYS_FIRE_WEAPON))
	{
		s_bIsAttackBlocked[client] = true;
		
		LockWeapon(client, myWeapon, buttons);
		return;
	}
	
	if (s_bIsAttackBlocked[client])
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
		
		s_bIsAttackBlocked[client] = false;
	}
}
