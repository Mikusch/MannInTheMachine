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

void SDKHooks_OnEntityCreated(int entity, const char[] classname)
{
	if (IsEntityClient(entity))
	{
		PSM_SDKHook(entity, SDKHook_OnTakeDamageAlive, SDKHook_CTFPlayer_OnTakeDamageAlive);
		PSM_SDKHook(entity, SDKHook_WeaponEquipPost, SDKHook_CTFPlayer_WeaponEquipPost);
		PSM_SDKHook(entity, SDKHook_WeaponSwitchPost, SDKHook_CTFPlayer_WeaponSwitchPost);
	}
	else if (StrEqual(classname, "tf_projectile_pipe_remote"))
	{
		PSM_SDKHook(entity, SDKHook_SetTransmit, SDKHook_CTFGrenadePipebombProjectile_SetTransmit);
	}
	else if (StrEqual(classname, "bot_hint_engineer_nest"))
	{
		PSM_SDKHook(entity, SDKHook_Think, SDKHook_CTFBotHintEngineerNest_Think);
		PSM_SDKHook(entity, SDKHook_ThinkPost, SDKHook_CTFBotHintEngineerNest_ThinkPost);
	}
	else if (StrEqual(classname, "entity_medigun_shield"))
	{
		PSM_SDKHook(entity, SDKHook_OnTakeDamagePost, SDKHook_CTFMedigunShield_OnTakeDamagePost);
	}
	else if (StrEqual(classname, "tank_boss"))
	{
		PSM_SDKHook(entity, SDKHook_Think, SDKHook_CTFTankBoss_Think);
	}
	else if (StrEqual(classname, "tf_player_manager"))
	{
		PSM_SDKHook(entity, SDKHook_ThinkPost, SDKHook_CTFPlayerResource_ThinkPost);
	}
}

static Action SDKHook_CTFPlayer_OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
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

static void SDKHook_CTFPlayer_WeaponEquipPost(int client, int weapon)
{
	if (!CTFPlayer(client).ShouldUseCustomViewModel())
		return;
	
	int iWeaponID = TF2Util_GetWeaponID(weapon);
	switch (iWeaponID)
	{
		case TF_WEAPON_INVIS:
		{
			char szModel[PLATFORM_MAX_PATH], szBotModel[PLATFORM_MAX_PATH];
			GetEntPropString(weapon, Prop_Data, "m_ModelName", szModel, sizeof(szModel));
			
			if (g_hSpyWatchOverrides.GetString(szModel, szBotModel, sizeof(szBotModel)))
			{
				int nModelIndex = PrecacheModel(szBotModel);
				SetEntProp(weapon, Prop_Send, "m_nModelIndex", nModelIndex);
				SetEntProp(weapon, Prop_Send, "m_nCustomViewmodelModelIndex", nModelIndex);
			}
		}
		case TF_WEAPON_PDA_SPY:
		{
			SetEntProp(weapon, Prop_Send, "m_nModelIndex", PrecacheModel(PDA_SPY_ARMS_OVERRIDE));
		}
	}
}

static void SDKHook_CTFPlayer_WeaponSwitchPost(int client, int weapon)
{
	if (!CTFPlayer(client).ShouldUseCustomViewModel() || !IsValidEntity(weapon))
		return;
	
	int nModelIndex = GetEffectiveViewModelIndex(client, weapon);
	if (nModelIndex == 0)
		return;
	
	SetEntProp(GetEntPropEnt(client, Prop_Send, "m_hViewModel"), Prop_Send, "m_nModelIndex", nModelIndex);
	SetEntProp(weapon, Prop_Send, "m_nCustomViewmodelModelIndex", nModelIndex);
}

static Action SDKHook_CTFGrenadePipebombProjectile_SetTransmit(int entity, int client)
{
	Action action = Plugin_Continue;
	
	TFTeam team = view_as<TFTeam>(GetEntProp(entity, Prop_Data, "m_iTeamNum"));
	
	// do not show defender stickybombs to the invading team
	if (team == TFTeam_Defenders && team != TF2_GetClientTeam(client))
	{
		// only when fully armed
		float flCreationTime = GetEntDataFloat(entity, GetOffset("CTFGrenadePipebombProjectile", "m_flCreationTime"));
		if ((GetGameTime() - flCreationTime) >= SDKCall_CTFGrenadePipebombProjectile_GetLiveTime(entity))
		{
			action = Plugin_Handled;
		}
	}
	
	CBaseEntity(entity).RefreshNetwork(client, action == Plugin_Continue ? true : false);
	return action;
}

