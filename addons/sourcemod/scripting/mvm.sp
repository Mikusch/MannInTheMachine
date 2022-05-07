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
#include <dhooks>
#include <tf2attributes>
#include <smmem/vec>
#include <tf_econ_data>
#include <tf2items>
#include <tf2utils>

#pragma semicolon 1
#pragma newdecls required

int g_OffsetClass;
int g_OffsetClassIcon;
int g_OffsetHealth;
int g_OffsetScale;
int g_OffsetAttributeFlags;
int g_OffsetItems;
int g_OffsetItemsAttributes;
int g_OffsetCharacterAttributes;
int g_OffsetIsMissionEnemy;

ConVar tf_mvm_miniboss_scale;

enum struct PlayerAttributes
{
	int attributeFlags;
	int spawnPoint;
	float scaleOverride;
}

PlayerAttributes g_PlayerAttributes[MAXPLAYERS + 1];

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
	RegConsoleCmd("sm_joinblue", Command_JoinTeamBlue);
	
	AddCommandListener(CommandListener_JoinTeam, "jointeam");
	
	tf_mvm_miniboss_scale = FindConVar("tf_mvm_miniboss_scale");
	
	GameData gamedata = new GameData("mvm");
	if (gamedata)
	{
		DHooks_Initialize(gamedata);
		SDKCalls_Initialize(gamedata);
		
		g_OffsetClass = gamedata.GetOffset("CTFBotSpawner::m_class");
		g_OffsetClassIcon = gamedata.GetOffset("CTFBotSpawner::m_iszClassIcon");
		g_OffsetHealth = gamedata.GetOffset("CTFBotSpawner::m_health");
		g_OffsetScale = gamedata.GetOffset("CTFBotSpawner::m_scale");
		g_OffsetAttributeFlags = gamedata.GetOffset("CTFBotSpawner::m_defaultAttributes::m_attributeFlags");
		g_OffsetItems = gamedata.GetOffset("CTFBotSpawner::m_defaultAttributes::m_items");
		g_OffsetItemsAttributes = gamedata.GetOffset("CTFBotSpawner::m_defaultAttributes::m_itemsAttributes");
		g_OffsetCharacterAttributes = gamedata.GetOffset("CTFBotSpawner::m_defaultAttributes::m_characterAttributes");
		g_OffsetIsMissionEnemy = gamedata.GetOffset("CTFPlayer::m_bIsMissionEnemy");
		
		delete gamedata;
	}
	else
	{
		SetFailState("Could not find mvm gamedata");
	}
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerTeam);
	
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

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	
	/*if (TF2_GetClientTeam(victim) == TFTeam_Blue)
	{
		TF2_ChangeClientTeam(victim, TFTeam_Spectator);
	}*/
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
}

