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

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <dhooks>
#include <tf2attributes>
#include <smmem/vec>
#include <tf_econ_data>
#include <tf2items>
#include <tf2utils>
#include <loadsoundscript>
#include <cbasenpc>
#include <cbasenpc/tf/nav>

#pragma semicolon 1
#pragma newdecls required

#define ZERO_VECTOR	{ 0.0, 0.0, 0.0 }

#define DEFINDEX_UNDEFINED	65535

#define MVM_CLASS_FLAG_NONE				0
#define MVM_CLASS_FLAG_NORMAL			(1<<0)
#define MVM_CLASS_FLAG_SUPPORT			(1<<1)
#define MVM_CLASS_FLAG_MISSION			(1<<2)
#define MVM_CLASS_FLAG_MINIBOSS			(1<<3)
#define MVM_CLASS_FLAG_ALWAYSCRIT		(1<<4)
#define MVM_CLASS_FLAG_SUPPORT_LIMITED	(1<<5)

#define TF_FLAGINFO_HOME		0
#define TF_FLAGINFO_STOLEN		(1<<0)
#define TF_FLAGINFO_DROPPED		(1<<1)

const TFTeam TFTeam_Defenders = TFTeam_Red;
const TFTeam TFTeam_Invaders = TFTeam_Blue;

char g_aRawPlayerClassNames[][] =
{
	"undefined",
	"scout",
	"sniper",
	"soldier",
	"demoman",
	"medic",
	"heavyweapons",
	"pyro",
	"spy",
	"engineer",
	"civilian",
	"",
	"random"
};

char g_aRawPlayerClassNamesShort[][] =
{
	"undefined",
	"scout",
	"sniper",
	"soldier",
	"demo",		// short
	"medic",
	"heavy",	// short
	"pyro",
	"spy",
	"engineer",
	"civilian",
	"",
	"random"
};

char g_szBotModels[][] =
{
	"", //TF_CLASS_UNDEFINED
	
	"models/bots/scout/bot_scout.mdl",
	"models/bots/sniper/bot_sniper.mdl",
	"models/bots/soldier/bot_soldier.mdl",
	"models/bots/demo/bot_demo.mdl",
	"models/bots/medic/bot_medic.mdl",
	"models/bots/heavy/bot_heavy.mdl",
	"models/bots/pyro/bot_pyro.mdl",
	"models/bots/spy/bot_spy.mdl",
	"models/bots/engineer/bot_engineer.mdl",
};

char g_szBotBossModels[][] =
{
	"", //TF_CLASS_UNDEFINED
	
	"models/bots/scout_boss/bot_scout_boss.mdl",
	"models/bots/sniper/bot_sniper.mdl",
	"models/bots/soldier_boss/bot_soldier_boss.mdl",
	"models/bots/demo_boss/bot_demo_boss.mdl",
	"models/bots/medic/bot_medic.mdl",
	"models/bots/heavy_boss/bot_heavy_boss.mdl",
	"models/bots/pyro_boss/bot_pyro_boss.mdl",
	"models/bots/spy/bot_spy.mdl",
	"models/bots/engineer/bot_engineer.mdl",
};

// Rome 2 promo models
char g_szRomePromoItems_Hat[][] =
{
	"", //TF_CLASS_UNDEFINED

	"tw_scoutbot_hat",
	"tw_sniperbot_helmet",
	"tw_soldierbot_helmet",
	"tw_demobot_helmet",
	"tw_medibot_hat",
	"tw_heavybot_helmet",
	"tw_pyrobot_helmet",
	"tw_spybot_hood",
	"tw_engineerbot_helmet",
};

char g_szRomePromoItems_Misc[][] =
{
	"", //TF_CLASS_UNDEFINED

	"tw_scoutbot_armor",
	"tw_sniperbot_armor",
	"tw_soldierbot_armor",
	"tw_demobot_armor",
	"tw_medibot_chariot",
	"tw_heavybot_armor",
	"tw_pyrobot_armor",
	"tw_spybot_armor",
	"tw_engineerbot_armor",
};

enum
{
	DONT_BLEED = -1,
	
	BLOOD_COLOR_RED = 0,
	BLOOD_COLOR_YELLOW,
	BLOOD_COLOR_GREEN,
	BLOOD_COLOR_MECH,
};

enum SpawnLocationResult
{
	SPAWN_LOCATION_NOT_FOUND = 0,
	SPAWN_LOCATION_NAV,
	SPAWN_LOCATION_TELEPORTER
};