static Action SDKHook_CTFBotHintEngineerNest_Think(int entity)
{
	g_bHasActiveTeleporterPre = GetEntProp(entity, Prop_Send, "m_bHasActiveTeleporter") != 0;
	
	return Plugin_Continue;
}

static void SDKHook_CTFBotHintEngineerNest_ThinkPost(int entity)
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

static void SDKHook_CTFMedigunShield_OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	int owner = GetEntPropEnt(victim, Prop_Send, "m_hOwnerEntity");
	if (!IsValidEntity(owner))
		return;
	
	SetEntPropFloat(owner, Prop_Send, "m_flRageMeter", GetEntPropFloat(owner, Prop_Send, "m_flRageMeter") - (damage * mitm_shield_damage_drain_rate.FloatValue));
}

static Action SDKHook_CTFTankBoss_Think(int entity)
{
	if (CTFTankBoss(entity).m_isDroppingBomb && GetEntProp(entity, Prop_Data, "m_bSequenceFinished"))
	{
		Forwards_OnTankDeployed(entity);
		
		CPrintToChatAll("%s %t", PLUGIN_TAG, "Tank_Deployed", GetEntProp(entity, Prop_Data, "m_iHealth"), TF2Util_GetEntityMaxHealth(entity));
	}
	
	return Plugin_Continue;
}

static void SDKHook_CTFPlayerResource_ThinkPost(int manager)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (TF2_GetClientTeam(client) != TFTeam_Invaders)
			continue;
		
		// Hide buyback text for invaders
		SetEntPropFloat(manager, Prop_Send, "m_flNextRespawnTime", 0.0, client);
	}
}

Action SDKHook_PlayerGlow_SetTransmit(int glow, int client)
{
	Action action = Plugin_Handled;
	
	if (TF2_GetClientTeam(client) == TFTeam_Invaders)
	{
		int hEffectEntity = GetEntPropEnt(glow, Prop_Data, "m_hMoveParent");
		int hMissionTarget = CTFPlayer(client).GetMissionTarget();
		
		// outline if this is a threat we should notice
		if (CTFPlayer(client).HasDelayedThreatNotice(hEffectEntity))
		{
			SetVariantColor(GLOW_COLOR_THREAT);
			AcceptEntityInput(glow, "SetGlowColor");
			
			action = Plugin_Continue;
		}
		
		// outline player if carrying mission target
		if (IsValidEntity(hMissionTarget) && IsBaseObject(hMissionTarget))
		{
			if (hEffectEntity == GetEntPropEnt(hMissionTarget, Prop_Send, "m_hBuilder"))
			{
				if (GetEntProp(hMissionTarget, Prop_Send, "m_bCarried"))
				{
					SetVariantColor(GLOW_COLOR_MISSION);
					AcceptEntityInput(glow, "SetGlowColor");
					
					action = Plugin_Continue;
				}
			}
		}
		
		// outline squad leader or squad members
		if (CTFPlayer(client).IsInASquad())
		{
			CTFBotSquad squad = CTFPlayer(client).GetSquad();
			
			if (hEffectEntity != client && (squad.IsLeader(hEffectEntity) || squad.IsLeader(client) && squad.IsMember(hEffectEntity)))
			{
				SetVariantColor(GLOW_COLOR_SQUAD);
				AcceptEntityInput(glow, "SetGlowColor");
				
				action = Plugin_Continue;
			}
		}
	}
	
	CBaseEntity(glow).RefreshNetwork(client, action == Plugin_Continue ? true : false);
	return action;
}

Action SDKHook_ObjectGlow_SetTransmit(int glow, int client)
{
	Action action = Plugin_Handled;
	
	if (TF2_GetClientTeam(client) == TFTeam_Invaders)
	{
		int hMissionTarget = CTFPlayer(client).GetMissionTarget();
		
		// outline mission target if not carried
		if (IsValidEntity(hMissionTarget) && IsBaseObject(hMissionTarget))
		{
			int hEffectEntity = GetEntPropEnt(glow, Prop_Data, "m_hMoveParent");
			
			if (hEffectEntity == hMissionTarget)
			{
				if (!GetEntProp(hMissionTarget, Prop_Send, "m_bCarried"))
				{
					SetVariantColor(GLOW_COLOR_MISSION);
					AcceptEntityInput(glow, "SetGlowColor");
					
					action = Plugin_Continue;
				}
			}
		}
	}
	
	CBaseEntity(glow).RefreshNetwork(client, action == Plugin_Continue ? true : false);
	return action;
}