void OnEventChangeAttributes(int player, EventChangeAttributes_t pEvent)
{
	if (pEvent)
	{
		// remove any player attributes
		SDKCall_RemovePlayerAttributes(player, false);
		// and add ones that we want specifically
		for (int i = 0; i < pEvent.m_characterAttributes.Count(); i++)
		{
			Address pDef = pEvent.m_characterAttributes.Get(i, 8);
			
			int defIndex = LoadFromAddress(pDef, NumberType_Int16);
			float value = LoadFromAddress(pDef + 4, NumberType_Int32);
			
			TF2Attrib_SetByDefIndex(player, defIndex, value);
		}
		
		// give items to bot before apply attribute changes
		for (int i = 0; i < pEvent.m_items.Count(); i++)
		{
			char item[64];
			LoadStringFromAddress(DereferencePointer(pEvent.m_items.Get(i)), item, sizeof(item));
			
			AddItem(player, item);
		}
		
		PrintToChatAll("Found %d items attributes", pEvent.m_itemsAttributes.Count());
		for (int i = 0; i < pEvent.m_itemsAttributes.Count(); i++)
		{
			Address itemAttributes = pEvent.m_itemsAttributes.Get(i);
			
			char itemName[64];
			LoadStringFromAddress(DereferencePointer(itemAttributes), itemName, sizeof(itemName));
			
			PrintToChatAll("Found %s: %d", itemName, FindItemByName(itemName));
			int itemDef = FindItemByName(itemName);
			
			for (int iItemSlot = LOADOUT_POSITION_PRIMARY; iItemSlot < CLASS_LOADOUT_POSITION_COUNT; iItemSlot++)
			{
				int entity = TF2Util_GetPlayerLoadoutEntity(player, iItemSlot);
				
				if (entity != -1 && itemDef == GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
				{
					CUtlVector m_attributes = CUtlVector(itemAttributes + view_as<Address>(0x8));
					for (int iAtt = 0; iAtt < m_attributes.Count(); iAtt++)
					{
						// item_attributes_t
						Address attrib = m_attributes.Get(iAtt, 8);
						
						int defIndex = LoadFromAddress(attrib, NumberType_Int16);
						float value = LoadFromAddress(attrib + 4, NumberType_Int32);
						
						TF2Attrib_SetByDefIndex(entity, defIndex, value);
					}
					
					if (entity != -1)
					{
						// update model incase we change style
						SDKCall_UpdateModelToClass(entity);
					}
					
					// move on to the next set of attributes
					break;
				}
			} // for each slot
		} // for each set of attributes
	}
}

void PostRobotSpawn(int newPlayer)
{
	SetEntData(newPlayer, g_OffsetIsMissionEnemy, true);
}

void ModifyMaxHealth(int client, int newMaxHealth, bool setCurrentHealth = true, bool allowModelScaling = true)
{
	int maxHealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
	if (maxHealth != newMaxHealth)
	{
		TF2Attrib_SetByName(client, "hidden maxhealth non buffed", float(newMaxHealth - maxHealth));
	}
	
	if (setCurrentHealth)
	{
		SetEntProp(client, Prop_Data, "m_iHealth", newMaxHealth);
	}
	
	if (allowModelScaling && GetEntProp(client, Prop_Send, "m_bIsMiniBoss"))
	{
		SetModelScale(client, g_PlayerAttributes[client].scaleOverride > 0.0 ? g_PlayerAttributes[client].scaleOverride : tf_mvm_miniboss_scale.FloatValue);
	}
}

public Action Command_JoinTeamBlue(int client, int args)
{
	FakeClientCommand(client, "jointeam blue");
	return Plugin_Handled;
}

public Action CommandListener_JoinTeam(int client, const char[] command, int argc)
{
	char strTeam[16];
	if (argc > 0)
		GetCmdArg(1, strTeam, sizeof(strTeam));
	
	TFTeam iTeam = TFTeam_Unassigned;
	if (StrEqual(strTeam, "red", false))
		iTeam = TFTeam_Red;
	else if (StrEqual(strTeam, "blue", false))
		iTeam = TFTeam_Blue;
	else if (StrEqual(strTeam, "spectate", false) || StrEqual(strTeam, "spectator", false))
		iTeam = TFTeam_Spectator;
	else if (!StrEqual(command, "autoteam", false))
		return Plugin_Continue;
	
	if (IsFakeClient(client))
		iTeam = TFTeam_Blue;
	
	SetEntityFlags(client, GetEntityFlags(client) | FL_FAKECLIENT);
	TF2_ChangeClientTeam(client, iTeam);
	SetEntityFlags(client, GetEntityFlags(client) & ~FL_FAKECLIENT);
	return Plugin_Handled;
}

int UTIL_StringtToCharArray(Address string_t, char[] buffer, int maxlen)
{
	if (string_t == Address_Null)
		ThrowError("string_t address is null");
	
	if (maxlen <= 0)
		ThrowError("Buffer size is negative or zero");
	
	int max = maxlen - 1;
	int i = 0;
	for (; i < max; i++)
	if ((buffer[i] = view_as<char>(LoadFromAddress(string_t + view_as<Address>(i), NumberType_Int8))) == '\0')
		return i;
	
	buffer[i] = '\0';
	return i;
}