//-----------------------------------------------------------------------------
// Particle attachment methods
//-----------------------------------------------------------------------------
enum ParticleAttachment_t
{
	PATTACH_ABSORIGIN = 0,			// Create at absorigin, but don't follow
	PATTACH_ABSORIGIN_FOLLOW,		// Create at absorigin, and update to follow the entity
	PATTACH_CUSTOMORIGIN,			// Create at a custom origin, but don't follow
	PATTACH_POINT,					// Create on attachment point, but don't follow
	PATTACH_POINT_FOLLOW,			// Create on attachment point, and update to follow the entity

	PATTACH_WORLDORIGIN,			// Used for control points that don't attach to an entity

	PATTACH_ROOTBONE_FOLLOW,		// Create at the root bone of the entity, and update to follow

	MAX_PATTACH_TYPES,
};

enum PlayerAnimEvent_t
{
	PLAYERANIMEVENT_ATTACK_PRIMARY,
	PLAYERANIMEVENT_ATTACK_SECONDARY,
	PLAYERANIMEVENT_ATTACK_GRENADE,
	PLAYERANIMEVENT_RELOAD,
	PLAYERANIMEVENT_RELOAD_LOOP,
	PLAYERANIMEVENT_RELOAD_END,
	PLAYERANIMEVENT_JUMP,
	PLAYERANIMEVENT_SWIM,
	PLAYERANIMEVENT_DIE,
	PLAYERANIMEVENT_FLINCH_CHEST,
	PLAYERANIMEVENT_FLINCH_HEAD,
	PLAYERANIMEVENT_FLINCH_LEFTARM,
	PLAYERANIMEVENT_FLINCH_RIGHTARM,
	PLAYERANIMEVENT_FLINCH_LEFTLEG,
	PLAYERANIMEVENT_FLINCH_RIGHTLEG,
	PLAYERANIMEVENT_DOUBLEJUMP,

	// Cancel.
	PLAYERANIMEVENT_CANCEL,
	PLAYERANIMEVENT_SPAWN,

	// Snap to current yaw exactly
	PLAYERANIMEVENT_SNAP_YAW,

	PLAYERANIMEVENT_CUSTOM,				// Used to play specific activities
	PLAYERANIMEVENT_CUSTOM_GESTURE,
	PLAYERANIMEVENT_CUSTOM_SEQUENCE,	// Used to play specific sequences
	PLAYERANIMEVENT_CUSTOM_GESTURE_SEQUENCE,

	// TF Specific. Here until there's a derived game solution to this.
	PLAYERANIMEVENT_ATTACK_PRE,
	PLAYERANIMEVENT_ATTACK_POST,
	PLAYERANIMEVENT_GRENADE1_DRAW,
	PLAYERANIMEVENT_GRENADE2_DRAW,
	PLAYERANIMEVENT_GRENADE1_THROW,
	PLAYERANIMEVENT_GRENADE2_THROW,
	PLAYERANIMEVENT_VOICE_COMMAND_GESTURE,
	PLAYERANIMEVENT_DOUBLEJUMP_CROUCH,
	PLAYERANIMEVENT_STUN_BEGIN,
	PLAYERANIMEVENT_STUN_MIDDLE,
	PLAYERANIMEVENT_STUN_END,
	PLAYERANIMEVENT_PASSTIME_THROW_BEGIN,
	PLAYERANIMEVENT_PASSTIME_THROW_MIDDLE,
	PLAYERANIMEVENT_PASSTIME_THROW_END,
	PLAYERANIMEVENT_PASSTIME_THROW_CANCEL,

	PLAYERANIMEVENT_ATTACK_PRIMARY_SUPER,

	PLAYERANIMEVENT_COUNT
};

enum WeaponRestrictionType
{
	ANY_WEAPON		= 0,
	MELEE_ONLY		= 0x0001,
	PRIMARY_ONLY	= 0x0002,
	SECONDARY_ONLY	= 0x0004,
};

enum ETFFlagType
{
	TF_FLAGTYPE_CTF = 0,
	TF_FLAGTYPE_ATTACK_DEFEND,
	TF_FLAGTYPE_TERRITORY_CONTROL,
	TF_FLAGTYPE_INVADE,
	TF_FLAGTYPE_RESOURCE_CONTROL,
	TF_FLAGTYPE_ROBOT_DESTRUCTION,
	TF_FLAGTYPE_PLAYER_DESTRUCTION
};

enum
{
	MVM_EVENT_POPFILE_NONE = 0,
	MVM_EVENT_POPFILE_HALLOWEEN,

