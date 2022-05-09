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

#define VEC_HULL_MIN	{-24.0, -24.0, 0.0}
#define VEC_HULL_MAX	{24.0, 24.0, 82.0}

#define MVM_CLASS_FLAG_NONE				0
#define MVM_CLASS_FLAG_NORMAL			(1<<0)
#define MVM_CLASS_FLAG_SUPPORT			(1<<1)
#define MVM_CLASS_FLAG_MISSION			(1<<2)
#define MVM_CLASS_FLAG_MINIBOSS			(1<<3)
#define MVM_CLASS_FLAG_ALWAYSCRIT		(1<<4)
#define MVM_CLASS_FLAG_SUPPORT_LIMITED	(1<<5)

const TFTeam TFTeam_Defenders = TFTeam_Red;
const TFTeam TFTeam_Invaders = TFTeam_Blue;

int g_OffsetClass;
int g_OffsetClassIcon;
int g_OffsetHealth;
int g_OffsetScale;
int g_OffsetDefaultAttributes;
int g_OffsetLimitedSupport;

int g_OffsetWeaponRestriction;
int g_OffsetAttributeFlags;
int g_OffsetItems;
int g_OffsetItemsAttributes;
int g_OffsetCharacterAttributes;

int g_OffsetIsMissionEnemy;
int g_OffsetIsLimitedSupportEnemy;
int g_OffsetWaveSpawnPopulator;

ConVar tf_mvm_miniboss_scale;
ConVar sv_stepsize;

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

enum
{
	DONT_BLEED = -1,
	
	BLOOD_COLOR_RED = 0,
	BLOOD_COLOR_YELLOW,
	BLOOD_COLOR_GREEN,
	BLOOD_COLOR_MECH,
};

enum WeaponRestrictionType
{
	ANY_WEAPON		= 0,
	MELEE_ONLY		= 0x0001,
	PRIMARY_ONLY	= 0x0002,
	SECONDARY_ONLY	= 0x0004,
};

enum
{
	TF_WPN_TYPE_PRIMARY = 0,
	TF_WPN_TYPE_SECONDARY,
	TF_WPN_TYPE_MELEE,
	TF_WPN_TYPE_GRENADE,
	TF_WPN_TYPE_BUILDING,
	TF_WPN_TYPE_PDA,
	TF_WPN_TYPE_ITEM1,
	TF_WPN_TYPE_ITEM2,
	TF_WPN_TYPE_HEAD,
	TF_WPN_TYPE_MISC,
	TF_WPN_TYPE_MELEE_ALLCLASS,
	TF_WPN_TYPE_SECONDARY2,
	TF_WPN_TYPE_PRIMARY2,

	TF_WPN_TYPE_COUNT,
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

#include "mvm/data.sp"

#include "mvm/dhooks.sp"
#include "mvm/events.sp"
#include "mvm/helpers.sp"
#include "mvm/memory.sp"
#include "mvm/sdkcalls.sp"

public Plugin myinfo =
{
	name = "Unnamed Experiment",
	author = "Mikusch",
	description = "Will it blend?",
	version = "1.0.0",
	url = "https://github.com/Mikusch"
}

public void OnPluginStart()
{
	tf_mvm_miniboss_scale = FindConVar("tf_mvm_miniboss_scale");
	sv_stepsize = FindConVar("sv_stepsize");
	
	Events_Initialize();
	
	GameData gamedata = new GameData("mvm");
	if (gamedata)
	{
		DHooks_Initialize(gamedata);
		SDKCalls_Initialize(gamedata);
		
		g_OffsetClass = gamedata.GetOffset("CTFBotSpawner::m_class");
		g_OffsetClassIcon = gamedata.GetOffset("CTFBotSpawner::m_iszClassIcon");
		g_OffsetHealth = gamedata.GetOffset("CTFBotSpawner::m_health");
		g_OffsetScale = gamedata.GetOffset("CTFBotSpawner::m_scale");
		g_OffsetDefaultAttributes = gamedata.GetOffset("CTFBotSpawner::m_defaultAttributes");
		g_OffsetLimitedSupport = gamedata.GetOffset("CWaveSpawnPopulator::m_bLimitedSupport");
		
		g_OffsetWeaponRestriction = gamedata.GetOffset("EventChangeAttributes_t::m_weaponRestriction");
		g_OffsetAttributeFlags = gamedata.GetOffset("EventChangeAttributes_t::m_attributeFlags");
		g_OffsetItems = gamedata.GetOffset("EventChangeAttributes_t::m_items");
		g_OffsetItemsAttributes = gamedata.GetOffset("EventChangeAttributes_t::m_itemsAttributes");
		g_OffsetCharacterAttributes = gamedata.GetOffset("EventChangeAttributes_t::m_characterAttributes");
		
		g_OffsetIsMissionEnemy = gamedata.GetOffset("CTFPlayer::m_bIsMissionEnemy");
		g_OffsetIsLimitedSupportEnemy = gamedata.GetOffset("CTFPlayer::m_bIsLimitedSupportEnemy");
		g_OffsetWaveSpawnPopulator = gamedata.GetOffset("CTFPlayer::m_pWaveSpawnPopulator");
		
		delete gamedata;
	}
	else
	{
		SetFailState("Could not find mvm gamedata");
	}
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
			OnClientPutInServer(client);
	}
}

public void OnClientPutInServer(int client)
{
	DHooks_HookClient(client);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (TF2_GetClientTeam(client) == TFTeam_Invaders)
	{
		if (Player(client).HasAttribute(ALWAYS_CRIT) && !TF2_IsPlayerInCondition(client, TFCond_CritCanteen))
		{
			TF2_AddCondition(client, TFCond_CritCanteen);
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
