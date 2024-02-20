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

enum struct SDKHookData
{
	char classname[64];
	SDKHookType type;
	SDKHookCB callback;
}

static bool g_bHasActiveTeleporterPre;
static ArrayList g_hSDKHooks;

void SDKHooks_Init()
{
	g_hSDKHooks = new ArrayList(sizeof(SDKHookData));
	
	SDKHooks_AddHook("player", SDKHook_OnTakeDamageAlive, SDKHookCB_Client_OnTakeDamageAlive);
	SDKHooks_AddHook("tf_projectile_pipe_remote", SDKHook_SetTransmit, SDKHookCB_ProjectilePipeRemote_SetTransmit);
	SDKHooks_AddHook("bot_hint_engineer_nest", SDKHook_Think, SDKHookCB_BotHintEngineerNest_Think);
	SDKHooks_AddHook("bot_hint_engineer_nest", SDKHook_ThinkPost, SDKHookCB_BotHintEngineerNest_ThinkPost);
	SDKHooks_AddHook("entity_medigun_shield", SDKHook_OnTakeDamagePost, SDKHookCB_EntityMedigunShield_OnTakeDamagePost);
}

void SDKHooks_Toggle(bool bEnable)
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		char classname[64];
		if (!GetEntityClassname(entity, classname, sizeof(classname)))
			continue;
		
		if (bEnable)
		{
			SDKHooks_HookEntity(entity, classname, true);
		}
		else
		{
			SDKHooks_HookEntity(entity, classname, false);
		}
	}
}

void SDKHooks_HookEntity(int entity, const char[] classname, bool bHook)
{
	int index = g_hSDKHooks.FindString(classname, SDKHookData::classname);
	if (index == -1)
		return;
	
	for (int i = index; i < g_hSDKHooks.Length; i++)
	{
		SDKHookData data;
		if (g_hSDKHooks.GetArray(i, data) && StrEqual(data.classname, classname))
		{
			if (bHook)
			{
				SDKHook(entity, data.type, data.callback);
			}
			else
			{
				SDKUnhook(entity, data.type, data.callback);
			}
		}
	}
}

static void SDKHooks_AddHook(const char[] classname, SDKHookType type, SDKHookCB callback)
{
	SDKHookData data;
	strcopy(data.classname, sizeof(data.classname), classname);
	data.type = type;
	data.callback = callback;
	
	g_hSDKHooks.PushArray(data);
}

static Action SDKHookCB_Client_OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	CTakeDamageInfo info = GetGlobalDamageInfo();
	
	if (TF2_GetClientTeam(victim) == TFTeam_Invaders)
	{
		// Don't let Sentry Busters die until they've done their spin-up
		if (CTFPlayer(victim).HasMission(MISSION_DESTROY_SENTRIES))
		{
			if ((float(GetEntProp(victim, Prop_Data, "m_iHealth")) - damage) <= 0.0)
			{
				SetEntityHealth(victim, 1);
				damage = 0.0;
				return Plugin_Changed;
			}
		}
		
		// Sentry Busters hurt teammates when they explode.
		// Force damage value when the victim is a giant.
		if (IsEntityClient(attacker) && TF2_GetClientTeam(attacker) == TFTeam_Invaders)
		{
			if ((attacker != victim) &&
				CTFPlayer(attacker).GetPrevMission() == MISSION_DESTROY_SENTRIES &&
				info.IsForceFriendlyFire() &&
				TF2_GetClientTeam(victim) == TF2_GetClientTeam(attacker) &&
				CTFPlayer(victim).IsMiniBoss())
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
		if (CTFPlayer(client).IsInvader())
		{
			// only when fully armed
			float flCreationTime = GetEntDataFloat(entity, GetOffset("CTFGrenadePipebombProjectile", "m_flCreationTime"));
			if ((GetGameTime() - flCreationTime) >= SDKCall_CTFGrenadePipebombProjectile_GetLiveTime(entity))
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

static void SDKHookCB_EntityMedigunShield_OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	int owner = GetEntPropEnt(victim, Prop_Send, "m_hOwnerEntity");
	if (!IsValidEntity(owner))
		return;
	
	SetEntPropFloat(owner, Prop_Send, "m_flRageMeter", GetEntPropFloat(owner, Prop_Send, "m_flRageMeter") - (damage * sm_mitm_shield_damage_drain_rate.FloatValue));
}

Action SDKHookCB_EntityGlow_SetTransmit(int entity, int client)
{
	int hEffectEntity = GetEntPropEnt(entity, Prop_Data, "m_hEffectEntity");
	
	if (!IsValidEntity(hEffectEntity))
		return Plugin_Handled;
	
	int hMissionTarget = CTFPlayer(client).GetMissionTarget();
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
	
	if (CTFPlayer(client).IsInASquad())
	{
		if (hEffectEntity != client && CTFPlayer(client).GetSquad().IsLeader(hEffectEntity))
		{
			// show the glow of our squad leader
			return Plugin_Continue;
		}
	}
	
	return Plugin_Handled;
}