	MVM_EVENT_POPFILE_MAX_TYPES,
};

enum BombDeployingState_t
{
	TF_BOMB_DEPLOYING_NONE,
	TF_BOMB_DEPLOYING_DELAY,
	TF_BOMB_DEPLOYING_ANIMATING,
	TF_BOMB_DEPLOYING_COMPLETE,

	TF_BOMB_DEPLOYING_NOT_COUNT,
};

enum AttributeType
{
	REMOVE_ON_DEATH				= 1<<0,					// kick bot from server when killed
	AGGRESSIVE					= 1<<1,					// in MvM mode, push for the cap point
	IS_NPC						= 1<<2,					// a non-player support character
	SUPPRESS_FIRE				= 1<<3,
	DISABLE_DODGE				= 1<<4,
	BECOME_SPECTATOR_ON_DEATH	= 1<<5,					// move bot to spectator team when killed
	QUOTA_MANANGED				= 1<<6,					// managed by the bot quota in CTFBotManager 
	RETAIN_BUILDINGS			= 1<<7,					// don't destroy this bot's buildings when it disconnects
	SPAWN_WITH_FULL_CHARGE		= 1<<8,					// all weapons start with full charge (ie: uber)
	ALWAYS_CRIT					= 1<<9,					// always fire critical hits
	IGNORE_ENEMIES				= 1<<10,
	HOLD_FIRE_UNTIL_FULL_RELOAD	= 1<<11,				// don't fire our barrage weapon until it is full reloaded (rocket launcher, etc)
	PRIORITIZE_DEFENSE			= 1<<12,				// bot prioritizes defending when possible
	ALWAYS_FIRE_WEAPON			= 1<<13,				// constantly fire our weapon
	TELEPORT_TO_HINT			= 1<<14,				// bot will teleport to hint target instead of walking out from the spawn point
	MINIBOSS					= 1<<15,				// is miniboss?
	USE_BOSS_HEALTH_BAR			= 1<<16,				// should I use boss health bar?
	IGNORE_FLAG					= 1<<17,				// don't pick up flag/bomb
	AUTO_JUMP					= 1<<18,				// auto jump
	AIR_CHARGE_ONLY				= 1<<19,				// demo knight only charge in the air
	PREFER_VACCINATOR_BULLETS	= 1<<20,				// When using the vaccinator, prefer to use the bullets shield
	PREFER_VACCINATOR_BLAST		= 1<<21,				// When using the vaccinator, prefer to use the blast shield
	PREFER_VACCINATOR_FIRE		= 1<<22,				// When using the vaccinator, prefer to use the fire shield
	BULLET_IMMUNE				= 1<<23,				// Has a shield that makes the bot immune to bullets
	BLAST_IMMUNE				= 1<<24,				// "" blast
	FIRE_IMMUNE					= 1<<25,				// "" fire
	PARACHUTE					= 1<<26,				// demo/soldier parachute when falling
	PROJECTILE_SHIELD			= 1<<27,				// medic projectile shield
};

enum
{
	LOADOUT_POSITION_INVALID = -1,

	// Weapons & Equipment
	LOADOUT_POSITION_PRIMARY = 0,
	LOADOUT_POSITION_SECONDARY,
	LOADOUT_POSITION_MELEE,
	LOADOUT_POSITION_UTILITY,
	LOADOUT_POSITION_BUILDING,
	LOADOUT_POSITION_PDA,
	LOADOUT_POSITION_PDA2,

	// Wearables. If you add new wearable slots, make sure you add them to IsWearableSlot() below this.
	LOADOUT_POSITION_HEAD,
	LOADOUT_POSITION_MISC,

	// other
	LOADOUT_POSITION_ACTION,

	// More wearables, yay!
	LOADOUT_POSITION_MISC2,

	// taunts
	LOADOUT_POSITION_TAUNT,
	LOADOUT_POSITION_TAUNT2,
	LOADOUT_POSITION_TAUNT3,
	LOADOUT_POSITION_TAUNT4,
	LOADOUT_POSITION_TAUNT5,
	LOADOUT_POSITION_TAUNT6,
	LOADOUT_POSITION_TAUNT7,
	LOADOUT_POSITION_TAUNT8,

	CLASS_LOADOUT_POSITION_COUNT,
};

enum medigun_weapontypes_t
{
	MEDIGUN_STANDARD = 0,
	MEDIGUN_UBER,
	MEDIGUN_QUICKFIX,
	MEDIGUN_RESIST,
};

