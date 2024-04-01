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
	int ref;
	SDKHookType type;
	SDKHookCB callback;
}

static bool g_bHasActiveTeleporterPre;
static ArrayList g_hActiveHooks;

void SDKHooks_Init()
{
	g_hActiveHooks = new ArrayList(sizeof(SDKHookData));
}

void SDKHooks_HookEntity(int entity, const char[] classname)
{
	if (IsEntityClient(entity))
	{
		SDKHooks_HookEntityInternal(entity, SDKHook_OnTakeDamageAlive, SDKHookCB_Client_OnTakeDamageAlive);
		SDKHooks_HookEntityInternal(entity, SDKHook_WeaponEquipPost, SDKHookCB_Client_WeaponEquipPost);
		SDKHooks_HookEntityInternal(entity, SDKHook_WeaponSwitchPost, SDKHookCB_Client_WeaponSwitchPost);
	}
	else if (StrEqual(classname, "tf_projectile_pipe_remote"))
	{
		SDKHooks_HookEntityInternal(entity, SDKHook_SetTransmit, SDKHookCB_ProjectilePipeRemote_SetTransmit);
	}
	else if (StrEqual(classname, "bot_hint_engineer_nest"))
	{
		SDKHooks_HookEntityInternal(entity, SDKHook_Think, SDKHookCB_BotHintEngineerNest_Think);
		SDKHooks_HookEntityInternal(entity, SDKHook_ThinkPost, SDKHookCB_BotHintEngineerNest_ThinkPost);
	}
	else if (StrEqual(classname, "entity_medigun_shield"))
	{
		SDKHooks_HookEntityInternal(entity, SDKHook_OnTakeDamagePost, SDKHookCB_EntityMedigunShield_OnTakeDamagePost);
	}
}

void SDKHooks_UnhookEntity(int entity)
{
	int ref = IsValidEdict(entity) ? EntIndexToEntRef(entity) : entity;
	
	for (int i = g_hActiveHooks.Length - 1; i >= 0; i--)
	{
		SDKHookData data;
		if (g_hActiveHooks.GetArray(i, data) && ref == data.ref)
		{
			SDKUnhook(data.ref, data.type, data.callback);
			g_hActiveHooks.Erase(i);
		}
	}
}

static void SDKHooks_HookEntityInternal(int entity, SDKHookType type, SDKHookCB callback)
{
	SDKHookData data;
	data.ref = IsValidEdict(entity) ? EntIndexToEntRef(entity) : entity;
	data.type = type;
	data.callback = callback;
	
	g_hActiveHooks.PushArray(data);
	
	SDKHook(entity, type, callback);
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

static void SDKHookCB_Client_WeaponEquipPost(int client, int weapon)
{
	if (!sm_mitm_use_bot_viewmodels.BoolValue || TF2_GetClientTeam(client) != TFTeam_Invaders)
		return;
	
	int iWeaponID = TF2Util_GetWeaponID(weapon);
	switch (iWeaponID)
	{
		case TF_WEAPON_INVIS:
		{
			char szModel[PLATFORM_MAX_PATH], szBotModel[PLATFORM_MAX_PATH];
			GetEntPropString(weapon, Prop_Data, "m_ModelName", szModel, sizeof(szModel));
			
			if (g_hSpyWatchModelReplacements.GetString(szModel, szBotModel, sizeof(szBotModel)))
			{
				int nModelIndex = PrecacheModel(szBotModel);
				SetEntProp(weapon, Prop_Send, "m_nModelIndex", nModelIndex);
				SetEntProp(weapon, Prop_Send, "m_nCustomViewmodelModelIndex", nModelIndex);
			}
		}
		case TF_WEAPON_PDA_SPY:
		{
			SetEntProp(weapon, Prop_Data, "m_nModelIndex", PrecacheModel("models/weapons/v_models/v_pda_spy_bot.mdl"));
		}
	}
}

static void SDKHookCB_Client_WeaponSwitchPost(int client, int weapon)
{
	if (!sm_mitm_use_bot_viewmodels.BoolValue || TF2_GetClientTeam(client) != TFTeam_Invaders)
		return;
	
	int nModelIndex = GetEffectiveViewModelIndex(client, weapon);
	if (nModelIndex == 0)
		return;
	
	SetEntProp(GetEntPropEnt(client, Prop_Send, "m_hViewModel"), Prop_Send, "m_nModelIndex", nModelIndex);
	SetEntProp(weapon, Prop_Send, "m_nCustomViewmodelModelIndex", nModelIndex);
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
