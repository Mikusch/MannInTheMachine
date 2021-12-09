/*
 * Copyright (C) 2021  Mikusch
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

#pragma semicolon 1
#pragma newdecls required

int g_OffsetClass;
int g_OffsetAttributeFlags;

enum struct PlayerAttributes
{
	int attributeFlags;
	int spawnPoint;
}

PlayerAttributes g_PlayerAttributes[MAXPLAYERS + 1];

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

#include "mvm/dhooks.sp"
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
	
	GameData gamedata = new GameData("mvm");
	if (gamedata)
	{
		DHooks_Initialize(gamedata);
		SDKCalls_Initialize(gamedata);
		
		g_OffsetClass = gamedata.GetOffset("CTFBotSpawner::m_class");
		g_OffsetAttributeFlags = gamedata.GetOffset("CTFBotSpawner::m_defaultAttributes::m_attributeFlags");
		
		delete gamedata;
	}
	else
	{
		SetFailState("Could not find mvm gamedata");
	}
	
	HookEvent("player_death", Event_PlayerDeath);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	
	if (TF2_GetClientTeam(victim) == TFTeam_Blue)
	{
		TF2_ChangeClientTeam(victim, TFTeam_Spectator);
	}
}

int GetClass(Address spawner)
{
	return LoadFromAddress(spawner + view_as<Address>(g_OffsetClass), NumberType_Int32);
}

int GetDefaultAttributeFlags(Address spawner)
{
	return LoadFromAddress(spawner + view_as<Address>(g_OffsetAttributeFlags), NumberType_Int32);
}

bool GameRules_IsMannVsMachineMode()
{
	return view_as<bool>(GameRules_GetProp("m_bPlayingMannVsMachine"));
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
	ChangeClientTeam(client, iTeam);
	SetEntityFlags(client, GetEntityFlags(client) & ~FL_FAKECLIENT);
	return Plugin_Handled;
}