enum medigun_charge_types
{
	MEDIGUN_CHARGE_INVALID = -1,
	MEDIGUN_CHARGE_INVULN = 0,
	MEDIGUN_CHARGE_CRITICALBOOST,
	MEDIGUN_CHARGE_MEGAHEAL,
	MEDIGUN_CHARGE_BULLET_RESIST,
	MEDIGUN_CHARGE_BLAST_RESIST,
	MEDIGUN_CHARGE_FIRE_RESIST,

	MEDIGUN_NUM_CHARGE_TYPES,
};

enum MissionType
{
	NO_MISSION = 0,
	MISSION_SEEK_AND_DESTROY,		// focus on finding and killing enemy players
	MISSION_DESTROY_SENTRIES,		// focus on finding and destroying enemy sentry guns (and buildings)
	MISSION_SNIPER,					// maintain teams of snipers harassing the enemy
	MISSION_SPY,					// maintain teams of spies harassing the enemy
	MISSION_ENGINEER,				// maintain engineer nests for harassing the enemy
	MISSION_REPROGRAMMED,			// MvM: robot has been hacked and will do bad things to their team
};

enum DifficultyType
{
	UNDEFINED = -1, 
	EASY = 0, 
	NORMAL = 1, 
	HARD = 2, 
	EXPERT = 3, 
	
	NUM_DIFFICULTY_LEVELS
};

enum struct CountdownTimer
{
	float timestamp;
	float duration;
	
	void Reset()
	{
		this.timestamp = GetGameTime() + this.duration;
	}
	
	void Start(float duration)
	{
		this.timestamp = GetGameTime() + duration;
		this.duration = duration;
	}
	
	void Invalidate()
	{
		this.timestamp = -1.0;
	}
	
	bool HasStarted()
	{
		return this.timestamp > 0.0;
	}
	
	bool IsElapsed()
	{
		return GetGameTime() > this.timestamp;
	}
	
	float GetElapsedTime()
	{
		return GetGameTime() - this.timestamp + this.duration;
	}
	
	float GetRemainingTime()
	{
		return this.timestamp - GetGameTime();
	}
	
	float GetCountdownDuration()
	{
		return this.HasStarted() ? this.duration : 0.0;
	}
}

// Globals
Handle g_WarningHudSync;
Handle g_hWaitingForPlayersTimer;
bool g_bInWaitingForPlayers;
StringMap g_offsets;
bool g_bAllowTeamChange;

// Plugin ConVars
ConVar mitm_robots_humans_ratio;
ConVar mitm_spawn_hurry_time;

// TF ConVars
ConVar tf_avoidteammates_pushaway;
ConVar tf_deploying_bomb_delay_time;
ConVar tf_deploying_bomb_time;
ConVar tf_mvm_miniboss_scale;
ConVar tf_mvm_min_players_to_start;
ConVar tf_mvm_bot_allow_flag_carrier_to_fight;
ConVar tf_mvm_bot_flag_carrier_health_regen;
ConVar tf_mvm_bot_flag_carrier_interval_to_1st_upgrade;
ConVar tf_mvm_bot_flag_carrier_interval_to_2nd_upgrade;
ConVar tf_mvm_bot_flag_carrier_interval_to_3rd_upgrade;
ConVar tf_mvm_engineer_teleporter_uber_duration;
ConVar tf_bot_taunt_victim_chance;
ConVar mp_waitingforplayers_time;
ConVar sv_stepsize;

#include "mvm/data.sp"

#include "mvm/console.sp"
#include "mvm/dhooks.sp"
#include "mvm/events.sp"
#include "mvm/helpers.sp"
#include "mvm/sdkcalls.sp"
#include "mvm/sdkhooks.sp"
#include "mvm/deploy_bomb.sp"
#include "mvm/spy.sp"

public Plugin myinfo =
{
	name = "Mann in the Machine",
	author = "Mikusch",
	description = "Mann vs. Machine but epic",
	version = "1.0.0",
	url = "https://github.com/Mikusch"
}

