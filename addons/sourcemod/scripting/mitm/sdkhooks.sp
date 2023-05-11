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
	SDKHook(client, SDKHook_OnTakeDamageAlive, SDKHookCB_Client_OnTakeDamageAlive);
	SDKHook(client, SDKHook_WeaponCanSwitchTo, SDKHookCB_Client_WeaponCanSwitchTo);
}

void SDKHooks_OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "tf_projectile_pipe_remote"))
	{
		SDKHook(entity, SDKHook_SetTransmit, SDKHookCB_ProjectilePipeRemote_SetTransmit);
	}
	else if (StrEqual(classname, "bot_hint_engineer_nest"))
	{
		SDKHook(entity, SDKHook_Think, SDKHookCB_BotHintEngineerNest_Think);
		SDKHook(entity, SDKHook_ThinkPost, SDKHookCB_BotHintEngineerNest_ThinkPost);
	}
}

static Action SDKHookCB_Client_OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
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
				Player(victim).IsMiniBoss())
			{
				damage = 600.0;
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}

static Action SDKHookCB_Client_WeaponCanSwitchTo(int client, int weapon)
{
	if (TF2_GetClientTeam(client) == TFTeam_Invaders && Player(client).IsWeaponRestricted(weapon))
	{
		EmitGameSoundToClient(client, "Player.DenyWeaponSelection");
		return Plugin_Handled;
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
			float flCreationTime = GetEntDataFloat(entity, GetOffset("CTFGrenadePipebombProjectile", "m_flCreationTime"));
			if ((GetGameTime() - flCreationTime) >= SDKCall_GetLiveTime(entity))
			{
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
		BroadcastSound(255, "Announcer.MVM_Engineer_Teleporter_Activated");
		
		CUtlVector m_teleporters = CUtlVector(GetEntityAddress(entity) + GetOffset("CTFBotHintEngineerNest", "m_teleporters"));
		for (int i = 0; i < m_teleporters.Count(); ++i)
		{
			int owner = GetEntPropEnt(LoadEntityFromHandleAddress(m_teleporters.Get(i)), Prop_Send, "m_hOwnerEntity");
			if (owner != -1 && IsBaseObject(owner))
			{
				EmitSoundToAll(")mvm/mvm_tele_activate.wav", owner, SNDCHAN_STATIC, 155);
			}
		}
	}
}

Action SDKHookCB_EntityGlow_SetTransmit(int entity, int client)
{
	int hEffectEntity = GetEntPropEnt(entity, Prop_Data, "m_hEffectEntity");
	
	if (!IsValidEntity(hEffectEntity))
		return Plugin_Handled;
	
	int hMissionTarget = Player(client).GetMissionTarget();
	if (IsValidEntity(hMissionTarget) && IsBaseObject(hMissionTarget))
	{
		// target sentry - only outline if not carried
		if (hEffectEntity == hMissionTarget)
		{
			if (!GetEntProp(hMissionTarget, Prop_Send, "m_bCarried"))
			{
				return Plugin_Continue;
			}
		}
		// player - only outline if carrying target sentry
		else if (hEffectEntity == GetEntPropEnt(hMissionTarget, Prop_Send, "m_hBuilder"))
		{
			if (GetEntProp(hMissionTarget, Prop_Send, "m_bCarried"))
			{
				return Plugin_Continue;
			}
		}
	}
	
	if (Player(client).IsInASquad())
	{
		if (hEffectEntity != client && Player(client).GetSquad().IsLeader(hEffectEntity))
		{
			// show the glow of our squad leader
			return Plugin_Continue;
		}
	}
	
	return Plugin_Handled;
}
