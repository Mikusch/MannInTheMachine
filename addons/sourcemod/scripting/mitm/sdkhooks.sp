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

static bool g_bHasActiveTeleporterPre;

void SDKHooks_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, SDKHookCB_Client_OnTakeDamage);
}

void SDKHooks_OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "tf_projectile_pipe_remote"))
	{
		SDKHook(entity, SDKHook_SetTransmit, SDKHookCB_ProjectilePipeRemote_SetTransmit);
	}
	else if (StrEqual(classname, "entity_revive_marker"))
	{
		SDKHook(entity, SDKHook_SetTransmit, SDKHookCB_ReviveMarker_SetTransmit);
	}
	else if (StrEqual(classname, "bot_hint_engineer_nest"))
	{
		SDKHook(entity, SDKHook_Think, SDKHookCB_BotHintEngineerNest_Think);
		SDKHook(entity, SDKHook_ThinkPost, SDKHookCB_BotHintEngineerNest_ThinkPost);
	}
}

static Action SDKHookCB_Client_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (TF2_GetClientTeam(victim) == TFTeam_Invaders)
	{
		// Don't let Sentry Busters die until they've done their spin-up
		if (Player(victim).HasMission(MISSION_DESTROY_SENTRIES))
		{
			if ((float(GetEntProp(victim, Prop_Data, "m_iHealth")) - damage) <= 0.0)
			{
				SetEntityHealth(victim, 1);
				return Plugin_Handled;
			}
		}
		
		// Sentry Busters hurt teammates when they explode.
		// Force damage value when the victim is a giant.
		if (IsEntityClient(attacker) && TF2_GetClientTeam(attacker) == TFTeam_Invaders)
		{
			if ((attacker != victim) &&
				Player(attacker).GetPrevMission() == MISSION_DESTROY_SENTRIES &&
				g_bForceFriendlyFire &&
				TF2_GetClientTeam(victim) == TF2_GetClientTeam(attacker) &&
				GetEntProp(victim, Prop_Send, "m_bIsMiniBoss"))
			{
				damage = 600.0;
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}

static Action SDKHookCB_ProjectilePipeRemote_SetTransmit(int entity, int client)
{
	TFTeam team = view_as<TFTeam>(GetEntProp(entity, Prop_Data, "m_iTeamNum"));
	if (team == TFTeam_Defenders)
	{
		// do not show defender stickybombs to the invading team
		if (Player(client).IsInvader())
		{
			// only when fully armed
			float flCreationTime = GetEntDataFloat(entity, GetOffset("CTFGrenadePipebombProjectile::m_flCreationTime"));
			if ((GetGameTime() - flCreationTime) >= SDKCall_GetLiveTime(entity))
			{
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

static Action SDKHookCB_ReviveMarker_SetTransmit(int entity, int client)
{
	TFTeam team = view_as<TFTeam>(GetEntProp(entity, Prop_Data, "m_iTeamNum"));
	if (team == TFTeam_Defenders)
	{
		int owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
		if (IsEntityClient(owner) && TF2_GetPlayerClass(owner) == TFClass_Spy)
		{
			if (Player(client).IsInvader())
			{
				// hide spy revive markers from invaders
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

static Action SDKHookCB_BotHintEngineerNest_Think(int entity)
{
	g_bHasActiveTeleporterPre = GetEntProp(entity, Prop_Send, "m_bHasActiveTeleporter") != 0;
	
	return Plugin_Continue;
}

static void SDKHookCB_BotHintEngineerNest_ThinkPost(int entity)
{
	if (!g_bHasActiveTeleporterPre && GetEntProp(entity, Prop_Send, "m_bHasActiveTeleporter"))
	{
		EmitSoundToAll(")mvm/mvm_tele_activate.wav", entity, SNDCHAN_STATIC, 155);
	}
}

Action SDKHookCB_EntityGlow_SetTransmit(int entity, int client)
{
	int target = GetEntPropEnt(entity, Prop_Data, "m_hEffectEntity");
	
	if (Player(client).HasMission(MISSION_DESTROY_SENTRIES) && target == Player(client).GetMissionTarget())
	{
		// show the glow of our target sentry
		return Plugin_Continue;
	}
	
	if (Player(client).IsInASquad())
	{
		if (client != target && Player(client).GetSquad().IsLeader(target))
		{
			// show the glow of our squad leader
			return Plugin_Continue;
		}
	}
	
	return Plugin_Handled;
}