public void OnPluginStart()
{
	g_WarningHudSync = CreateHudSynchronizer();
	g_offsets = new StringMap();
	
	mitm_robots_humans_ratio = CreateConVar("mitm_robots_humans_ratio", "4.33", "The ratio of invaders to defenders. Defender slots gets populated first.");
	mitm_spawn_hurry_time = CreateConVar("mitm_spawn_hurry_time", "30.0", "Time that invaders have to leave their spawn.");
	
	tf_avoidteammates_pushaway = FindConVar("tf_avoidteammates_pushaway");
	tf_deploying_bomb_delay_time = FindConVar("tf_deploying_bomb_delay_time");
	tf_deploying_bomb_time = FindConVar("tf_deploying_bomb_time");
	tf_mvm_miniboss_scale = FindConVar("tf_mvm_miniboss_scale");
	tf_mvm_min_players_to_start = FindConVar("tf_mvm_min_players_to_start");
	tf_mvm_bot_allow_flag_carrier_to_fight = FindConVar("tf_mvm_bot_allow_flag_carrier_to_fight");
	tf_mvm_bot_flag_carrier_health_regen = FindConVar("tf_mvm_bot_flag_carrier_health_regen");
	tf_mvm_bot_flag_carrier_interval_to_1st_upgrade = FindConVar("tf_mvm_bot_flag_carrier_interval_to_1st_upgrade");
	tf_mvm_bot_flag_carrier_interval_to_2nd_upgrade = FindConVar("tf_mvm_bot_flag_carrier_interval_to_2nd_upgrade");
	tf_mvm_bot_flag_carrier_interval_to_3rd_upgrade = FindConVar("tf_mvm_bot_flag_carrier_interval_to_3rd_upgrade");
	tf_mvm_engineer_teleporter_uber_duration = FindConVar("tf_mvm_engineer_teleporter_uber_duration");
	tf_bot_taunt_victim_chance = FindConVar("tf_bot_taunt_victim_chance");
	mp_waitingforplayers_time = FindConVar("mp_waitingforplayers_time");
	sv_stepsize = FindConVar("sv_stepsize");
	
	Console_Initialize();
	Events_Initialize();
	SDKHooks_Initialize();
	
	GameData gamedata = new GameData("mvm");
	if (gamedata)
	{
		DHooks_Initialize(gamedata);
		SDKCalls_Initialize(gamedata);
		
		SetOffset(gamedata, "CTFBotSpawner::m_class");
		SetOffset(gamedata, "CTFBotSpawner::m_health");
		SetOffset(gamedata, "CTFBotSpawner::m_scale");
		SetOffset(gamedata, "CTFBotSpawner::m_flAutoJumpMin");
		SetOffset(gamedata, "CTFBotSpawner::m_flAutoJumpMax");
		SetOffset(gamedata, "CTFBotSpawner::m_eventChangeAttributes");
		SetOffset(gamedata, "CTFBotSpawner::m_name");
		SetOffset(gamedata, "CTFBotSpawner::m_teleportWhereName");
		SetOffset(gamedata, "CTFBotSpawner::m_defaultAttributes");
		SetOffset(gamedata, "CMissionPopulator::m_cooldownDuration");
		SetOffset(gamedata, "CWaveSpawnPopulator::m_bLimitedSupport");
		SetOffset(gamedata, "CPopulationManager::m_defaultEventChangeAttributesName");
		
		SetOffset(gamedata, "EventChangeAttributes_t::m_eventName");
		SetOffset(gamedata, "EventChangeAttributes_t::m_skill");
		SetOffset(gamedata, "EventChangeAttributes_t::m_weaponRestriction");
		SetOffset(gamedata, "EventChangeAttributes_t::m_attributeFlags");
		SetOffset(gamedata, "EventChangeAttributes_t::m_items");
		SetOffset(gamedata, "EventChangeAttributes_t::m_itemsAttributes");
		SetOffset(gamedata, "EventChangeAttributes_t::m_characterAttributes");
		SetOffset(gamedata, "EventChangeAttributes_t::m_tags");
		
		SetOffset(gamedata, "CTFPlayer::m_flSpawnTime");
		SetOffset(gamedata, "CTFPlayer::m_bIsMissionEnemy");
		SetOffset(gamedata, "CTFPlayer::m_bIsLimitedSupportEnemy");
		SetOffset(gamedata, "CTFPlayer::m_pWaveSpawnPopulator");
		SetOffset(gamedata, "CObjectTeleporter::m_teleportWhereName");
		
		delete gamedata;
	}
	else
	{
		SetFailState("Could not find mvm gamedata");
	}
	
	for (int client = 1; client <= MaxClients; client++)
	{
		Player(client).Initialize();
		
		if (IsClientInGame(client))
			OnClientPutInServer(client);
	}
}

