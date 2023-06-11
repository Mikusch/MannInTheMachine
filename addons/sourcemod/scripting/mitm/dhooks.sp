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

static DynamicHook g_hDHook_CBaseEntity_SetModel;
static DynamicHook g_hDHook_CBaseObject_IsPlacementPosValid;
static DynamicHook g_hDHook_CBaseObject_CanBeUpgraded;
static DynamicHook g_hDHook_CItem_ComeToRest;
static DynamicHook g_hDHook_CBaseEntity_ShouldTransmit;
static DynamicHook g_hDHook_CBaseEntity_Event_Killed;
static DynamicHook g_hDHook_CBaseCombatCharacter_ShouldGib;
static DynamicHook g_hDHook_CTFPlayer_IsAllowedToPickUpFlag;
static DynamicHook g_hDHook_CBasePlayer_EntSelectSpawnPoint;
static DynamicHook g_hDHook_CBaseFilter_PassesFilterImpl;
static DynamicHook g_hDHook_CTFItem_PickUp;
static DynamicHook g_hDHook_CGameRules_ClientConnected;
static DynamicHook g_hDHook_CGameRules_FPlayerCanTakeDamage;

static ArrayList m_justSpawnedList;

static int g_internalSpawnPoint = INVALID_ENT_REFERENCE;
static SpawnLocationResult s_spawnLocationResult = SPAWN_LOCATION_NOT_FOUND;
static float g_flTempRestartRoundTime;

// CMissionPopulator
static CountdownTimer m_cooldownTimer;
static CountdownTimer m_checkForDangerousSentriesTimer;
static CMissionPopulator s_MissionPopulator;
static int s_activeMissionMembers;
static int s_nSniperCount;

// MvM Engineer Teleporter
static CBaseEntity s_lastTeleporter;
static float s_flLastTeleportTime;

void DHooks_Init(GameData hGameData)
{
	m_justSpawnedList = new ArrayList();
	m_cooldownTimer = new CountdownTimer();
	m_checkForDangerousSentriesTimer = new CountdownTimer();
	
	CreateDynamicDetour(hGameData, "CTFGCServerSystem::PreClientUpdate", DHookCallback_CTFGCServerSystem_PreClientUpdate_Pre, DHookCallback_CTFGCServerSystem_PreClientUpdate_Post);
	CreateDynamicDetour(hGameData, "CPopulationManager::AllocateBots", DHookCallback_CPopulationManager_AllocateBots_Pre);
	CreateDynamicDetour(hGameData, "CPopulationManager::EndlessRollEscalation", DHookCallback_CPopulationManager_EndlessRollEscalation_Pre, DHookCallback_CPopulationManager_EndlessRollEscalation_Post);
	CreateDynamicDetour(hGameData, "CPopulationManager::RestoreCheckpoint", DHookCallback_CPopulationManager_RestoreCheckpoint_Pre);
	CreateDynamicDetour(hGameData, "CTFBotSpawner::Spawn", DHookCallback_CTFBotSpawner_Spawn_Pre);
	CreateDynamicDetour(hGameData, "CSquadSpawner::Spawn", _, DHookCallback_CSquadSpawner_Spawn_Post);
	CreateDynamicDetour(hGameData, "CPopulationManager::Update", DHookCallback_CPopulationManager_Update_Pre, DHookCallback_CPopulationManager_Update_Post);
	CreateDynamicDetour(hGameData, "CPeriodicSpawnPopulator::Update", _, DHookCallback_CPeriodicSpawnPopulator_Update_Post);
	CreateDynamicDetour(hGameData, "CWaveSpawnPopulator::Update", _, DHookCallback_CWaveSpawnPopulatorUpdate_Post);
	CreateDynamicDetour(hGameData, "CMissionPopulator::UpdateMission", DHookCallback_CMissionPopulator_UpdateMission_Pre, DHookCallback_CMissionPopulator_UpdateMission_Post);
	CreateDynamicDetour(hGameData, "CMissionPopulator::UpdateMissionDestroySentries", DHookCallback_CMissionPopulator_UpdateMissionDestroySentries_Pre, DHookCallback_CMissionPopulator_UpdateMissionDestroySentries_Post);
	CreateDynamicDetour(hGameData, "CPointPopulatorInterface::InputChangeBotAttributes", DHookCallback_CPointPopulatorInterface_InputChangeBotAttributes_Pre);
	CreateDynamicDetour(hGameData, "CTFGameRules::GetTeamAssignmentOverride", DHookCallback_CTFGameRules_GetTeamAssignmentOverride_Pre, DHookCallback_CTFGameRules_GetTeamAssignmentOverride_Post);
	CreateDynamicDetour(hGameData, "CTFGameRules::PlayerReadyStatus_UpdatePlayerState", DHookCallback_CTFGameRules_PlayerReadyStatus_UpdatePlayerState_Pre, DHookCallback_CTFGameRules_PlayerReadyStatus_UpdatePlayerState_Post);
	CreateDynamicDetour(hGameData, "CTeamplayRoundBasedRules::ResetPlayerAndTeamReadyState", DHookCallback_CTeamplayRoundBasedRules_ResetPlayerAndTeamReadyState_Pre);
	CreateDynamicDetour(hGameData, "CTFPlayer::GetLoadoutItem", DHookCallback_CTFPlayer_GetLoadoutItem_Pre, DHookCallback_CTFPlayer_GetLoadoutItem_Post);
	CreateDynamicDetour(hGameData, "CTFPlayer::CheckInstantLoadoutRespawn", DHookCallback_CTFPlayer_CheckInstantLoadoutRespawn_Pre);
	CreateDynamicDetour(hGameData, "CTFPlayer::DoClassSpecialSkill", DHookCallback_CTFPlayer_DoClassSpecialSkill_Pre);
	CreateDynamicDetour(hGameData, "CTFPlayer::RemoveAllOwnedEntitiesFromWorld", DHookCallback_CTFPlayer_RemoveAllOwnedEntitiesFromWorld_Pre);
	CreateDynamicDetour(hGameData, "CTFPlayer::CanBuild", DHookCallback_CTFPlayer_CanBuild_Pre, DHookCallback_CTFPlayer_CanBuild_Post);
	CreateDynamicDetour(hGameData, "CWeaponMedigun::AllowedToHealTarget", DHookCallback_CWeaponMedigun_AllowedToHealTarget_Pre);
	CreateDynamicDetour(hGameData, "CSpawnLocation::FindSpawnLocation", _, DHookCallback_CSpawnLocation_FindSpawnLocation_Post);
	CreateDynamicDetour(hGameData, "CTraceFilterObject::ShouldHitEntity", _, DHookCallback_CTraceFilterObject_ShouldHitEntity_Post);
	CreateDynamicDetour(hGameData, "CLagCompensationManager::StartLagCompensation", DHookCallback_CLagCompensationManager_StartLagCompensation_Pre, DHookCallback_CLagCompensationManager_StartLagCompensation_Post);
	CreateDynamicDetour(hGameData, "CUniformRandomStream::SetSeed", DHookCallback_CUniformRandomStream_SetSeed_Pre);
	CreateDynamicDetour(hGameData, "DoTeleporterOverride", _, DHookCallback_DoTeleporterOverride_Post);
	CreateDynamicDetour(hGameData, "OnBotTeleported", DHookCallback_OnBotTeleported_Pre);
	
	g_hDHook_CBaseEntity_SetModel = CreateDynamicHook(hGameData, "CBaseEntity::SetModel");
	g_hDHook_CBaseObject_IsPlacementPosValid = CreateDynamicHook(hGameData, "CBaseObject::IsPlacementPosValid");
	g_hDHook_CBaseObject_CanBeUpgraded = CreateDynamicHook(hGameData, "CBaseObject::CanBeUpgraded");
	g_hDHook_CItem_ComeToRest = CreateDynamicHook(hGameData, "CItem::ComeToRest");
	g_hDHook_CBaseEntity_ShouldTransmit = CreateDynamicHook(hGameData, "CBaseEntity::ShouldTransmit");
	g_hDHook_CBaseEntity_Event_Killed = CreateDynamicHook(hGameData, "CBaseEntity::Event_Killed");
	g_hDHook_CBaseCombatCharacter_ShouldGib = CreateDynamicHook(hGameData, "CBaseCombatCharacter::ShouldGib");
	g_hDHook_CTFPlayer_IsAllowedToPickUpFlag = CreateDynamicHook(hGameData, "CTFPlayer::IsAllowedToPickUpFlag");
	g_hDHook_CBasePlayer_EntSelectSpawnPoint = CreateDynamicHook(hGameData, "CBasePlayer::EntSelectSpawnPoint");
	g_hDHook_CBaseFilter_PassesFilterImpl = CreateDynamicHook(hGameData, "CBaseFilter::PassesFilterImpl");
	g_hDHook_CTFItem_PickUp = CreateDynamicHook(hGameData, "CTFItem::PickUp");
	g_hDHook_CGameRules_ClientConnected = CreateDynamicHook(hGameData, "CGameRules::ClientConnected");
	g_hDHook_CGameRules_FPlayerCanTakeDamage = CreateDynamicHook(hGameData, "CGameRules::FPlayerCanTakeDamage");
	
	CopyScriptFunctionBinding("CTFBot", "AddBotAttribute", "CTFPlayer", DHookCallback_ScriptAddAttribute_Pre);
	CopyScriptFunctionBinding("CTFBot", "AddBotTag", "CTFPlayer", DHookCallback_ScriptAddTag_Pre);
	CopyScriptFunctionBinding("CTFBot", "AddWeaponRestriction", "CTFPlayer", DHookCallback_ScriptSetWeaponRestriction_Pre);
	CopyScriptFunctionBinding("CTFBot", "ClearAllBotAttributes", "CTFPlayer", DHookCallback_ScriptClearAllAttributes_Pre);
	CopyScriptFunctionBinding("CTFBot", "ClearAllBotTags", "CTFPlayer", DHookCallback_ScriptClearTags_Pre);
	CopyScriptFunctionBinding("CTFBot", "ClearAllWeaponRestrictions", "CTFPlayer", DHookCallback_ScriptClearWeaponRestrictions);
	CopyScriptFunctionBinding("CTFBot", "DisbandCurrentSquad", "CTFPlayer", DHookCallback_ScriptDisbandAndDeleteSquad);
	CopyScriptFunctionBinding("CTFBot", "GenerateAndWearItem", "CTFPlayer");
	CopyScriptFunctionBinding("CTFBot", "HasBotAttribute", "CTFPlayer", DHookCallback_ScriptHasAttribute_Pre);
	CopyScriptFunctionBinding("CTFBot", "HasBotTag", "CTFPlayer", DHookCallback_ScriptHasTag_Pre);
	CopyScriptFunctionBinding("CTFBot", "IsInASquad", "CTFPlayer", DHookCallback_ScriptIsInASquad_Pre);
	CopyScriptFunctionBinding("CTFBot", "LeaveSquad", "CTFPlayer", DHookCallback_ScriptLeaveSquad_Pre);
	CopyScriptFunctionBinding("CTFBot", "HasWeaponRestriction", "CTFPlayer", DHookCallback_ScriptHasWeaponRestriction_Pre);
	CopyScriptFunctionBinding("CTFBot", "RemoveBotAttribute", "CTFPlayer", DHookCallback_ScriptRemoveAttribute_Pre);
	CopyScriptFunctionBinding("CTFBot", "RemoveBotTag", "CTFPlayer", DHookCallback_ScriptRemoveTag_Pre);
	CopyScriptFunctionBinding("CTFBot", "RemoveWeaponRestriction", "CTFPlayer", DHookCallback_ScriptRemoveWeaponRestriction_Pre);
	
	VScript_ResetScriptVM();
	
	CreateScriptDetour("CTFPlayer", "IsBotOfType", DHookCallback_ScriptIsBotOfType_Pre);
}

void DHooks_OnClientPutInServer(int client)
{
	if (g_hDHook_CBaseEntity_SetModel)
	{
		g_hDHook_CBaseEntity_SetModel.HookEntity(Hook_Post, client, DHookCallback_CBaseEntity_SetModel_Post);
	}
	
	if (g_hDHook_CBaseEntity_ShouldTransmit)
	{
		g_hDHook_CBaseEntity_ShouldTransmit.HookEntity(Hook_Pre, client, DHookCallback_CTFPlayer_ShouldTransmit_Pre);
	}
	
	if (g_hDHook_CBaseEntity_Event_Killed)
	{
		g_hDHook_CBaseEntity_Event_Killed.HookEntity(Hook_Pre, client, DHookCallback_CTFPlayer_EventKilled_Pre);
	}
	
	if (g_hDHook_CBaseCombatCharacter_ShouldGib)
	{
		g_hDHook_CBaseCombatCharacter_ShouldGib.HookEntity(Hook_Pre, client, DHookCallback_CTFPlayer_ShouldGib_Pre);
	}
	
	if (g_hDHook_CTFPlayer_IsAllowedToPickUpFlag)
	{
		g_hDHook_CTFPlayer_IsAllowedToPickUpFlag.HookEntity(Hook_Pre, client, DHookCallback_CTFPlayer_IsAllowedToPickUpFlag_Post);
	}
	
	if (g_hDHook_CBasePlayer_EntSelectSpawnPoint)
	{
		g_hDHook_CBasePlayer_EntSelectSpawnPoint.HookEntity(Hook_Pre, client, DHookCallback_CTFPlayer_EntSelectSpawnPoint_Pre);
	}
}

void DHooks_HookGamerules()
{
	if (g_hDHook_CGameRules_ClientConnected)
	{
		g_hDHook_CGameRules_ClientConnected.HookGamerules(Hook_Pre, DHookCallback_CTFGameRules_ClientConnected_Pre);
	}
	
	if (g_hDHook_CGameRules_FPlayerCanTakeDamage)
	{
		g_hDHook_CGameRules_FPlayerCanTakeDamage.HookGamerules(Hook_Pre, DHookCallback_CTFGameRules_FPlayerCanTakeDamage_Pre);
	}
}

void DHooks_OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "filter_tf_bot_has_tag"))
	{
		if (g_hDHook_CBaseFilter_PassesFilterImpl)
		{
			g_hDHook_CBaseFilter_PassesFilterImpl.HookEntity(Hook_Pre, entity, DHookCallback_CFilterTFBotHasTag_PassesFilterImpl_Pre);
		}
	}
	else if (StrEqual(classname, "item_teamflag"))
	{
		if (g_hDHook_CTFItem_PickUp)
		{
			g_hDHook_CTFItem_PickUp.HookEntity(Hook_Pre, entity, DHookCallback_CCaptureFlag_PickUp_Pre);
			g_hDHook_CTFItem_PickUp.HookEntity(Hook_Post, entity, DHookCallback_CCaptureFlag_PickUp_Post);
		}
	}
	else if (StrEqual(classname, "obj_teleporter"))
	{
		if (g_hDHook_CBaseObject_CanBeUpgraded)
		{
			g_hDHook_CBaseObject_CanBeUpgraded.HookEntity(Hook_Pre, entity, DHookCallback_CObjectTeleporter_CanBeUpgraded_Pre);
		}
		
		if (g_hDHook_CBaseObject_IsPlacementPosValid)
		{
			g_hDHook_CBaseObject_IsPlacementPosValid.HookEntity(Hook_Post, entity, DHookCallback_CObjectTeleporter_IsPlacementPosValid_Post);
		}
	}
	else if (strncmp(classname, "item_currencypack_", 18) == 0)
	{
		if (g_hDHook_CItem_ComeToRest)
		{
			g_hDHook_CItem_ComeToRest.HookEntity(Hook_Pre, entity, DHookCallback_CCurrencyPack_ComeToRest_Pre);
		}
	}
	else if (StrEqual(classname, "obj_sentrygun"))
	{
		if (g_hDHook_CBaseEntity_SetModel)
		{
			g_hDHook_CBaseEntity_SetModel.HookEntity(Hook_Post, entity, DHookCallback_CBaseEntity_SetModel_Post);
		}
	}
}

static void CreateDynamicDetour(GameData hGameData, const char[] name, DHookCallback callbackPre = INVALID_FUNCTION, DHookCallback callbackPost = INVALID_FUNCTION)
{
	DynamicDetour detour = DynamicDetour.FromConf(hGameData, name);
	if (detour)
	{
		if (callbackPre != INVALID_FUNCTION)
			detour.Enable(Hook_Pre, callbackPre);
		
		if (callbackPost != INVALID_FUNCTION)
			detour.Enable(Hook_Post, callbackPost);
	}
	else
	{
		LogError("Failed to create detour setup handle for %s", name);
	}
}

static DynamicHook CreateDynamicHook(GameData hGameData, const char[] name)
{
	DynamicHook hook = DynamicHook.FromConf(hGameData, name);
	if (!hook)
		LogError("Failed to create hook setup handle for %s", name);
	
	return hook;
}

static void CopyScriptFunctionBinding(const char[] sourceClassName, const char[] functionName, const char[] targetClassName, DHookCallback callback = INVALID_FUNCTION)
{
	VScriptFunction pTargetFunc = VScript_GetClassFunction("CTFPlayer", functionName);
	if (!pTargetFunc)
	{
		VScriptFunction pSourceFunc = VScript_GetClassFunction(sourceClassName, functionName);
		VScriptClass pTargetClass = VScript_GetClass(targetClassName);
		
		pTargetFunc = pTargetClass.CreateFunction();
		pTargetFunc.CopyFrom(pSourceFunc);
	}
	
	if (callback == INVALID_FUNCTION)
		return;
	
	DynamicDetour detour = pTargetFunc.CreateDetour();
	if (detour)
	{
		detour.Enable(Hook_Pre, callback);
	}
	else
	{
		LogError("Failed to create script detour: %s::%s", targetClassName, functionName);
	}
}