public void OnMapStart()
{
	g_hWaitingForPlayersTimer = null;
	g_bInWaitingForPlayers = true;
	
	DHooks_HookGamerules();
	
	// Add HUD icons to downloadables
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

public void OnClientPutInServer(int client)
{
	DHooks_HookClient(client);
	
	Player(client).Reset();
}

public void OnClientDisconnect(int client)
{
	if (TF2_GetClientTeam(client) == TFTeam_Invaders)
	{
		// progress the wave and drop their cash before disconnect
		ForcePlayerSuicide(client);
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	DHooks_OnEntityCreated(entity, classname);
	SDKHooks_OnEntityCreated(entity, classname);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int & subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (TF2_GetClientTeam(client) == TFTeam_Invaders && IsPlayerAlive(client))
	{
		if (Player(client).ShouldAutoJump())
		{
			buttons |= IN_JUMP;
		}
		
		FireWeaponAtEnemy(client, buttons);
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (TF2_GetClientTeam(client) == TFTeam_Invaders && IsPlayerAlive(client))
	{
		if (Player(client).HasAttribute(ALWAYS_CRIT) && !TF2_IsPlayerInCondition(client, TFCond_CritCanteen))
		{
			TF2_AddCondition(client, TFCond_CritCanteen);
		}
		
		CTFNavArea myArea = view_as<CTFNavArea>(CBaseCombatCharacter(client).GetLastKnownArea());
		TFNavAttributeType spawnRoomFlag = TF2_GetClientTeam(client) == TFTeam_Red ? RED_SPAWN_ROOM : BLUE_SPAWN_ROOM;
		
		if (myArea && myArea.HasAttributeTF(spawnRoomFlag))
		{
			// invading bots get uber while they leave their spawn so they don't drop their cash where players can't pick it up
			TF2_AddCondition(client, TFCond_Ubercharged, 0.5);
			TF2_AddCondition(client, TFCond_UberchargedHidden, 0.5);
			TF2_AddCondition(client, TFCond_UberchargeFading, 0.5);
			
			// force bots to walk out of spawn
			TF2Attrib_SetByName(client, "no_jump", 1.0);
			
			if (mitm_spawn_hurry_time.FloatValue)
			{
				if (!Player(client).m_flRequiredSpawnLeaveTime)
				{
					// minibosses and bomb carriers are slow and get more time to leave
					float flTime = (GetEntProp(client, Prop_Send, "m_bIsMiniBoss") || SDKCall_HasTheFlag(client)) ? mitm_spawn_hurry_time.FloatValue * 1.5 : mitm_spawn_hurry_time.FloatValue;
					Player(client).m_flRequiredSpawnLeaveTime = GetGameTime() + flTime;
				}
				else
				{
					float flTimeLeft = Player(client).m_flRequiredSpawnLeaveTime - GetGameTime();
					if (flTimeLeft <= 0.0)
					{
						ForcePlayerSuicide(client);
					}
					else if (flTimeLeft <= 15.0)
					{
						// motivate them to leave their spawn
						SetHudTextParams(-1.0, 0.7, 0.1, 255, 255, 255, 255, _, 0.0, 0.0, 0.0);
						ShowSyncHudText(client, g_WarningHudSync, "You have %1.2f seconds to leave the spawn area.", flTimeLeft);
					}
				}
			}
		}
		else
		{
			// not in spawn, reset their time
			Player(client).m_flRequiredSpawnLeaveTime = 0.0;
			
			TF2Attrib_RemoveByName(client, "no_jump");
		}
		
		// CTFBotScenarioMonitor::DesiredScenarioAndClassAction
		
		if (TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			SpyLeaveSpawnRoomUpdate(client);
			return;
		}
		
		if (TF2_GetPlayerClass(client) == TFClass_Medic)
		{
			// if I'm being healed by another medic, I should do something else other than healing
			bool bIsBeingHealedByAMedic = false;
			int nNumHealers = GetEntProp(client, Prop_Send, "m_nNumHealers");
			for (int i = 0; i < nNumHealers; ++i)
			{
				int healer = TF2Util_GetPlayerHealer(client, i);
				if (0 < healer < MaxClients)
				{
					bIsBeingHealedByAMedic = true;
					break;
				}
			}
			
			if (!bIsBeingHealedByAMedic)
			{
				return;
			}
		}
		
		if (TF2_GetPlayerClass(client) == TFClass_Engineer)
		{
			// TODO: Engineer Bot Idle
			return;
		}
		
		// CTFBotFetchFlag
		int flag = Player(client).GetFlagToFetch();
		if (flag != -1)
		{
			if (GetEntProp(flag, Prop_Send, "m_nFlagStatus") == TF_FLAGINFO_HOME)
			{
				if (GetGameTime() - GetEntDataFloat(client, GetOffset("CTFPlayer::m_flSpawnTime")) < 1.0 && TF2_GetClientTeam(client) != TFTeam_Spectator)
				{
					// we just spawned - give us the flag
					SDKCall_PickUp(flag, client, true);
				}
			}
		}
		
		// CTFBotMvMDeployBomb
		// TODO: Check contact with func_capturezone here and do deployment stuff, then remove deploying check below
		
		// CTFBotDeliverFlag
		if (SDKCall_HasTheFlag(client) && Player(client).m_nDeployingBombState == TF_BOMB_DEPLOYING_NONE && Player(client).UpgradeOverTime())
		{
			// Taunting for our new upgrade
			FakeClientCommand(client, "taunt");
		}
	}
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	if (TF2_GetClientTeam(client) == TFTeam_Invaders)
	{
		if (Player(client).HasAttribute(ALWAYS_CRIT))
		{
			result = true;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (condition == TFCond_MVMBotRadiowave)
	{
		TF2_StunPlayer(client, TF2Util_GetPlayerConditionDuration(client, TFCond_MVMBotRadiowave), 1.0, TF_STUNFLAG_SLOWDOWN | TF_STUNFLAG_BONKSTUCK | TF_STUNFLAG_NOSOUNDOREFFECT);
	}
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int itemDefIndex, Handle &item)
{
	if (TF2_GetClientTeam(client) == TFTeam_Invaders)
	{
		int slot = TF2Econ_GetItemLoadoutSlot(itemDefIndex, TF2_GetPlayerClass(client));
		if (slot == LOADOUT_POSITION_ACTION)
		{
			// Robots aren't allowed to have action items
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

any GetOffset(const char[] name)
{
	int offset;
	if (!g_offsets.GetValue(name, offset))
	{
		ThrowError("Offset \"%s\" not found in map", name);
	}
	
	return offset;
}

void SetOffset(GameData gamedata, const char[] name)
{
	int offset = gamedata.GetOffset(name);
	if (offset == -1)
	{
		ThrowError("Offset \"%s\" not found in gamedata", name);
	}
	
	g_offsets.SetValue(name, offset);
}

void SelectNewDefenders()
{
	ArrayList playerVector = new ArrayList(MaxClients);
	
	// collect valid players
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		playerVector.Push(client);
	}
	
	// shuffle the vector to randomize defenders
	playerVector.Sort(Sort_Random, Sort_Integer);
	
	int iDefenderCount = 0, iInvaderCount = 0;
	
	for (int i = 0; i < playerVector.Length; i++)
	{
		int client = playerVector.Get(i);
		
		g_bAllowTeamChange = true;
		
		if (iDefenderCount == 0)
		{
			// first player always gets defender
			TF2_ChangeClientTeam(client, TFTeam_Defenders);
			iDefenderCount++;
		}
		else
		{
			float flRatio = float(iInvaderCount) / float(iDefenderCount);
			if (flRatio < mitm_robots_humans_ratio.FloatValue)
			{
				TF2_ChangeClientTeam(client, TFTeam_Spectator);
				iInvaderCount++;
			}
			else
			{
				TF2_ChangeClientTeam(client, TFTeam_Defenders);
				iDefenderCount++;
			}
		}
		
		// Defenders get stuck if the map resets without having picked a class
		if (TF2_GetPlayerClass(client) == TFClass_Unknown)
			TF2_SetPlayerClass(client, view_as<TFClassType>(GetRandomInt(view_as<int>(TFClass_Scout), view_as<int>(TFClass_Engineer))));
		
		g_bAllowTeamChange = false;
	}
	
	delete playerVector;
}

// TODO: This is missing some stuff.
// We need to override DoTeleporterOverride to have access to the
// teleporter itself and complete the function.
void OnBotTeleported(int bot)
{
	static float s_flLastTeleportTime;
	
	// don't too many sound and effect when lots of bots teleporting in short time.
	if (GetGameTime() - s_flLastTeleportTime > 0.1)
	{
		EmitGameSoundToAll("MVM.Robot_Teleporter_Deliver", bot);
		
		s_flLastTeleportTime = GetGameTime();
	}
	
	// spy shouldn't get any effect from the teleporter
	if (TF2_GetPlayerClass(bot) != TFClass_Spy)
	{
		TF2_AddCondition(bot, TFCond_TeleportedGlow, 30.0);
		
		// invading bots get uber while they leave their spawn so they don't drop their cash where players can't pick it up
		float flUberTime = tf_mvm_engineer_teleporter_uber_duration.FloatValue;
		TF2_AddCondition(bot, TFCond_Ubercharged, flUberTime);
		TF2_AddCondition(bot, TFCond_UberchargeFading, flUberTime);
	}
}

void FireWeaponAtEnemy(int client, int &buttons)
{
	if (Player(client).HasAttribute(SUPPRESS_FIRE))
		return;
	
	if (Player(client).HasAttribute(IGNORE_ENEMIES))
		return;
	
	int myWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (myWeapon == -1)
		return;
	
	if (Player(client).IsBarrageAndReloadWeapon(myWeapon))
	{
		if (Player(client).HasAttribute(HOLD_FIRE_UNTIL_FULL_RELOAD))
		{
			static int m_isWaitingForFullReload[MAXPLAYERS + 1];
			
			if (GetEntProp(myWeapon, Prop_Send, "m_iClip1") <= 0)
			{
				m_isWaitingForFullReload[client] = true;
			}
			
			if (m_isWaitingForFullReload[client])
			{
				if (GetEntProp(myWeapon, Prop_Send, "m_iClip1") < TF2Util_GetWeaponMaxClip(myWeapon))
				{
					TF2Attrib_SetByName(myWeapon, "no_attack", 1.0);
					TF2Attrib_SetByName(myWeapon, "provide on active", 1.0);
					
					buttons &= ~IN_ATTACK;
					buttons &= ~IN_ATTACK2;
					return;
				}
				
				TF2Attrib_RemoveByName(myWeapon, "no_attack");
				TF2Attrib_RemoveByName(myWeapon, "provide on active");
				
				// we are fully reloaded
				m_isWaitingForFullReload[client] = false;
			}
		}
	}
	
	if (Player(client).HasAttribute(ALWAYS_FIRE_WEAPON))
	{
		buttons |= IN_ATTACK;
		return;
	}
	
	int weaponID = TF2Util_GetWeaponID(myWeapon);
	
	// vaccinator resistance preference for robot medics
	if (weaponID == TF_WEAPON_MEDIGUN)
	{
		ArrayList attributes = TF2Econ_GetItemStaticAttributes(GetEntProp(myWeapon, Prop_Send, "m_iItemDefinitionIndex"));
		int index = attributes.FindValue(144); // set_weapon_mode
		if (index != -1 && attributes.Get(index, 1) == float(MEDIGUN_RESIST))
		{
			bool preferBullets = Player(client).HasAttribute(PREFER_VACCINATOR_BULLETS);
			bool preferBlast = Player(client).HasAttribute(PREFER_VACCINATOR_BLAST);
			bool preferFire = Player(client).HasAttribute(PREFER_VACCINATOR_FIRE);
			
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
				
				// prevent switching resistance types
				buttons &= ~IN_RELOAD;
				return;
			}
		}
		delete attributes;
	}
	
	if (weaponID == TF_WEAPON_MEDIGUN || weaponID == TF_WEAPON_LUNCHBOX || weaponID == TF_WEAPON_BUFF_ITEM || weaponID == TF_WEAPON_BAT_WOOD || GetEntProp(client, Prop_Send, "m_bShieldEquipped"))
	{
		// allow robots to use certain weapons at all time
		return;
	}
	
	CTFNavArea myArea = view_as<CTFNavArea>(CBaseCombatCharacter(client).GetLastKnownArea());
	TFNavAttributeType spawnRoomFlag = TF2_GetClientTeam(client) == TFTeam_Red ? RED_SPAWN_ROOM : BLUE_SPAWN_ROOM;
	
	static bool s_isInSpawn[MAXPLAYERS + 1];
	
	if (myArea && myArea.HasAttributeTF(spawnRoomFlag))
	{
		s_isInSpawn[client] = true;
		
		// disable attacking
		TF2Attrib_SetByName(myWeapon, "no_attack", 1.0);
		TF2Attrib_SetByName(myWeapon, "provide on active", 1.0);
		
		buttons &= ~IN_ATTACK;
		buttons &= ~IN_ATTACK2;
		return;
	}
	else if (s_isInSpawn[client])
	{
		s_isInSpawn[client] = false;
		
		// the active weapon might have switched, remove attributes from all
		int numWeapons = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
		for (int i = 0; i < numWeapons; i++)
		{
			int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
			if (weapon == -1)
				continue;
			
			TF2Attrib_RemoveByName(weapon, "no_attack");
			TF2Attrib_RemoveByName(weapon, "provide on active");
		}
	}
}