static void CreateScriptDetour(const char[] className, const char[] functionName, DHookCallback callback)
{
	DynamicDetour detour = VScript_GetClassFunction(className, functionName).CreateDetour();
	if (detour)
	{
		detour.Enable(Hook_Pre, callback);
	}
	else
	{
		LogError("Failed to create script detour: %s::%s", className, functionName);
	}
}

static MRESReturn DHookCallback_CTFGCServerSystem_PreClientUpdate_Pre()
{
	// Allows us to have an MvM server with 32 visible player slots
	GameRules_SetProp("m_bPlayingMannVsMachine", false);
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTFGCServerSystem_PreClientUpdate_Post()
{
	// Set it back afterwards
	GameRules_SetProp("m_bPlayingMannVsMachine", true);
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CPopulationManager_AllocateBots_Pre(int populator)
{
	// Do not allow the populator to allocate bots
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CPopulationManager_EndlessRollEscalation_Pre(int populator)
{
	g_bInEndlessRollEscalation = true;
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CPopulationManager_EndlessRollEscalation_Post(int populator)
{
	g_bInEndlessRollEscalation = false;
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CPopulationManager_RestoreCheckpoint_Pre(int populator)
{
	// NOTE: RestoreCheckpoint is called twice after a call to ResetMap().
	// After waiting for players ends, it will call this function again while `m_bIsInitialized` is `false`, then set it to `true`.
	// This technically starts waiting for players again on the first call, but we force it to terminate immediately on the second call.
	if (CPopulationManager(populator).m_bIsInitialized)
	{
		if (g_bInWaitingForPlayers)
		{
			g_bInWaitingForPlayers = false;
			tf_mvm_min_players_to_start.IntValue = 0;
		}
		
		SelectNewDefenders();
	}
	else
	{
		g_bInWaitingForPlayers = true;
		tf_mvm_min_players_to_start.IntValue = MaxClients + 1;
		
		CreateTimer(mp_waitingforplayers_time.FloatValue, Timer_OnWaitingForPlayersEnd);
	}
	
	return MRES_Ignored;
}

static void Timer_OnWaitingForPlayersEnd(Handle timer)
{
	if (!g_bInWaitingForPlayers)
		return;
	
	if (g_pPopulationManager.IsValid())
	{
		g_pPopulationManager.m_bIsInitialized = false;
		g_pPopulationManager.ResetMap();
	}
}

// The meat of the spawning logic. Any error happening in here WILL cause bots to spawn!
static MRESReturn DHookCallback_CTFBotSpawner_Spawn_Pre(CTFBotSpawner spawner, DHookReturn ret, DHookParam params)
{
	float rawHere[3];
	params.GetVector(1, rawHere);
	
	float here[3];
	here = Vector(rawHere[0], rawHere[1], rawHere[2]);
	
	CTFNavArea area = view_as<CTFNavArea>(TheNavMesh.GetNavArea(here));
	if (area && area.HasAttributeTF(NO_SPAWNING))
	{
		if (tf_populator_debug.BoolValue)
		{
			LogMessage("CTFBotSpawner: %3.2f: *** Tried to spawn in a NO_SPAWNING area at (%f, %f, %f)", GetGameTime(), here[0], here[1], here[2]);
		}
		
		ret.Value = false;
		return MRES_Supercede;
	}
	
	if (IsMannVsMachineMode())
	{
		// Only spawn players while the round is running in MVM mode
		if (GameRules_GetRoundState() != RoundState_RoundRunning)
		{
			ret.Value = false;
			return MRES_Supercede;
		}
	}
	
	// the ground may be variable here, try a few heights
	float z;
	for (z = 0.0; z < sv_stepsize.FloatValue; z += 4.0)
	{
		here[2] = rawHere[2] + sv_stepsize.FloatValue;
		
		if (SDKCall_IsSpaceToSpawnHere(here))
		{
			break;
		}
	}
	
	if (z >= sv_stepsize.FloatValue)
	{
		if (tf_populator_debug.BoolValue)
		{
			LogMessage("CTFBotSpawner: %3.2f: *** No space to spawn at (%f, %f, %f)", GetGameTime(), here[0], here[1], here[2]);
		}
		
		ret.Value = false;
		return MRES_Supercede;
	}
	
	if (IsMannVsMachineMode())
	{
		if (spawner.m_class == TFClass_Engineer && spawner.m_defaultAttributes.m_attributeFlags & TELEPORT_TO_HINT && SDKCall_CTFBotMvMEngineerHintFinder_FindHint(true, false) == false)
		{
			if (tf_populator_debug.BoolValue)
			{
				LogMessage("CTFBotSpawner: %3.2f: *** No teleporter hint for engineer", GetGameTime());
			}
			
			ret.Value = false;
			return MRES_Supercede;
		}
	}
	
	// find dead player we can re-use
	int newPlayer = FindNextInvader(spawner.m_defaultAttributes.m_attributeFlags & MINIBOSS);
	
	if (newPlayer != -1)
	{
		Player(newPlayer).ClearAllAttributes();
		
		// Remove any player attributes
		TF2Attrib_RemoveAll(newPlayer);
		
		// clear any old TeleportWhere settings 
		Player(newPlayer).ClearTeleportWhere();
		
		if (g_internalSpawnPoint == INVALID_ENT_REFERENCE || EntRefToEntIndex(g_internalSpawnPoint) == -1)
		{
			g_internalSpawnPoint = EntIndexToEntRef(CreateEntityByName("populator_internal_spawn_point"));
			DispatchSpawn(g_internalSpawnPoint);
		}
		
		char name[MAX_NAME_LENGTH];
		spawner.GetName(name, sizeof(name), "TFBot");
		Player(newPlayer).SetInvaderName(name, sm_mitm_rename_robots.BoolValue);
		
		CBaseEntity(g_internalSpawnPoint).SetAbsOrigin(here);
		CBaseEntity(g_internalSpawnPoint).SetLocalAngles(ZERO_VECTOR);
		Player(newPlayer).SetSpawnPoint(g_internalSpawnPoint);
		
		TFTeam team = TFTeam_Red;
		
		if (IsMannVsMachineMode())
		{
			team = TFTeam_Invaders;
		}
		
		TF2_ChangeClientTeam(newPlayer, team);
		
		SetEntProp(newPlayer, Prop_Data, "m_bAllowInstantSpawn", true);
		FakeClientCommand(newPlayer, "joinclass %s", g_aRawPlayerClassNames[spawner.m_class]);
		
		// Set the address of CTFPlayer::m_iszClassIcon from the return value of CTFBotSpawner::GetClassIcon.
		// Simply setting the value using SetEntPropString leads to segfaults, don't do that!
		Player(newPlayer).SetClassIconName(spawner.GetClassIcon());
		
		Player(newPlayer).ClearEventChangeAttributes();
		for (int i = 0; i < spawner.m_eventChangeAttributes.Count(); ++i)
		{
			Player(newPlayer).AddEventChangeAttributes(spawner.m_eventChangeAttributes.Get(i, GetOffset(NULL_STRING, "sizeof(EventChangeAttributes_t)")));
		}
		
		Player(newPlayer).SetTeleportWhere(spawner.m_teleportWhereName);
		
		if (spawner.m_defaultAttributes.m_attributeFlags & MINIBOSS)
		{
			SetEntProp(newPlayer, Prop_Send, "m_bIsMiniBoss", true);
		}
		
		if (spawner.m_defaultAttributes.m_attributeFlags & USE_BOSS_HEALTH_BAR)
		{
			SetEntProp(newPlayer, Prop_Send, "m_bUseBossHealthBar", true);
		}
		
		if (spawner.m_defaultAttributes.m_attributeFlags & AUTO_JUMP)
		{
			Player(newPlayer).SetAutoJump(spawner.m_flAutoJumpMin, spawner.m_flAutoJumpMax);
		}
		
		if (spawner.m_defaultAttributes.m_attributeFlags & BULLET_IMMUNE)
		{
			TF2_AddCondition(newPlayer, TFCond_BulletImmune);
		}
		
		if (spawner.m_defaultAttributes.m_attributeFlags & BLAST_IMMUNE)
		{
			TF2_AddCondition(newPlayer, TFCond_BlastImmune);
		}
		
		if (spawner.m_defaultAttributes.m_attributeFlags & FIRE_IMMUNE)
		{
			TF2_AddCondition(newPlayer, TFCond_FireImmune);
		}
		
		if (IsMannVsMachineMode())
		{
			// initialize currency to be dropped on death to zero
			SetEntProp(newPlayer, Prop_Send, "m_nCurrency", 0);
			
			// announce Spies
			if (spawner.m_class == TFClass_Spy)
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
			
		}
		
		Player(newPlayer).SetScaleOverride(spawner.m_scale);
		
		int nHealth = spawner.m_health;
		
		if (nHealth <= 0.0)
		{
			nHealth = TF2Util_GetEntityMaxHealth(newPlayer);
		}
		
		nHealth = RoundToFloor(float(nHealth) * g_pPopulationManager.GetHealthMultiplier(false));
		Player(newPlayer).ModifyMaxHealth(nHealth);
		
		Player(newPlayer).StartIdleSound();
		
		// Add our items first, they'll get replaced below by the normal MvM items if any are needed
		if (IsMannVsMachineMode() && (TF2_GetClientTeam(newPlayer) == TFTeam_Invaders))
		{
			// Apply the Rome 2 promo items to each player. They'll be 
			// filtered out for clients that do not have Romevision.
			CMissionPopulator pMission = s_MissionPopulator;
			if (pMission && pMission.m_mission == MISSION_DESTROY_SENTRIES)
			{
				Player(newPlayer).AddItem("tw_sentrybuster");
			}
			else
			{
				Player(newPlayer).AddItem(g_szRomePromoItems_Hat[spawner.m_class]);
				Player(newPlayer).AddItem(g_szRomePromoItems_Misc[spawner.m_class]);
			}
		}
		
		EventChangeAttributes_t pEventChangeAttributes = Player(newPlayer).GetEventChangeAttributes(g_pPopulationManager.GetDefaultEventChangeAttributesName());
		if (!pEventChangeAttributes)
		{
			pEventChangeAttributes = spawner.m_defaultAttributes;
		}
		Player(newPlayer).OnEventChangeAttributes(pEventChangeAttributes);
		
		int flag = Player(newPlayer).GetFlagToFetch();
		if (IsValidEntity(flag))
		{
			Player(newPlayer).SetFlagTarget(flag);
		}
		
		if (Player(newPlayer).HasAttribute(SPAWN_WITH_FULL_CHARGE))
		{
			// charge up our weapons
			
			// Medigun Ubercharge
			int weapon = GetPlayerWeaponSlot(newPlayer, TFWeaponSlot_Secondary);
			if (weapon != -1 && HasEntProp(weapon, Prop_Send, "m_flChargeLevel"))
			{
				SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", 1.0);
			}
			
			if (TF2_GetPlayerClass(newPlayer) != TFClass_Medic || Player(newPlayer).HasAttribute(PROJECTILE_SHIELD))
			{
				SetEntPropFloat(newPlayer, Prop_Send, "m_flRageMeter", 100.0);
			}
		}
		
		TFClassType nClassIndex = TF2_GetPlayerClass(newPlayer);
		
		if (GetEntProp(g_pObjectiveResource.index, Prop_Send, "m_nMvMEventPopfileType") == MVM_EVENT_POPFILE_HALLOWEEN)
		{
			// zombies use the original player models
			SetEntProp(newPlayer, Prop_Send, "m_nSkin", 4);
			
			char item[64];
			Format(item, sizeof(item), "Zombie %s", g_aRawPlayerClassNamesShort[nClassIndex]);
			
			Player(newPlayer).AddItem(item);
		}
		else
		{
			// use the nifty new robot model
			if (nClassIndex >= TFClass_Scout && nClassIndex <= TFClass_Engineer)
			{
				if (spawner.m_scale >= tf_mvm_miniboss_scale.FloatValue || Player(newPlayer).IsMiniBoss() && FileExists(g_szBotBossModels[nClassIndex], true))
				{
					SetVariantString(g_szBotBossModels[nClassIndex]);
					AcceptEntityInput(newPlayer, "SetCustomModelWithClassAnimations");
					SetEntProp(newPlayer, Prop_Data, "m_bloodColor", DONT_BLEED);
				}
				else if (FileExists(g_szBotModels[nClassIndex], true))
				{
					SetVariantString(g_szBotModels[nClassIndex]);
					AcceptEntityInput(newPlayer, "SetCustomModelWithClassAnimations");
					SetEntProp(newPlayer, Prop_Data, "m_bloodColor", DONT_BLEED);
				}
			}
		}
		
		if (params.Get(2))
		{
			CUtlVector result = CUtlVector(params.Get(2)); // EntityHandleVector_t
			result.AddToTail(GetEntityHandle(newPlayer));
		}
		
		// for easy access in populator spawner callbacks
		m_justSpawnedList.Push(newPlayer);
		
		if (IsMannVsMachineMode())
		{
			if (Player(newPlayer).IsMiniBoss())
			{
				HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_GIANT_CALLOUT", TFTeam_Defenders);
			}
		}
		
		if (tf_populator_debug.BoolValue)
		{
			LogMessage("%3.2f: Spawned player '%N'", GetGameTime(), newPlayer);
		}
	}
	else
	{
		if (tf_populator_debug.BoolValue)
		{
			LogMessage("CTFBotSpawner: %3.2f: *** Can't find player to spawn.", GetGameTime());
		}
		
		ret.Value = false;
		return MRES_Supercede;
	}
	
	ret.Value = true;
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CSquadSpawner_Spawn_Post(CSquadSpawner spawner, DHookReturn ret, DHookParam params)
{
	CUtlVector result = CUtlVector(params.Get(2));
	
	if (ret.Value && result)
	{
		// create the squad
		CTFBotSquad squad = CTFBotSquad.Create();
		if (squad)
		{
			squad.SetFormationSize(spawner.m_formationSize);
			squad.SetShouldPreserveSquad(spawner.m_bShouldPreserveSquad);
			
			for (int i = 0; i < result.Count(); ++i)
			{
				int bot = LoadEntityFromHandleAddress(result.Get(i));
				if (IsEntityClient(bot))
				{
					Player(bot).JoinSquad(squad);
				}
			}
		}
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CPopulationManager_Update_Pre(int populator)
{
	// allows spawners to freely switch teams of players
	g_bAllowTeamChange = true;
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CPopulationManager_Update_Post(int populator)
{
	g_bAllowTeamChange = false;
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CPeriodicSpawnPopulator_Update_Post(Address pThis)
{
	for (int i = 0; i < m_justSpawnedList.Length; i++)
	{
		int player = m_justSpawnedList.Get(i);
		if (IsEntityClient(player))
		{
			// what bot should do after spawning at teleporter exit
			if (s_spawnLocationResult == SPAWN_LOCATION_TELEPORTER)
			{
				OnBotTeleported(player);
			}
		}
	}
	
	// after we are done, clear the list
	m_justSpawnedList.Clear();
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CWaveSpawnPopulatorUpdate_Post(CWaveSpawnPopulator populator)
{
	for (int i = 0; i < m_justSpawnedList.Length; i++)
	{
		int player = m_justSpawnedList.Get(i);
		if (IsEntityClient(player))
		{
			Player(player).SetCustomCurrencyWorth(0);
			Player(player).SetWaveSpawnPopulator(populator);
			
			// Allows client UI to know if a specific spawner is active
			g_pObjectiveResource.SetMannVsMachineWaveClassActive(Player(player).GetClassIconName());
			
			if (populator.IsSupportWave())
			{
				Player(player).MarkAsSupportEnemy();
			}
			
			if (populator.IsLimitedSupportWave())
			{
				Player(player).MarkAsLimitedSupportEnemy();
			}
			
			// what bot should do after spawning at teleporter exit
			if (s_spawnLocationResult == SPAWN_LOCATION_TELEPORTER)
			{
				OnBotTeleported(player);
			}
		}
	}
	
	// after we are done, clear the list
	m_justSpawnedList.Clear();
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CMissionPopulator_UpdateMission_Pre(CMissionPopulator populator, DHookReturn ret, DHookParam params)
{
	MissionType mission = params.Get(1);
	
	ArrayList livePlayerList = new ArrayList();
	CollectPlayers(livePlayerList, TFTeam_Invaders, COLLECT_ONLY_LIVING_PLAYERS);
	
	s_activeMissionMembers = 0;
	
	for (int i = 0; i < livePlayerList.Length; ++i)
	{
		int player = livePlayerList.Get(i);
		if (Player(player).HasMission(mission))
		{
			++s_activeMissionMembers;
		}
	}
	
	if (s_activeMissionMembers > 0)
	{
		// wait until prior mission is dead
		
		// cooldown is time after death of last mission member
		m_cooldownTimer.Start(populator.m_cooldownDuration);
		
		delete livePlayerList;
		ret.Value = false;
		return MRES_Supercede;
	}
	
	if (!m_cooldownTimer.IsElapsed())
	{
		delete livePlayerList;
		ret.Value = false;
		return MRES_Supercede;
	}
	
	s_nSniperCount = 0;
	for (int i = 0; i < livePlayerList.Length; ++i)
	{
		int liveBot = livePlayerList.Get(i);
		if (TF2_GetPlayerClass(liveBot) == TFClass_Sniper)
		{
			s_nSniperCount++;
		}
	}
	
	delete livePlayerList;
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CMissionPopulator_UpdateMission_Post(Address pThis, DHookReturn ret, DHookParam params)
{
	MissionType mission = params.Get(1);
	
	for (int i = 0; i < m_justSpawnedList.Length; i++)
	{
		int player = m_justSpawnedList.Get(i);
		if (IsEntityClient(player))
		{
			Player(player).SetFlagTarget(INVALID_ENT_REFERENCE);
			Player(player).SetMission(mission);
			Player(player).MarkAsMissionEnemy();
			
			int iFlags = MVM_CLASS_FLAG_MISSION;
			if (Player(player).IsMiniBoss())
			{
				iFlags |= MVM_CLASS_FLAG_MINIBOSS;
			}
			else if (Player(player).HasAttribute(ALWAYS_CRIT))
			{
				iFlags |= MVM_CLASS_FLAG_ALWAYSCRIT;
			}
			g_pObjectiveResource.IncrementMannVsMachineWaveClassCount(Player(player).GetClassIconName(), iFlags);
			
			// Response rules stuff for MvM
			if (IsMannVsMachineMode())
			{
				// Only have defenders announce the arrival of the first enemy Sniper
				if (Player(player).HasMission(MISSION_SNIPER))
				{
					s_nSniperCount++;
					
					if (s_nSniperCount == 1)
					{
						HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_SNIPER_CALLOUT", TFTeam_Defenders);
					}
				}
			}
			
			if (s_spawnLocationResult == SPAWN_LOCATION_TELEPORTER)
			{
				OnBotTeleported(player);
			}
		}
	}
	
	// after we are done, clear the list
	m_justSpawnedList.Clear();
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CMissionPopulator_UpdateMissionDestroySentries_Pre(CMissionPopulator populator, DHookReturn ret)
{
	s_MissionPopulator = populator;
	
	if (!m_cooldownTimer.IsElapsed())
	{
		ret.Value = false;
		return MRES_Supercede;
	}
	
	if (!m_checkForDangerousSentriesTimer.IsElapsed())
	{
		ret.Value = false;
		return MRES_Supercede;
	}
	
	if (g_pPopulationManager.IsSpawningPaused())
	{
		ret.Value = false;
		return MRES_Supercede;
	}
	
	m_checkForDangerousSentriesTimer.Start(GetRandomFloat(5.0, 10.0));
	
	// collect all of the dangerous sentries
	ArrayList dangerousSentryList = new ArrayList();
	
	int nDmgLimit = 0;
	int nKillLimit = 0;
	g_pPopulationManager.GetSentryBusterDamageAndKillThreshold(nDmgLimit, nKillLimit);
	
	int obj = -1;
	while ((obj = FindEntityByClassname(obj, "obj_*")) != -1)
	{
		if (TF2_GetObjectType(obj) == TFObject_Sentry)
		{
			// Disposable sentries are not valid targets
			if (GetEntProp(obj, Prop_Send, "m_bDisposableBuilding"))
				continue;
			
			if (view_as<TFTeam>(GetEntProp(obj, Prop_Data, "m_iTeamNum")) == TFTeam_Defenders)
			{
				int sentryOwner = GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
				if (sentryOwner != -1)
				{
					int nDmgDone = RoundToFloor(Player(sentryOwner).m_accumulatedSentryGunDamageDealt);
					int nKillsMade = Player(sentryOwner).m_accumulatedSentryGunKillCount;
					
					if (nDmgDone >= nDmgLimit || nKillsMade >= nKillLimit)
					{
						dangerousSentryList.Push(obj);
					}
				}
			}
		}
	}
	
	ArrayList livePlayerList = new ArrayList();
	CollectPlayers(livePlayerList, TFTeam_Invaders, COLLECT_ONLY_LIVING_PLAYERS);
	
	// dispatch a sentry busting squad for each dangerous sentry
	bool didSpawn = false;
	
	for (int i = 0; i < dangerousSentryList.Length; ++i)
	{
		int targetSentry = dangerousSentryList.Get(i);
		
		// if there is already a squad out there destroying this sentry, don't spawn another one
		int j;
		for (j = 0; j < livePlayerList.Length; ++j)
		{
			int bot = livePlayerList.Get(j);
			if (Player(bot).HasMission(MISSION_DESTROY_SENTRIES) && Player(bot).GetMissionTarget() == targetSentry)
			{
				// there is already a sentry busting squad active for this sentry
				break;
			}
		}
		
		if (j < livePlayerList.Length)
		{
			continue;
		}
		
		// spawn a sentry buster squad to destroy this sentry
		float vSpawnPosition[3];
		SpawnLocationResult spawnLocationResult = SDKCall_CSpawnLocation_FindSpawnLocation(populator.m_where, vSpawnPosition);
		if (spawnLocationResult != SPAWN_LOCATION_NOT_FOUND)
		{
			// We don't actually pass a CUtlVector because it would require fetching or creating one in memory.
			// This is very tedious, so we just use our temporary list hack.
			if (populator.m_spawner && SDKCall_IPopulationSpawner_Spawn(populator.m_spawner, vSpawnPosition))
			{
				// success
				if (tf_populator_debug.BoolValue)
				{
					LogMessage("MANN VS MACHINE: %3.2f: <<<< Spawning Sentry Busting Mission >>>>", GetGameTime());
				}
				
				for (int k = 0; k < m_justSpawnedList.Length; ++k)
				{
					int bot = m_justSpawnedList.Get(k);
					
					Player(bot).SetFlagTarget(INVALID_ENT_REFERENCE);
					Player(bot).SetMission(MISSION_DESTROY_SENTRIES);
					Player(bot).SetMissionTarget(targetSentry);
					
					Player(bot).MarkAsMissionEnemy();
					
					didSpawn = true;
					
					SetVariantString(g_szBotBossSentryBusterModel);
					AcceptEntityInput(bot, "SetCustomModelWithClassAnimations");
					SetEntProp(bot, Prop_Data, "m_bloodColor", DONT_BLEED);
					
					SetVariantInt(1);
					AcceptEntityInput(bot, "SetForcedTauntCam");
					
					int iFlags = MVM_CLASS_FLAG_MISSION;
					if (Player(bot).IsMiniBoss())
					{
						iFlags |= MVM_CLASS_FLAG_MINIBOSS;
					}
					if (Player(bot).HasAttribute(ALWAYS_CRIT))
					{
						iFlags |= MVM_CLASS_FLAG_ALWAYSCRIT;
					}
					g_pObjectiveResource.IncrementMannVsMachineWaveClassCount(CTFBotSpawner(populator.m_spawner).GetClassIcon(k), iFlags);
					
					HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_SENTRY_BUSTER", TFTeam_Defenders);
					
					// what bot should do after spawning at teleporter exit
					if (spawnLocationResult == SPAWN_LOCATION_TELEPORTER)
					{
						OnBotTeleported(bot);
					}
				}
				
				// after we are done, clear the list
				m_justSpawnedList.Clear();
			}
		}
		else if (tf_populator_debug.BoolValue)
		{
			LogError("MissionPopulator: %3.2f: Can't find a place to spawn a sentry destroying squad", GetGameTime());
		}
	}
	
	if (didSpawn)
	{
		float flCoolDown = populator.m_cooldownDuration;
		
		CWave wave = g_pPopulationManager.GetCurrentWave();
		if (wave)
		{
			wave.IncrementSentryBustersSpawned();
			
			if (wave.NumSentryBustersSpawned() > 1)
			{
				BroadcastSound(255, "Announcer.MVM_Sentry_Buster_Alert_Another");
			}
			else
			{
				BroadcastSound(255, "Announcer.MVM_Sentry_Buster_Alert");
			}
			
			flCoolDown = populator.m_cooldownDuration + wave.NumSentryBustersKilled() * populator.m_cooldownDuration;
			
			wave.ResetSentryBustersKilled();
		}
		
		m_cooldownTimer.Start(flCoolDown);
	}
	
	delete dangerousSentryList;
	delete livePlayerList;
	
	ret.Value = didSpawn;
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CMissionPopulator_UpdateMissionDestroySentries_Post(Address pThis, DHookReturn ret)
{
	s_MissionPopulator = CMissionPopulator(Address_Null);
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CPointPopulatorInterface_InputChangeBotAttributes_Pre(int popInterface, DHookParam params)
{
	Address pszEventName = params.GetObjectVar(1, GetOffset("inputdata_t", "value"), ObjectValueType_Int);
	
	if (IsMannVsMachineMode())
	{
		ArrayList botList = new ArrayList();
		CollectPlayers(botList, TFTeam_Invaders, COLLECT_ONLY_LIVING_PLAYERS);
		
		for (int i = 0; i < botList.Length; ++i)
		{
			EventChangeAttributes_t pEvent = Player(botList.Get(i)).GetEventChangeAttributes(pszEventName);
			if (pEvent)
			{
				Player(botList.Get(i)).OnEventChangeAttributes(pEvent);
			}
		}
		
		delete botList;
	}
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFGameRules_PlayerReadyStatus_UpdatePlayerState_Pre(DHookParam params)
{
	if (sm_mitm_setup_time.IntValue <= 0)
		return MRES_Ignored;
	
	// Save off the old timer value
	g_flTempRestartRoundTime = GameRules_GetPropFloat("m_flRestartRoundTime");
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTFGameRules_PlayerReadyStatus_UpdatePlayerState_Post(DHookParam params)
{
	if (sm_mitm_setup_time.IntValue <= 0)
		return MRES_Ignored;
	
	// If m_flRestartRoundTime is -1.0 at this point, all players have toggled off ready
	if (GameRules_GetPropFloat("m_flRestartRoundTime") == -1.0)
	{
		// Prevent the timer from stopping by setting back the old value
		GameRules_SetPropFloat("m_flRestartRoundTime", g_flTempRestartRoundTime);
	}
	
	g_flTempRestartRoundTime = 0.0;
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTeamplayRoundBasedRules_ResetPlayerAndTeamReadyState_Pre()
{
	if (!g_pGameRules.IsValid())
		return MRES_Ignored;
	
	// Check if we came from CTFGameRules::PlayerReadyStatus_UpdatePlayerState
	if (GameRules_GetPropFloat("m_flRestartRoundTime") == -1.0 && g_flTempRestartRoundTime)
	{
		// When only one player is ready and they then unready, this function attempts to reset the "was ready before" state.
		// This would allow players to continously ready up to shorten the timer. Prevent this.
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTFGameRules_GetTeamAssignmentOverride_Pre(DHookReturn ret, DHookParam params)
{
	int player = params.Get(1);
	TFTeam nDesiredTeam = params.Get(2);
	
	if (IsClientSourceTV(player))
		return MRES_Ignored;
	
	// allow this function to set each player's team and currency
	SetEntityFlags(player, GetEntityFlags(player) & ~FL_FAKECLIENT);
	
	if (g_bInWaitingForPlayers)
	{
		params.Set(2, TFTeam_Defenders);
		return MRES_ChangedHandled;
	}
	else if (g_bAllowTeamChange || (sm_mitm_developer.BoolValue && !IsFakeClient(player)))
	{
		if (nDesiredTeam == TFTeam_Spectator || nDesiredTeam == TFTeam_Defenders)
			return MRES_Ignored;
		
		ret.Value = nDesiredTeam;
		return MRES_Supercede;
	}
	else
	{
		// player is trying to switch from invaders to spectate
		if (nDesiredTeam == TFTeam_Spectator && TF2_GetClientTeam(player) == TFTeam_Invaders && !sm_mitm_invader_allow_suicide.BoolValue)
		{
			if (IsPlayerAlive(player))
				PrintCenterText(player, "%t", "Invader_NotAllowedToSuicide");
			
			ret.Value = TF2_GetClientTeam(player);
			return MRES_Supercede;
		}
		
		if (!Forwards_OnIsValidDefender(player))
		{
			params.Set(2, TFTeam_Spectator);
			return MRES_ChangedHandled;
		}
		
		int iDefenderCount = 0;
		
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client))
				continue;
			
			if (TF2_GetClientTeam(client) == TFTeam_Defenders)
				iDefenderCount++;
		}
		
		// players can join defenders freely if a slot is open
		if (iDefenderCount >= sm_mitm_defender_count.IntValue ||
			Player(player).IsInAParty() ||
			Player(player).HasPreference(PREF_DISABLE_DEFENDER) ||
			Player(player).HasPreference(PREF_DISABLE_SPAWNING))
		{
			params.Set(2, TFTeam_Spectator);
			return MRES_ChangedHandled;
		}
		else
		{
			params.Set(2, TFTeam_Defenders);
			return MRES_ChangedHandled;
		}
	}
}

static MRESReturn DHookCallback_CTFGameRules_GetTeamAssignmentOverride_Post(DHookReturn ret, DHookParam params)
{
	if (ret.Value == TFTeam_Invaders)
	{
		// any player joining the invader team needs to be marked as a bot
		int player = params.Get(1);
		SetEntityFlags(player, GetEntityFlags(player) | FL_FAKECLIENT);
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTFPlayer_GetLoadoutItem_Pre(int player, DHookReturn ret, DHookParam params)
{
	if (IsClientInGame(player) && TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		// generate base items for robot players
		GameRules_SetProp("m_bIsInTraining", true);
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTFPlayer_GetLoadoutItem_Post(int player, DHookReturn ret, DHookParam params)
{
	if (IsClientInGame(player) && TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		GameRules_SetProp("m_bIsInTraining", false);
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTFPlayer_CheckInstantLoadoutRespawn_Pre(int player)
{
	// never allow invaders to respawn with a new loadout, this breaks spawners
	return TF2_GetClientTeam(player) == TFTeam_Invaders ? MRES_Supercede : MRES_Ignored;
}

static MRESReturn DHookCallback_CTFPlayer_DoClassSpecialSkill_Pre(int player, DHookReturn ret)
{
	if (TF2_GetPlayerClass(player) == TFClass_DemoMan && GetEntProp(player, Prop_Send, "m_bShieldEquipped"))
	{
		float velocity[3];
		GetEntPropVector(player, Prop_Data, "m_vecAbsVelocity", velocity);
		
		if (Player(player).HasAttribute(AIR_CHARGE_ONLY) && (GetEntPropEnt(player, Prop_Send, "m_hGroundEntity") != -1 || velocity[2] > 0.0))
		{
			ret.Value = false;
			return MRES_Supercede;
		}
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTFPlayer_RemoveAllOwnedEntitiesFromWorld_Pre(int player, DHookParam params)
{
	// keep this bot's buildings
	return Player(player).HasAttribute(RETAIN_BUILDINGS) ? MRES_Supercede : MRES_Ignored;
}

static MRESReturn DHookCallback_CTFPlayer_CanBuild_Pre(int player, DHookReturn ret, DHookParam params)
{
	if (TF2_GetClientTeam(player) == TFTeam_Invaders && TF2_GetPlayerClass(player) == TFClass_Engineer)
	{
		// prevent human robot engineers from building multiple sentries
		SetEntityFlags(player, GetEntityFlags(player) & ~FL_FAKECLIENT);
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTFPlayer_CanBuild_Post(int player, DHookReturn ret, DHookParam params)
{
	if (TF2_GetClientTeam(player) == TFTeam_Invaders && TF2_GetPlayerClass(player) == TFClass_Engineer)
	{
		SetEntityFlags(player, GetEntityFlags(player) | FL_FAKECLIENT);
		
		// early out if we cannot build right now
		if (ret.Value != CB_CAN_BUILD)
			return MRES_Ignored;
		
		TFObjectType iObjectType = params.Get(1);
		TFObjectMode iObjectMode = params.Get(2);
		
		bool bDisallowBuilding = false;
		
		switch (iObjectType)
		{
			// dispenser: cannot be built
			case TFObject_Dispenser:
			{
				bDisallowBuilding = true;
			}
			// teleporter: only exit can be built with teleporter hint
			case TFObject_Teleporter, TFObject_Sapper:
			{
				bDisallowBuilding = (iObjectMode == TFObjectMode_Entrance) || (FindTeleporterHintForPlayer(player) == -1);
			}
			// sentry: can only be built with sentry hint
			case TFObject_Sentry:
			{
				bDisallowBuilding = (FindSentryHintForPlayer(player) == -1);
			}
		}
		
		if (bDisallowBuilding)
		{
			EmitGameSoundToClient(player, "Player.DenyWeaponSelection");
			ret.Value = CB_CANNOT_BUILD;
			return MRES_Supercede;
		}
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CWeaponMedigun_AllowedToHealTarget_Pre(int medigun, DHookReturn ret, DHookParam params)
{
	int target = params.Get(1);
	int owner = GetEntPropEnt(medigun, Prop_Send, "m_hOwnerEntity");
	
	if (TF2_GetClientTeam(owner) == TFTeam_Invaders)
	{
		// medics in a squad should only ever heal their squad leader
		if (Player(owner).IsInASquad() && Player(owner).GetSquad().GetLeader() != -1)
		{
			CTFBotSquad squad = Player(owner).GetSquad();
			if (squad.IsLeader(owner) || squad.IsLeader(target))
			{
				// allow healing the squad leader, or everyone if we are the leader
				return MRES_Ignored;
			}
			
			PrintCenterText(owner, "%t", "Medic_Squad_NotAllowedToHeal", squad.GetLeader());
			
			// disallow healing everyone else
			ret.Value = false;
			return MRES_Supercede;
		}
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CSpawnLocation_FindSpawnLocation_Post(Address where, DHookReturn ret, DHookParam params)
{
	// Store for use in populator callbacks.
	// We can't use CWaveSpawnPopulator::m_spawnLocationResult because it gets overridden in some cases.
	s_spawnLocationResult = ret.Value;
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTraceFilterObject_ShouldHitEntity_Post(Address pFilter, DHookReturn ret, DHookParam params)
{
	int me = GetEntityFromAddress(LoadFromAddress(pFilter + GetOffset("CTraceFilterSimple", "m_pPassEnt"), NumberType_Int32));
	int entity = GetEntityFromAddress(params.Get(1));
	
	if (IsEntityClient(entity))
	{
		if (IsMannVsMachineMode())
		{
			if (Player(entity).HasMission(MISSION_DESTROY_SENTRIES))
			{
				// Don't collide with sentry busters since they don't collide with us
				ret.Value = false;
				return MRES_Supercede;
			}
			
			if (Player(me).HasMission(MISSION_DESTROY_SENTRIES))
			{
				// Sentry Busters don't collide with enemies (so they can't be body-blocked)
				ret.Value = false;
				return MRES_Supercede;
			}
		}
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CLagCompensationManager_StartLagCompensation_Pre(DHookParam params)
{
	int player = params.Get(1);
	
	if (TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		// re-enable lag compensation for our "human bots"
		SetEntityFlags(player, GetEntityFlags(player) & ~FL_FAKECLIENT);
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CLagCompensationManager_StartLagCompensation_Post(DHookParam params)
{
	int player = params.Get(1);
	
	if (TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		SetEntityFlags(player, GetEntityFlags(player) | FL_FAKECLIENT);
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CUniformRandomStream_SetSeed_Pre(DHookParam params)
{
	if (g_bInEndlessRollEscalation)
	{
		// force endless to be truly random
		params.Set(1, GetRandomInt(0, INT_MAX));
		return MRES_ChangedHandled;
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_DoTeleporterOverride_Post(DHookReturn ret, DHookParam params)
{
	CBaseEntity spawnEnt = CBaseEntity(params.Get(1));
	
	float vSpawnPosition[3];
	params.GetVector(2, vSpawnPosition);
	
	bool bClosestPointOnNav = params.Get(3);
	
	ArrayList teleporterList = new ArrayList();
	
	int obj = -1;
	while ((obj = FindEntityByClassname(obj, "obj_*")) != -1)
	{
		if (TF2_GetObjectType(obj) != TFObject_Teleporter)
			continue;
		
		if (view_as<TFTeam>(GetEntProp(obj, Prop_Data, "m_iTeamNum")) != TFTeam_Invaders)
			continue;
		
		if (GetEntProp(obj, Prop_Send, "m_bBuilding"))
			continue;
		
		if (GetEntProp(obj, Prop_Send, "m_bCarried"))
			continue;
		
		if (GetEntProp(obj, Prop_Send, "m_bHasSapper"))
			continue;
		
		if (GetEntProp(obj, Prop_Send, "m_bPlasmaDisable"))
			continue;
		
		char szSpawnPointName[64];
		spawnEnt.GetPropString(Prop_Data, "m_iName", szSpawnPointName, sizeof(szSpawnPointName));
		
		for (int iTelePoints = 0; iTelePoints < Entity(obj).GetTeleportWhere().Length; ++iTelePoints)
		{
			char teleportWhereName[64];
			Entity(obj).GetTeleportWhere().GetString(iTelePoints, teleportWhereName, sizeof(teleportWhereName));
			
			if (StrEqual(teleportWhereName, szSpawnPointName, false))
			{
				teleporterList.Push(obj);
				break;
			}
		}
	}
	
	if (teleporterList.Length > 0)
	{
		int which = GetRandomInt(0, teleporterList.Length - 1);
		CBaseEntity teleporter = CBaseEntity(teleporterList.Get(which));
		teleporter.WorldSpaceCenter(vSpawnPosition);
		s_lastTeleporter = teleporter;
		
		delete teleporterList;
		params.SetVector(2, vSpawnPosition);
		ret.Value = SPAWN_LOCATION_TELEPORTER;
		return MRES_Supercede;
	}
	
	float spawnEntCenter[3];
	spawnEnt.WorldSpaceCenter(spawnEntCenter);
	
	CNavArea nav = TheNavMesh.GetNearestNavArea(spawnEntCenter);
	if (!nav)
	{
		delete teleporterList;
		ret.Value = SPAWN_LOCATION_NOT_FOUND;
		return MRES_Supercede;
	}
	
	nav.GetCenter(vSpawnPosition);
	
	if (bClosestPointOnNav)
	{
		nav.GetClosestPointOnArea(spawnEntCenter, vSpawnPosition);
	}
	else
	{
		nav.GetCenter(vSpawnPosition);
	}
	
	delete teleporterList;
	params.SetVector(2, vSpawnPosition);
	ret.Value = SPAWN_LOCATION_NAV;
	return MRES_Supercede;
}

static MRESReturn DHookCallback_OnBotTeleported_Pre(DHookParam params)
{
	// This crashes our server in local testing due to s_lastTeleporter being null
	return MRES_Supercede;
}

void OnBotTeleported(int bot)
{
	float origin[3], angles[3];
	s_lastTeleporter.GetAbsOrigin(origin);
	s_lastTeleporter.GetAbsAngles(angles);
	
	// don't too many sound and effect when lots of bots teleporting in short time.
	if (GetGameTime() - s_flLastTeleportTime > 0.1)
	{
		EmitGameSoundToAll("MVM.Robot_Teleporter_Deliver", s_lastTeleporter.index, .origin = origin);
		
		s_flLastTeleportTime = GetGameTime();
	}
	
	// force bot to face in the direction specified by the teleporter
	TeleportEntity(bot, .angles = angles);
	
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

static MRESReturn DHookCallback_CTFPlayer_ShouldTransmit_Pre(int player, DHookReturn ret, DHookParam params)
{
	if (Player(player).HasAttribute(USE_BOSS_HEALTH_BAR))
	{
		ret.Value = FL_EDICT_ALWAYS;
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTFPlayer_EventKilled_Pre(int player, DHookParam params)
{
	// Replicate behavior of CTFBot::Event_Killed
	if (TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		// announce Spies
		if (TF2_GetPlayerClass(player) == TFClass_Spy)
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
		else if (TF2_GetPlayerClass(player) == TFClass_Engineer)
		{
			// in MVM, when an engineer dies, we need to decouple his objects so they stay alive when his bot slot gets recycled
			while (TF2Util_GetPlayerObjectCount(player) > 0)
			{
				// set to not have owner
				int obj = TF2Util_GetPlayerObject(player, 0);
				if (obj != -1)
				{
					SetEntityOwner(obj, -1);
					SetEntPropEnt(obj, Prop_Send, "m_hBuilder", -1);
				}
				SDKCall_CTFPlayer_RemoveObject(player, obj);
			}
			
			// unown engineer nest if owned any
			int hint = -1;
			while ((hint = FindEntityByClassname(hint, "bot_hint_*")) != -1)
			{
				if (GetEntPropEnt(hint, Prop_Send, "m_hOwnerEntity") == player)
				{
					SetEntityOwner(hint, -1);
				}
			}
			
			ArrayList playerList = new ArrayList();
			CollectPlayers(playerList, TFTeam_Invaders, COLLECT_ONLY_LIVING_PLAYERS);
			bool bShouldAnnounceLastEngineerBotDeath = Player(player).HasAttribute(TELEPORT_TO_HINT);
			if (bShouldAnnounceLastEngineerBotDeath)
			{
				for (int i = 0; i < playerList.Length; ++i)
				{
					if (playerList.Get(i) != player && TF2_GetPlayerClass(playerList.Get(i)) == TFClass_Engineer)
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
		
		if (Player(player).IsInASquad())
		{
			Player(player).LeaveSquad();
		}
		
		Player(player).StopIdleSound();
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTFPlayer_ShouldGib_Pre(int player, DHookReturn ret, DHookParam params)
{
	// only gib giant/miniboss
	if (IsMannVsMachineMode() && (Player(player).IsMiniBoss() || GetEntPropFloat(player, Prop_Send, "m_flModelScale") > 1.0))
	{
		ret.Value = true;
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTFPlayer_IsAllowedToPickUpFlag_Post(int player, DHookReturn ret)
{
	// only the leader of a squad can pick up the flag
	if (Player(player).IsInASquad() && !Player(player).GetSquad().IsLeader(player))
	{
		ret.Value = false;
		return MRES_Supercede;
	}
	
	// mission bots can't pick up the flag
	if (Player(player).IsOnAnyMission())
	{
		ret.Value = false;
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTFPlayer_EntSelectSpawnPoint_Pre(int player, DHookReturn ret)
{
	// override normal spawn behavior to spawn robots at the right place
	if (IsValidEntity(Player(player).m_spawnPointEntity))
	{
		ret.Value = Player(player).m_spawnPointEntity;
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CFilterTFBotHasTag_PassesFilterImpl_Pre(int filter, DHookReturn ret, DHookParam params)
{
	if (params.IsNull(2))
		return MRES_Ignored;
	
	int entity = params.Get(2);
	
	if (IsEntityClient(entity) && TF2_GetClientTeam(entity) == TFTeam_Invaders)
	{
		bool bRequireAllTags = GetEntProp(filter, Prop_Data, "m_bRequireAllTags") != 0;
		
		char iszTags[512];
		GetEntPropString(filter, Prop_Data, "m_iszTags", iszTags, sizeof(iszTags));
		
		// max. 8 tags with a length of 64 characters each
		char tags[8][64];
		int count = ExplodeString(iszTags, " ", tags, sizeof(tags), sizeof(tags[]));
		
		bool bPasses = false;
		for (int i = 0; i < count; ++i)
		{
			if (Player(entity).HasTag(tags[i]))
			{
				bPasses = true;
				if (!bRequireAllTags)
				{
					break;
				}
			}
			else if (bRequireAllTags)
			{
				ret.Value = false;
				return MRES_Supercede;
			}
		}
		
		ret.Value = bPasses;
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CCaptureFlag_PickUp_Pre(int item, DHookParam params)
{
	int player = params.Get(1);
	
	if (IsMannVsMachineMode() && TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		// do not trip up the assert_cast< CTFBot* >
		SetEntityFlags(player, GetEntityFlags(player) & ~FL_FAKECLIENT);
		
		if (Player(player).HasAttribute(IGNORE_FLAG))
			return MRES_Supercede;
		
		Player(player).SetFlagTarget(EntIndexToEntRef(item));
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CCaptureFlag_PickUp_Post(int item, DHookParam params)
{
	int player = params.Get(1);
	
	if (IsMannVsMachineMode() && TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		SetEntityFlags(player, GetEntityFlags(player) | FL_FAKECLIENT);
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CBaseEntity_SetModel_Post(int entity, DHookParam params)
{
	char szModelName[PLATFORM_MAX_PATH];
	params.GetString(1, szModelName, sizeof(szModelName));
	
	int hGlowEntity = Entity(entity).GetGlowEntity();
	if (IsValidEntity(hGlowEntity))
	{
		// we already have a glow, update it with the new model
		SetEntityModel(hGlowEntity, szModelName);
	}
	else
	{
		// no existing glow entity, create one
		Entity(entity).SetGlowEntity(CreateEntityGlow(entity));
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CObjectTeleporter_IsPlacementPosValid_Post(int obj, DHookReturn ret)
{
	if (!ret.Value)
	{
		return MRES_Ignored;
	}
	
	int builder = GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
	if (builder == -1 || TF2_GetClientTeam(builder) != TFTeam_Invaders)
	{
		return MRES_Ignored;
	}
	
	// m_vecBuildOrigin is the proposed build origin
	float vecTestPos[3];
	GetEntDataVector(obj, GetOffset("CBaseObject", "m_vecBuildOrigin"), vecTestPos);
	vecTestPos[2] += 12.0; // TELEPORTER_MAXS.z
	
	// giants don't tend to be bigger than 1.9 scale
	float vecHullMins[3] = VEC_HULL_MIN;
	float vecHullMaxs[3] = VEC_HULL_MAX;
	ScaleVector(vecHullMins, 1.9);
	ScaleVector(vecHullMaxs, 1.9);
	
	// make sure we can fit a giant player on top in this pos
	TR_TraceHullFilter(vecTestPos, vecTestPos, vecHullMins, vecHullMaxs, MASK_SOLID | CONTENTS_PLAYERCLIP, TraceEntityFilter_IsPlacementPosValid, COLLISION_GROUP_PLAYER_MOVEMENT);
	
	ret.Value = TR_GetFraction() >= 1.0;
	return MRES_Supercede;
}

static bool TraceEntityFilter_IsPlacementPosValid(int entity, int contentsMask, Collision_Group_t collisionGroup)
{
	if (entity == -1)
		return false;
	
	if (!SDKCall_CBaseEntity_ShouldCollide(entity, collisionGroup, contentsMask))
		return false;
	
	if (entity != -1 && !SDKCall_CGameRules_ShouldCollide(collisionGroup, view_as<Collision_Group_t>(GetEntProp(entity, Prop_Send, "m_CollisionGroup"))))
		return false;
	
	return true;
}

static MRESReturn DHookCallback_CObjectTeleporter_CanBeUpgraded_Pre(int obj, DHookReturn ret, DHookParam params)
{
	int player = params.Get(1);
	
	if (TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		if (TF2_GetObjectType(obj) == TFObject_Teleporter)
		{
			ret.Value = false;
			return MRES_Supercede;
		}
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CCurrencyPack_ComeToRest_Pre(int item)
{
	float origin[3];
	GetEntPropVector(item, Prop_Data, "m_vecAbsOrigin", origin);
	
	// if we've come to rest in the enemy spawn, just grant the money to the player
	CTFNavArea area = view_as<CTFNavArea>(TheNavMesh.GetNavArea(origin));
	
	if (area && (area.HasAttributeTF(BLUE_SPAWN_ROOM) || area.HasAttributeTF(RED_SPAWN_ROOM)))
	{
		SDKCall_CTFGameRules_DistributeCurrencyAmount(GetEntData(item, GetOffset("CCurrencyPack", "m_nAmount")));
		SetEntData(item, GetOffset("CCurrencyPack", "m_bTouched"), true, 1);
		RemoveEntity(item);
		
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTFGameRules_ClientConnected_Pre(DHookReturn ret, DHookParam params)
{
	// MvM will start rejecting connections if the server has 10 humans
	ret.Value = true;
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFGameRules_FPlayerCanTakeDamage_Pre(DHookReturn ret, DHookParam params)
{
	if (g_bForceFriendlyFire)
	{
		params.SetObjectVar(3, GetOffset("CTakeDamageInfo", "m_bForceFriendlyFire"), ObjectValueType_Bool, true);
		return MRES_ChangedHandled;
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_ScriptIsBotOfType_Pre(int player, DHookReturn ret, DHookParam param)
{
	int botType = param.Get(1);
	
	// make scripts believe that all invaders are TFBots
	if (botType == TF_BOT_TYPE && Player(player).IsInvader())
	{
		ret.Value = true;
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_ScriptAddAttribute_Pre(int bot, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	Player(bot).SetAttribute(params.Get(1));
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_ScriptAddTag_Pre(int bot, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	char tag[64];
	params.GetString(1, tag, sizeof(tag));
	
	Player(bot).AddTag(tag);
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_ScriptSetWeaponRestriction_Pre(int bot, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	Player(bot).SetWeaponRestriction(params.Get(1));
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_ScriptClearAllAttributes_Pre(int bot)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	Player(bot).ClearAllAttributes();
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_ScriptClearTags_Pre(int bot)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	Player(bot).ClearTags();
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_ScriptClearWeaponRestrictions(int bot)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	Player(bot).ClearWeaponRestrictions();
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_ScriptDisbandAndDeleteSquad(int bot)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	CTFBotSquad squad = Player(bot).GetSquad();
	if (squad)
	{
		squad.DisbandAndDeleteSquad();
	}
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_ScriptHasAttribute_Pre(int bot, DHookReturn ret, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	ret.Value = Player(bot).HasAttribute(params.Get(1));
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_ScriptHasTag_Pre(int bot, DHookReturn ret, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	char tag[64];
	params.GetString(1, tag, sizeof(tag));
	
	ret.Value = Player(bot).HasTag(tag);
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_ScriptIsInASquad_Pre(int bot, DHookReturn ret)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	ret.Value = Player(bot).IsInASquad();
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_ScriptLeaveSquad_Pre(int bot)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	Player(bot).LeaveSquad();
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_ScriptHasWeaponRestriction_Pre(int bot, DHookReturn ret, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	ret.Value = Player(bot).HasWeaponRestriction(params.Get(1));
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_ScriptRemoveAttribute_Pre(int bot, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	Player(bot).ClearAttribute(params.Get(1));
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_ScriptRemoveTag_Pre(int bot, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	char tag[64];
	params.GetString(1, tag, sizeof(tag));
	
	Player(bot).RemoveTag(tag);
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_ScriptRemoveWeaponRestriction_Pre(int bot, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	Player(bot).RemoveWeaponRestriction(params.Get(1));
	
	return MRES_Supercede;
}
