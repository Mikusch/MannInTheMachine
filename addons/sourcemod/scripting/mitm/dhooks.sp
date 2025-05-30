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
static DynamicHook g_hDHook_CBaseEntity_FVisible;
static DynamicHook g_hDHook_CBaseObject_IsPlacementPosValid;
static DynamicHook g_hDHook_CBaseObject_CanBeUpgraded;
static DynamicHook g_hDHook_CItem_ComeToRest;
static DynamicHook g_hDHook_CBaseEntity_ShouldTransmit;
static DynamicHook g_hDHook_CBaseCombatCharacter_ShouldGib;
static DynamicHook g_hDHook_CTFPlayer_IsAllowedToPickUpFlag;
static DynamicHook g_hDHook_CBasePlayer_EntSelectSpawnPoint;
static DynamicHook g_hDHook_CBaseFilter_PassesFilterImpl;
static DynamicHook g_hDHook_CTFItem_PickUp;
static DynamicHook g_hDHook_CTeamplayRoundBasedRules_RespawnPlayers;

static bool g_bPrevPlayingMannVsMachine;
static ArrayList m_justSpawnedList;

static int g_internalSpawnPoint = INVALID_ENT_REFERENCE;
static SpawnLocationResult s_spawnLocationResult = SPAWN_LOCATION_NOT_FOUND;
static float g_flTempRestartRoundTime;

// CMissionPopulator
static CountdownTimer m_cooldownTimer;
static CountdownTimer m_checkForDangerousSentriesTimer;
static CMissionPopulator s_missionPopulator;
static int s_activeMissionMembers;
static int s_nSniperCount;

// MvM Engineer Teleporter
static CBaseEntity s_lastTeleporter;
static float s_flLastTeleportTime;

void DHooks_Init()
{
	m_justSpawnedList = new ArrayList();
	m_cooldownTimer = new CountdownTimer();
	m_checkForDangerousSentriesTimer = new CountdownTimer();
	
	PSM_AddDynamicDetourFromConf("CTFGCServerSystem::PreClientUpdate", DHookCallback_CTFGCServerSystem_PreClientUpdate_Pre, DHookCallback_CTFGCServerSystem_PreClientUpdate_Post);
	PSM_AddDynamicDetourFromConf("CPopulationManager::AllocateBots", DHookCallback_CPopulationManager_AllocateBots_Pre);
	PSM_AddDynamicDetourFromConf("CPopulationManager::EndlessRollEscalation", DHookCallback_CPopulationManager_EndlessRollEscalation_Pre, DHookCallback_CPopulationManager_EndlessRollEscalation_Post);
	PSM_AddDynamicDetourFromConf("CTFBotSpawner::Spawn", DHookCallback_CTFBotSpawner_Spawn_Pre);
	PSM_AddDynamicDetourFromConf("CSquadSpawner::Spawn", _, DHookCallback_CSquadSpawner_Spawn_Post);
	PSM_AddDynamicDetourFromConf("CPopulationManager::Update", DHookCallback_CPopulationManager_Update_Pre, DHookCallback_CPopulationManager_Update_Post);
	PSM_AddDynamicDetourFromConf("CPeriodicSpawnPopulator::Update", _, DHookCallback_CPeriodicSpawnPopulator_Update_Post);
	PSM_AddDynamicDetourFromConf("CWaveSpawnPopulator::Update", _, DHookCallback_CWaveSpawnPopulator_Update_Post);
	PSM_AddDynamicDetourFromConf("CMissionPopulator::UpdateMission", DHookCallback_CMissionPopulator_UpdateMission_Pre, DHookCallback_CMissionPopulator_UpdateMission_Post);
	PSM_AddDynamicDetourFromConf("CMissionPopulator::UpdateMissionDestroySentries", DHookCallback_CMissionPopulator_UpdateMissionDestroySentries_Pre, DHookCallback_CMissionPopulator_UpdateMissionDestroySentries_Post);
	PSM_AddDynamicDetourFromConf("CPointPopulatorInterface::InputChangeBotAttributes", DHookCallback_CPointPopulatorInterface_InputChangeBotAttributes_Pre);
	PSM_AddDynamicDetourFromConf("CTFGameRules::GetTeamAssignmentOverride", DHookCallback_CTFGameRules_GetTeamAssignmentOverride_Pre, DHookCallback_CTFGameRules_GetTeamAssignmentOverride_Post);
	PSM_AddDynamicDetourFromConf("CTFGameRules::PlayerReadyStatus_UpdatePlayerState", DHookCallback_CTFGameRules_PlayerReadyStatus_UpdatePlayerState_Pre, DHookCallback_CTFGameRules_PlayerReadyStatus_UpdatePlayerState_Post);
	PSM_AddDynamicDetourFromConf("CTeamplayRoundBasedRules::ResetPlayerAndTeamReadyState", DHookCallback_CTeamplayRoundBasedRules_ResetPlayerAndTeamReadyState_Pre);
	PSM_AddDynamicDetourFromConf("CTFPlayer::GetLoadoutItem", DHookCallback_CTFPlayer_GetLoadoutItem_Pre, DHookCallback_CTFPlayer_GetLoadoutItem_Post);
	PSM_AddDynamicDetourFromConf("CTFPlayer::CheckInstantLoadoutRespawn", DHookCallback_CTFPlayer_CheckInstantLoadoutRespawn_Pre);
	PSM_AddDynamicDetourFromConf("CTFPlayer::DoClassSpecialSkill", DHookCallback_CTFPlayer_DoClassSpecialSkill_Pre);
	PSM_AddDynamicDetourFromConf("CTFPlayer::RemoveAllOwnedEntitiesFromWorld", DHookCallback_CTFPlayer_RemoveAllOwnedEntitiesFromWorld_Pre);
	PSM_AddDynamicDetourFromConf("CTFPlayer::CanBuild", DHookCallback_CTFPlayer_CanBuild_Pre, DHookCallback_CTFPlayer_CanBuild_Post);
	PSM_AddDynamicDetourFromConf("CTFPlayer::ForceChangeTeam", DHookCallback_CTFPlayer_ForceChangeTeam_Pre, DHookCallback_CTFPlayer_ForceChangeTeam_Post);
	PSM_AddDynamicDetourFromConf("CWeaponMedigun::AllowedToHealTarget", DHookCallback_CWeaponMedigun_AllowedToHealTarget_Pre);
	PSM_AddDynamicDetourFromConf("CSpawnLocation::FindSpawnLocation", _, DHookCallback_CSpawnLocation_FindSpawnLocation_Post);
	PSM_AddDynamicDetourFromConf("CTraceFilterObject::ShouldHitEntity", DHookCallback_CTraceFilterObject_ShouldHitEntity_Pre);
	PSM_AddDynamicDetourFromConf("CLagCompensationManager::StartLagCompensation", DHookCallback_CLagCompensationManager_StartLagCompensation_Pre, DHookCallback_CLagCompensationManager_StartLagCompensation_Post);
	PSM_AddDynamicDetourFromConf("CUniformRandomStream::SetSeed", DHookCallback_CUniformRandomStream_SetSeed_Pre);
	PSM_AddDynamicDetourFromConf("DoTeleporterOverride", DHookCallback_DoTeleporterOverride_Pre);
	PSM_AddDynamicDetourFromConf("OnBotTeleported", DHookCallback_OnBotTeleported_Pre);
	
	g_hDHook_CBaseEntity_SetModel = PSM_AddDynamicHookFromConf("CBaseEntity::SetModel");
	g_hDHook_CBaseEntity_FVisible = PSM_AddDynamicHookFromConf("CBaseEntity::FVisible");
	g_hDHook_CBaseObject_IsPlacementPosValid = PSM_AddDynamicHookFromConf("CBaseObject::IsPlacementPosValid");
	g_hDHook_CBaseObject_CanBeUpgraded = PSM_AddDynamicHookFromConf("CBaseObject::CanBeUpgraded");
	g_hDHook_CItem_ComeToRest = PSM_AddDynamicHookFromConf("CItem::ComeToRest");
	g_hDHook_CBaseEntity_ShouldTransmit = PSM_AddDynamicHookFromConf("CBaseEntity::ShouldTransmit");
	g_hDHook_CBaseCombatCharacter_ShouldGib = PSM_AddDynamicHookFromConf("CBaseCombatCharacter::ShouldGib");
	g_hDHook_CTFPlayer_IsAllowedToPickUpFlag = PSM_AddDynamicHookFromConf("CTFPlayer::IsAllowedToPickUpFlag");
	g_hDHook_CBasePlayer_EntSelectSpawnPoint = PSM_AddDynamicHookFromConf("CBasePlayer::EntSelectSpawnPoint");
	g_hDHook_CBaseFilter_PassesFilterImpl = PSM_AddDynamicHookFromConf("CBaseFilter::PassesFilterImpl");
	g_hDHook_CTFItem_PickUp = PSM_AddDynamicHookFromConf("CTFItem::PickUp");
	g_hDHook_CTeamplayRoundBasedRules_RespawnPlayers = PSM_AddDynamicHookFromConf("CTeamplayRoundBasedRules::RespawnPlayers");
}

void DHooks_VScriptInit()
{
	DHooks_CopyScriptFunctionBinding("CTFBot", "AddBotAttribute", "CTFPlayer", DHookCallback_CTFBot_ScriptAddBotAttribute_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "AddBotTag", "CTFPlayer", DHookCallback_CTFBot_ScriptAddBotTag_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "AddWeaponRestriction", "CTFPlayer", DHookCallback_CTFBot_ScriptAddWeaponRestriction_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "ClearAllBotAttributes", "CTFPlayer", DHookCallback_CTFBot_ScriptClearAllBotAttributes_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "ClearAllBotTags", "CTFPlayer", DHookCallback_CTFBot_ScriptClearAllBotTags_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "ClearAllWeaponRestrictions", "CTFPlayer", DHookCallback_CTFBot_ScriptClearAllWeaponRestrictions_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "DelayedThreatNotice", "CTFPlayer", DHookCallback_CTFBot_DelayedThreatNotices_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "DisbandCurrentSquad", "CTFPlayer", DHookCallback_CTFBot_ScriptDisbandCurrentSquad_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "GenerateAndWearItem", "CTFPlayer", .bEmpty = false);
	DHooks_CopyScriptFunctionBinding("CTFBot", "GetAllBotTags", "CTFPlayer", DHookCallback_CTFBot_ScriptGetAllBotTags_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "GetDifficulty", "CTFPlayer", DHookCallback_CTFBot_ScriptGetDifficulty_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "GetMission", "CTFPlayer", DHookCallback_CTFBot_ScriptGetMission_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "GetMissionTarget", "CTFPlayer", DHookCallback_CTFBot_ScriptGetMissionTarget_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "GetPrevMission", "CTFPlayer", DHookCallback_CTFBot_ScriptGetPrevMission_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "HasBotAttribute", "CTFPlayer", DHookCallback_CTFBot_ScriptHasBotAttribute_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "HasBotTag", "CTFPlayer", DHookCallback_CTFBot_ScriptHasBotTag_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "HasWeaponRestriction", "CTFPlayer", DHookCallback_CTFBot_ScriptHasWeaponRestriction_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "IsDifficulty", "CTFPlayer", DHookCallback_CTFBot_ScriptIsDifficulty_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "IsInASquad", "CTFPlayer", DHookCallback_CTFBot_ScriptIsInASquad_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "IsOnAnyMission", "CTFPlayer", DHookCallback_CTFBot_ScriptIsOnAnyMission_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "IsWeaponRestricted", "CTFPlayer", DHookCallback_CTFBot_ScriptIsWeaponRestricted_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "LeaveSquad", "CTFPlayer", DHookCallback_CTFBot_ScriptLeaveSquad_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "PressAltFireButton", "CTFPlayer", DHookCallback_CTFBot_ScriptPressAltFireButton_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "PressFireButton", "CTFPlayer", DHookCallback_CTFBot_ScriptPressFireButton_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "PressSpecialFireButton", "CTFPlayer", DHookCallback_CTFBot_ScriptPressSpecialFireButton_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "RemoveBotAttribute", "CTFPlayer", DHookCallback_CTFBot_ScriptRemoveBotAttribute_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "RemoveBotTag", "CTFPlayer", DHookCallback_CTFBot_ScriptRemoveBotTag_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "RemoveWeaponRestriction", "CTFPlayer", DHookCallback_CTFBot_ScriptRemoveWeaponRestriction_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "SetDifficulty", "CTFPlayer", DHookCallback_CTFBot_ScriptSetDifficulty_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "SetMission", "CTFPlayer", DHookCallback_CTFBot_ScriptSetMission_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "SetMissionTarget", "CTFPlayer", DHookCallback_CTFBot_ScriptSetMissionTarget_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "SetPrevMission", "CTFPlayer", DHookCallback_CTFBot_ScriptSetPrevMission_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "SetScaleOverride", "CTFPlayer", DHookCallback_CTFBot_ScriptSetScaleOverride_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "ShouldAutoJump", "CTFPlayer", DHookCallback_CTFBot_ScriptShouldAutoJump_Pre);
	DHooks_CopyScriptFunctionBinding("CTFBot", "UpdateDelayedThreatNotices", "CTFPlayer", DHookCallback_CTFBot_ScriptUpdateDelayedThreatNotices_Pre);
	
	DHooks_CreateScriptDetour("CTFPlayer", "IsBotOfType", DHookCallback_CTFPlayer_ScriptIsBotOfType_Pre);
	DHooks_CreateScriptDetour(NULL_STRING, "IsPlayerABot", DHookCallback_IsPlayerABot_Pre);
}

void DHooks_OnMapStart()
{
	m_cooldownTimer.Invalidate();
	m_checkForDangerousSentriesTimer.Invalidate();
	
	if (g_hDHook_CTeamplayRoundBasedRules_RespawnPlayers)
		PSM_DHookGameRules(g_hDHook_CTeamplayRoundBasedRules_RespawnPlayers, Hook_Pre, DHookCallback_CTFGameRules_RespawnPlayers_Pre);
}

void DHooks_OnEntityCreated(int entity, const char[] classname)
{
	if (IsEntityClient(entity))
	{
		if (g_hDHook_CBaseEntity_SetModel)
			PSM_DHookEntity(g_hDHook_CBaseEntity_SetModel, Hook_Post, entity, DHookCallback_CBaseEntity_SetModel_Post);
		
		if (g_hDHook_CBaseEntity_ShouldTransmit)
			PSM_DHookEntity(g_hDHook_CBaseEntity_ShouldTransmit, Hook_Pre, entity, DHookCallback_CTFPlayer_ShouldTransmit_Pre);
		
		if (g_hDHook_CBaseCombatCharacter_ShouldGib)
			PSM_DHookEntity(g_hDHook_CBaseCombatCharacter_ShouldGib, Hook_Pre, entity, DHookCallback_CTFPlayer_ShouldGib_Pre);
		
		if (g_hDHook_CTFPlayer_IsAllowedToPickUpFlag)
			PSM_DHookEntity(g_hDHook_CTFPlayer_IsAllowedToPickUpFlag, Hook_Post, entity, DHookCallback_CTFPlayer_IsAllowedToPickUpFlag_Post);
		
		if (g_hDHook_CBasePlayer_EntSelectSpawnPoint)
			PSM_DHookEntity(g_hDHook_CBasePlayer_EntSelectSpawnPoint, Hook_Pre, entity, DHookCallback_CTFPlayer_EntSelectSpawnPoint_Pre);
	}
	else if (StrEqual(classname, "filter_tf_bot_has_tag"))
	{
		if (g_hDHook_CBaseFilter_PassesFilterImpl)
			PSM_DHookEntity(g_hDHook_CBaseFilter_PassesFilterImpl, Hook_Pre, entity, DHookCallback_CFilterTFBotHasTag_PassesFilterImpl_Pre);
	}
	else if (StrEqual(classname, "item_teamflag"))
	{
		if (g_hDHook_CTFItem_PickUp)
		{
			PSM_DHookEntity(g_hDHook_CTFItem_PickUp, Hook_Pre, entity, DHookCallback_CCaptureFlag_PickUp_Pre);
			PSM_DHookEntity(g_hDHook_CTFItem_PickUp, Hook_Post, entity, DHookCallback_CCaptureFlag_PickUp_Post);
		}
	}
	else if (StrEqual(classname, "obj_teleporter"))
	{
		if (g_hDHook_CBaseObject_CanBeUpgraded)
			PSM_DHookEntity(g_hDHook_CBaseObject_CanBeUpgraded, Hook_Pre, entity, DHookCallback_CObjectTeleporter_CanBeUpgraded_Pre);
		
		if (g_hDHook_CBaseObject_IsPlacementPosValid)
			PSM_DHookEntity(g_hDHook_CBaseObject_IsPlacementPosValid, Hook_Post, entity, DHookCallback_CObjectTeleporter_IsPlacementPosValid_Post);
	}
	else if (strncmp(classname, "item_currencypack_", 18) == 0)
	{
		if (g_hDHook_CItem_ComeToRest)
			PSM_DHookEntity(g_hDHook_CItem_ComeToRest, Hook_Pre, entity, DHookCallback_CCurrencyPack_ComeToRest_Pre);
	}
	else if (StrEqual(classname, "obj_sentrygun"))
	{
		if (g_hDHook_CBaseEntity_SetModel)
			PSM_DHookEntity(g_hDHook_CBaseEntity_SetModel, Hook_Post, entity, DHookCallback_CBaseEntity_SetModel_Post);
	}
	else if (HasEntProp(entity, Prop_Data, "CBaseCombatWeaponDefaultTouch"))
	{
		if (g_hDHook_CBaseEntity_FVisible)
			PSM_DHookEntity(g_hDHook_CBaseEntity_FVisible, Hook_Pre, entity, DHookCallback_CBaseCombatWeapon_FVisible_Pre);
	}
}

static void DHooks_CopyScriptFunctionBinding(const char[] sourceClassName, const char[] functionName, const char[] targetClassName, DHookCallback callbackPre = INVALID_FUNCTION, DHookCallback callbackPost = INVALID_FUNCTION, bool bEmpty = true)
{
	VScriptFunction pTargetFunc = VScript_GetClassFunction(targetClassName, functionName);
	if (!pTargetFunc)
	{
		VScriptFunction pSourceFunc = VScript_GetClassFunction(sourceClassName, functionName);
		VScriptClass pTargetClass = VScript_GetClass(targetClassName);
		
		pTargetFunc = pTargetClass.CreateFunction();
		pTargetFunc.CopyFrom(pSourceFunc);
		
		if (bEmpty)
			pTargetFunc.SetFunctionEmpty();
	}
	
	char targetName[64];
	Format(targetName, sizeof(targetName), "%s::%s", targetClassName, functionName);
	
#if defined DEBUG
	LogMessage("Copied script function binding: %s::%s -> %s", sourceClassName, functionName, targetName);
#endif
	
	// not setup for detour
	if (callbackPre == INVALID_FUNCTION && callbackPost == INVALID_FUNCTION)
		return;
	
	DynamicDetour detour = pTargetFunc.CreateDetour();
	
	if (detour)
	{
		PSM_AddDynamicDetour(targetName, detour, callbackPre, callbackPost);
	}
	else
	{
		LogError("Failed to create script detour: %s", targetName);
	}
}

static void DHooks_CreateScriptDetour(const char[] szClassName, const char[] functionName, DHookCallback callbackPre = INVALID_FUNCTION, DHookCallback callbackPost = INVALID_FUNCTION)
{
	DynamicDetour detour;
	char name[64];
	
	if (szClassName[0])
	{
		detour = VScript_GetClassFunction(szClassName, functionName).CreateDetour();
		Format(name, sizeof(name), "%s::%s", szClassName, functionName);
	}
	else
	{
		detour = VScript_GetGlobalFunction(functionName).CreateDetour();
		strcopy(name, sizeof(name), functionName);
	}
	
	if (detour)
	{
		PSM_AddDynamicDetour(name, detour, callbackPre, callbackPost);
	}
	else
	{
		LogError("Failed to create script detour: %s", name);
	}
}

static MRESReturn DHookCallback_CTFGCServerSystem_PreClientUpdate_Pre()
{
	// Allows us to have an MvM server with unlimited visible player slots
	g_bPrevPlayingMannVsMachine = GameRules_GetProp("m_bPlayingMannVsMachine") != 0;
	GameRules_SetProp("m_bPlayingMannVsMachine", false);
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTFGCServerSystem_PreClientUpdate_Post()
{
	// Set it back afterwards
	GameRules_SetProp("m_bPlayingMannVsMachine", g_bPrevPlayingMannVsMachine);
	
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
	for (z = 0.0; z < StepHeight; z += 4.0)
	{
		here[2] = rawHere[2] + StepHeight;
		
		if (SDKCall_IsSpaceToSpawnHere(here))
		{
			break;
		}
	}
	
	if (z >= StepHeight)
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
		if (spawner.m_class == TFClass_Engineer && spawner.m_defaultAttributes.m_attributeFlags & TELEPORT_TO_HINT && !SDKCall_CTFBotMvMEngineerHintFinder_FindHint(true, false))
		{
			if (tf_populator_debug.BoolValue)
			{
				LogMessage("CTFBotSpawner: %3.2f: *** No teleporter hint for engineer", GetGameTime());
			}
			
			ret.Value = false;
			return MRES_Supercede;
		}
	}
	
	// find dead bot we can re-use
	CTFPlayer newBot = FindNextInvader(spawner.m_defaultAttributes.m_attributeFlags & MINIBOSS);
	
	if (newBot.IsValid())
	{
		newBot.ClearAllAttributes();
		
		// remove any player attributes
		TF2Attrib_RemoveAll(newBot.index);
		
		// clear any old TeleportWhere settings 
		newBot.ClearTeleportWhere();
		
		if (g_internalSpawnPoint == INVALID_ENT_REFERENCE || EntRefToEntIndex(g_internalSpawnPoint) == -1)
		{
			g_internalSpawnPoint = EntIndexToEntRef(CreateEntityByName("populator_internal_spawn_point"));
			DispatchSpawn(g_internalSpawnPoint);
		}
		
		// set name
		char name[MAX_NAME_LENGTH];
		spawner.GetName(name, sizeof(name), "TFBot");
		newBot.SetInvaderName(name, mitm_rename_robots.BoolValue);
		
		CBaseEntity(g_internalSpawnPoint).SetAbsOrigin(here);
		CBaseEntity(g_internalSpawnPoint).SetLocalAngles(ZERO_VECTOR);
		newBot.SetSpawnPoint(g_internalSpawnPoint);
		
		TFTeam team = TFTeam_Red;
		
		if (IsMannVsMachineMode())
		{
			team = TFTeam_Invaders;
		}
		
		TF2_ChangeClientTeam(newBot.index, team);
		
		newBot.SetProp(Prop_Data, "m_bAllowInstantSpawn", true);
		FakeClientCommand(newBot.index, "joinclass %s", g_aRawPlayerClassNames[spawner.m_class]);
		
		// Set the address of CTFPlayer::m_iszClassIcon from the return value of CTFBotSpawner::GetClassIcon.
		// Simply setting the value using SetEntPropString leads to segfaults, don't do that!
		newBot.SetClassIconName(spawner.GetClassIcon());
		
		newBot.ClearEventChangeAttributes();
		for (int i = 0; i < spawner.m_eventChangeAttributes.Count(); ++i)
		{
			newBot.AddEventChangeAttributes(spawner.m_eventChangeAttributes.Get(i, GetTypeSize("EventChangeAttributes_t")));
		}
		
		newBot.SetTeleportWhere(spawner.m_teleportWhereName);
		
		if (spawner.m_defaultAttributes.m_attributeFlags & MINIBOSS)
		{
			newBot.SetProp(Prop_Send, "m_bIsMiniBoss", true);
		}
		
		if (spawner.m_defaultAttributes.m_attributeFlags & USE_BOSS_HEALTH_BAR)
		{
			newBot.SetProp(Prop_Send, "m_bUseBossHealthBar", true);
		}
		
		if (spawner.m_defaultAttributes.m_attributeFlags & AUTO_JUMP)
		{
			newBot.SetAutoJump(spawner.m_flAutoJumpMin, spawner.m_flAutoJumpMax);
		}
		
		if (spawner.m_defaultAttributes.m_attributeFlags & BULLET_IMMUNE)
		{
			TF2_AddCondition(newBot.index, TFCond_BulletImmune);
		}
		
		if (spawner.m_defaultAttributes.m_attributeFlags & BLAST_IMMUNE)
		{
			TF2_AddCondition(newBot.index, TFCond_BlastImmune);
		}
		
		if (spawner.m_defaultAttributes.m_attributeFlags & FIRE_IMMUNE)
		{
			TF2_AddCondition(newBot.index, TFCond_FireImmune);
		}
		
		if (IsMannVsMachineMode())
		{
			// initialize currency to be dropped on death to zero
			newBot.SetProp(Prop_Send, "m_nCurrency", 0);
			
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
		
		newBot.SetScaleOverride(spawner.m_scale);
		
		int nHealth = spawner.m_health;
		
		if (nHealth <= 0.0)
		{
			nHealth = TF2Util_GetEntityMaxHealth(newBot.index);
		}
		
		nHealth = RoundToFloor(float(nHealth) * g_pPopulationManager.GetHealthMultiplier(false));
		newBot.ModifyMaxHealth(nHealth);
		
		newBot.StartIdleSound();
		
		// Add our items first, they'll get replaced below by the normal MvM items if any are needed
		if (IsMannVsMachineMode() && (newBot.GetTFTeam() == TFTeam_Invaders) && mitm_romevision.BoolValue)
		{
			// Apply the Rome 2 promo items to each player. They'll be 
			// filtered out for clients that do not have Romevision.
			CMissionPopulator pMission = s_missionPopulator;
			if (pMission && pMission.m_mission == MISSION_DESTROY_SENTRIES)
			{
				newBot.AddItem("tw_sentrybuster");
			}
			else
			{
				newBot.AddItem(g_szRomePromoItems_Hat[spawner.m_class]);
				newBot.AddItem(g_szRomePromoItems_Misc[spawner.m_class]);
			}
		}
		
		EventChangeAttributes_t pEventChangeAttributes = newBot.GetEventChangeAttributes(g_pPopulationManager.GetDefaultEventChangeAttributesName());
		if (!pEventChangeAttributes)
		{
			pEventChangeAttributes = spawner.m_defaultAttributes;
		}
		newBot.OnEventChangeAttributes(pEventChangeAttributes);
		
		int flag = newBot.GetFlagToFetch();
		if (IsValidEntity(flag))
		{
			newBot.SetFlagTarget(flag);
		}
		
		if (newBot.HasAttribute(SPAWN_WITH_FULL_CHARGE))
		{
			// charge up our weapons
			
			// Medigun Ubercharge
			int weapon = GetPlayerWeaponSlot(newBot.index, TFWeaponSlot_Secondary);
			if (weapon != -1 && HasEntProp(weapon, Prop_Send, "m_flChargeLevel"))
			{
				SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", 1.0);
			}
			
			if (TF2_GetPlayerClass(newBot.index) != TFClass_Medic || newBot.HasAttribute(PROJECTILE_SHIELD))
			{
				newBot.SetPropFloat(Prop_Send, "m_flRageMeter", 100.0);
			}
		}
		
		TFClassType nClassIndex = TF2_GetPlayerClass(newBot.index);
		
		if (g_pObjectiveResource.IsValid() && g_pObjectiveResource.IsPopFileEventType(MVM_EVENT_POPFILE_HALLOWEEN))
		{
			// zombies use the original player models
			newBot.SetProp(Prop_Send, "m_nSkin", 4);
			
			char item[64];
			Format(item, sizeof(item), "Zombie %s", g_aRawPlayerClassNamesShort[nClassIndex]);
			
			newBot.AddItem(item);
		}
		else
		{
			// use the nifty new robot model
			if (nClassIndex >= TFClass_Scout && nClassIndex <= TFClass_Engineer)
			{
				if (spawner.m_scale >= tf_mvm_miniboss_scale.FloatValue || newBot.IsMiniBoss() && FileExists(g_szBotBossModels[nClassIndex], true))
				{
					SetVariantString(g_szBotBossModels[nClassIndex]);
					newBot.AcceptInput("SetCustomModelWithClassAnimations");
					newBot.SetProp(Prop_Data, "m_bloodColor", DONT_BLEED);
				}
				else if (FileExists(g_szBotModels[nClassIndex], true))
				{
					SetVariantString(g_szBotModels[nClassIndex]);
					newBot.AcceptInput("SetCustomModelWithClassAnimations");
					newBot.SetProp(Prop_Data, "m_bloodColor", DONT_BLEED);
				}
			}
		}
		
		if (params.Get(2))
		{
			CUtlVector result = CUtlVector(params.Get(2)); // EntityHandleVector_t
			result.AddToTail(GetEntityHandle(newBot.index));
		}
		
		// for easy access in populator spawner callbacks
		m_justSpawnedList.Push(newBot);
		
		if (IsMannVsMachineMode())
		{
			if (newBot.IsMiniBoss())
			{
				HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_GIANT_CALLOUT", TFTeam_Defenders);
			}
		}
		
		if (tf_populator_debug.BoolValue)
		{
			LogMessage("%3.2f: Spawned player '%L'", GetGameTime(), newBot);
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
				if (IsValidEntity(bot) && IsEntityClient(bot))
				{
					CTFPlayer(bot).JoinSquad(squad);
				}
			}
		}
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CPopulationManager_Update_Pre(int populator)
{
	// allow populators/spawners to freely switch player's teams
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
		CTFPlayer bot = m_justSpawnedList.Get(i);
		if (bot.IsValid())
		{
			// what bot should do after spawning at teleporter exit
			if (s_spawnLocationResult == SPAWN_LOCATION_TELEPORTER)
			{
				OnBotTeleported(bot.index);
			}
		}
	}
	
	// after we are done, clear the list
	m_justSpawnedList.Clear();
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CWaveSpawnPopulator_Update_Post(CWaveSpawnPopulator populator)
{
	for (int i = 0; i < m_justSpawnedList.Length; i++)
	{
		CTFPlayer bot = m_justSpawnedList.Get(i);
		if (bot.IsValid())
		{
			bot.SetCustomCurrencyWorth(0);
			bot.SetWaveSpawnPopulator(populator);
			
			// Allows client UI to know if a specific spawner is active
			g_pObjectiveResource.SetMannVsMachineWaveClassActive(bot.GetClassIconName());
			
			if (populator.IsSupportWave())
			{
				bot.MarkAsSupportEnemy();
			}
			
			if (populator.IsLimitedSupportWave())
			{
				bot.MarkAsLimitedSupportEnemy();
			}
			
			// what bot should do after spawning at teleporter exit
			if (s_spawnLocationResult == SPAWN_LOCATION_TELEPORTER)
			{
				OnBotTeleported(bot.index);
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
		CTFPlayer player = livePlayerList.Get(i);
		if (player.HasMission(mission))
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
	if (!ret.Value)
		return MRES_Ignored;
	
	MissionType mission = params.Get(1);
	
	for (int i = 0; i < m_justSpawnedList.Length; i++)
	{
		CTFPlayer bot = m_justSpawnedList.Get(i);
		if (bot.IsValid())
		{
			bot.SetFlagTarget(INVALID_ENT_REFERENCE);
			bot.SetMission(mission);
			bot.MarkAsMissionEnemy();
			
			if (g_pObjectiveResource.IsValid())
			{
				int iFlags = MVM_CLASS_FLAG_MISSION;
				if (bot.IsMiniBoss())
				{
					iFlags |= MVM_CLASS_FLAG_MINIBOSS;
				}
				else if (bot.HasAttribute(ALWAYS_CRIT))
				{
					iFlags |= MVM_CLASS_FLAG_ALWAYSCRIT;
				}
				g_pObjectiveResource.IncrementMannVsMachineWaveClassCount(bot.GetClassIconName(), iFlags);
			}
			
			// Response rules stuff for MvM
			if (IsMannVsMachineMode())
			{
				// Only have defenders announce the arrival of the first enemy Sniper
				if (bot.HasMission(MISSION_SNIPER))
				{
					s_nSniperCount++;
					
					if (s_nSniperCount == 1)
					{
						HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_SNIPER_CALLOUT", TFTeam_Defenders);
					}
				}
			}
			
			// what bot should do after spawning at teleporter exit
			if (s_spawnLocationResult == SPAWN_LOCATION_TELEPORTER)
			{
				OnBotTeleported(bot.index);
			}
		}
	}
	
	// after we are done, clear the list
	m_justSpawnedList.Clear();
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CMissionPopulator_UpdateMissionDestroySentries_Pre(CMissionPopulator populator, DHookReturn ret)
{
	s_missionPopulator = populator;
	
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
				CTFPlayer sentryOwner = CTFPlayer(GetEntPropEnt(obj, Prop_Send, "m_hBuilder"));
				if (sentryOwner.IsValid())
				{
					int nDmgDone = RoundToFloor(sentryOwner.m_accumulatedSentryGunDamageDealt);
					int nKillsMade = sentryOwner.m_accumulatedSentryGunKillCount;
					
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
			CTFPlayer bot = livePlayerList.Get(j);
			if (bot.HasMission(MISSION_DESTROY_SENTRIES) && bot.GetMissionTarget() == targetSentry)
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
					CTFPlayer bot = m_justSpawnedList.Get(k);
					if (bot.IsValid())
					{
						bot.SetFlagTarget(INVALID_ENT_REFERENCE);
						bot.SetMission(MISSION_DESTROY_SENTRIES);
						bot.SetMissionTarget(targetSentry);
						
						bot.MyNextBotPointer().Update();
						
						bot.MarkAsMissionEnemy();
						
						didSpawn = true;
						
						SetVariantString(g_szBotBossSentryBusterModel);
						bot.AcceptInput("SetCustomModelWithClassAnimations");
						bot.SetProp(Prop_Data, "m_bloodColor", DONT_BLEED);
						
						SetVariantInt(1);
						bot.AcceptInput("SetForcedTauntCam");
						
						if (g_pObjectiveResource.IsValid())
						{
							int iFlags = MVM_CLASS_FLAG_MISSION;
							if (bot.IsMiniBoss())
							{
								iFlags |= MVM_CLASS_FLAG_MINIBOSS;
							}
							if (bot.HasAttribute(ALWAYS_CRIT))
							{
								iFlags |= MVM_CLASS_FLAG_ALWAYSCRIT;
							}
							g_pObjectiveResource.IncrementMannVsMachineWaveClassCount(CTFBotSpawner(populator.m_spawner).GetClassIcon(k), iFlags);
						}
						
						HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_SENTRY_BUSTER", TFTeam_Defenders);
						
						// what bot should do after spawning at teleporter exit
						if (spawnLocationResult == SPAWN_LOCATION_TELEPORTER)
						{
							OnBotTeleported(bot.index);
						}
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
	s_missionPopulator = CMissionPopulator(Address_Null);
	
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
			EventChangeAttributes_t pEvent = CTFPlayer(botList.Get(i)).GetEventChangeAttributes(pszEventName);
			if (pEvent)
			{
				CTFPlayer(botList.Get(i)).OnEventChangeAttributes(pEvent);
			}
		}
		
		delete botList;
	}
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFGameRules_PlayerReadyStatus_UpdatePlayerState_Pre(DHookParam params)
{
	if (mitm_setup_time.IntValue <= 0)
		return MRES_Ignored;
	
	// Save off the old timer value
	g_flTempRestartRoundTime = GameRules_GetPropFloat("m_flRestartRoundTime");
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTFGameRules_PlayerReadyStatus_UpdatePlayerState_Post(DHookParam params)
{
	if (mitm_setup_time.IntValue <= 0)
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
	TFTeam nCurrentTeam = TF2_GetClientTeam(player);
	
	if (IsClientSourceTV(player))
		return MRES_Ignored;
	
	// allow this function to set each player's team and currency
	CBaseEntity(player).RemoveFlag(FL_FAKECLIENT);
	
	if (GameRules_GetRoundState() == RoundState_Pregame || IsInWaitingForPlayers())
	{
		ret.Value = TFTeam_Defenders;
		return MRES_Supercede;
	}
	else if (g_bAllowTeamChange)
	{
		ret.Value = nDesiredTeam;
		return MRES_Supercede;
	}
	else if (developer.BoolValue && !IsFakeClient(player))
	{
		if (nDesiredTeam == TFTeam_Spectator || nDesiredTeam == TFTeam_Defenders)
			return MRES_Ignored;
		
		ret.Value = nDesiredTeam;
		return MRES_Supercede;
	}
	else
	{
		// player is trying to switch from invaders to a different team
		if (!g_bAllowTeamChange && nCurrentTeam == TFTeam_Invaders && nDesiredTeam != nCurrentTeam && !mitm_bot_allow_suicide.BoolValue)
		{
			if (IsPlayerAlive(player))
				PrintCenterText(player, "%t", "Invader_NotAllowedToSuicide");
			
			ret.Value = nCurrentTeam;
			return MRES_Supercede;
		}
		
		if (nDesiredTeam == TFTeam_Defenders)
		{
			if (!CTFPlayer(player).IsValidDefender())
			{
				ret.Value = TFTeam_Spectator;
				return MRES_Supercede;
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
			if (iDefenderCount >= tf_mvm_defenders_team_size.IntValue || CTFPlayer(player).IsInAParty() && CTFPlayer(player).GetParty().GetMemberCount() > 1)
			{
				ret.Value = TFTeam_Spectator;
				return MRES_Supercede;
			}
		}
		
		return MRES_Ignored;
	}
}

static MRESReturn DHookCallback_CTFGameRules_GetTeamAssignmentOverride_Post(DHookReturn ret, DHookParam params)
{
	if (ret.Value == TFTeam_Invaders)
	{
		// Mark all invaders as bots.
		// This will allow IsBot() to return true, but IsFakeClient() will still be false!
		int player = params.Get(1);
		CBaseEntity(player).AddFlag(FL_FAKECLIENT);
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
		
		if (CTFPlayer(player).HasAttribute(AIR_CHARGE_ONLY) && (GetEntPropEnt(player, Prop_Send, "m_hGroundEntity") != -1 || velocity[2] > 0.0))
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
	return CTFPlayer(player).HasAttribute(RETAIN_BUILDINGS) ? MRES_Supercede : MRES_Ignored;
}

static MRESReturn DHookCallback_CTFPlayer_CanBuild_Pre(int player, DHookReturn ret, DHookParam params)
{
	if (TF2_GetClientTeam(player) == TFTeam_Invaders && TF2_GetPlayerClass(player) == TFClass_Engineer)
	{
		// prevent invaders from building multiple sentries
		CBaseEntity(player).RemoveFlag(FL_FAKECLIENT);
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTFPlayer_CanBuild_Post(int player, DHookReturn ret, DHookParam params)
{
	if (TF2_GetClientTeam(player) == TFTeam_Invaders && TF2_GetPlayerClass(player) == TFClass_Engineer)
	{
		CBaseEntity(player).AddFlag(FL_FAKECLIENT);
		
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

static MRESReturn DHookCallback_CTFPlayer_ForceChangeTeam_Pre(int player, DHookParam params)
{
	// If it's forced, there is probably a good reason
	g_bAllowTeamChange = true;
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTFPlayer_ForceChangeTeam_Post(int player, DHookParam params)
{
	g_bAllowTeamChange = false;
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CWeaponMedigun_AllowedToHealTarget_Pre(int medigun, DHookReturn ret, DHookParam params)
{
	int target = params.Get(1);
	int owner = GetEntPropEnt(medigun, Prop_Send, "m_hOwnerEntity");
	
	if (TF2_GetClientTeam(owner) == TFTeam_Invaders)
	{
		// medics in a squad should only ever heal their squad leader
		if (CTFPlayer(owner).IsInASquad() && CTFPlayer(owner).GetSquad().GetLeader() != -1)
		{
			CTFBotSquad squad = CTFPlayer(owner).GetSquad();
			if (squad.IsLeader(owner) || squad.IsLeader(target))
			{
				// allow healing the squad leader, or everyone if we are the leader
				return MRES_Ignored;
			}
			
			PrintCenterText(owner, "%t", "Squad_NotAllowedToHeal", squad.GetLeader());
			
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

static MRESReturn DHookCallback_CTraceFilterObject_ShouldHitEntity_Pre(Address pFilter, DHookReturn ret, DHookParam params)
{
	int me = GetEntityFromAddress(LoadFromAddress(pFilter + GetOffset("CTraceFilterSimple", "m_pPassEnt"), NumberType_Int32));
	int entity = GetEntityFromAddress(params.Get(1));
	
	if (IsEntityClient(entity))
	{
		if (IsMannVsMachineMode())
		{
			if (CTFPlayer(entity).HasMission(MISSION_DESTROY_SENTRIES) || CTFPlayer(entity).HasMission(MISSION_REPROGRAMMED))
			{
				// Don't collide with sentry busters since they don't collide with us
				ret.Value = false;
				return MRES_Supercede;
			}
			
			if (CTFPlayer(me).HasMission(MISSION_DESTROY_SENTRIES) || CTFPlayer(me).HasMission(MISSION_REPROGRAMMED))
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
		// re-enable lag compensation for invaders
		CBaseEntity(player).RemoveFlag(FL_FAKECLIENT);
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CLagCompensationManager_StartLagCompensation_Post(DHookParam params)
{
	int player = params.Get(1);
	
	if (TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		CBaseEntity(player).AddFlag(FL_FAKECLIENT);
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CUniformRandomStream_SetSeed_Pre(DHookParam params)
{
	if (g_bInEndlessRollEscalation)
	{
		params.Set(1, g_iEndlessRandomSeed);
		return MRES_ChangedHandled;
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_DoTeleporterOverride_Pre(DHookReturn ret, DHookParam params)
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
		
		ArrayList teleportWhere = Entity(obj).GetTeleportWhere();
		for (int iTelePoints = 0; iTelePoints < teleportWhere.Length; ++iTelePoints)
		{
			char teleportWhereName[64];
			teleportWhere.GetString(iTelePoints, teleportWhereName, sizeof(teleportWhereName));
			
			if (StrEqual(teleportWhereName, szSpawnPointName, false))
			{
				teleporterList.Push(obj);
				break;
			}
		}
		delete teleportWhere;
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
	
	delete teleporterList;
	
	float spawnEntCenter[3];
	spawnEnt.WorldSpaceCenter(spawnEntCenter);
	
	CNavArea nav = TheNavMesh.GetNearestNavArea(spawnEntCenter);
	if (!nav)
	{
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
	
	params.SetVector(2, vSpawnPosition);
	ret.Value = SPAWN_LOCATION_NAV;
	return MRES_Supercede;
}

static MRESReturn DHookCallback_OnBotTeleported_Pre(DHookParam params)
{
	// This crashes our server in local testing due to s_lastTeleporter being null
	return MRES_Supercede;
}

static void OnBotTeleported(int bot)
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
	if (CTFPlayer(player).HasAttribute(USE_BOSS_HEALTH_BAR))
	{
		ret.Value = FL_EDICT_ALWAYS;
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTFPlayer_ShouldGib_Pre(int player, DHookReturn ret, DHookParam params)
{
	// only gib giant/miniboss
	if (IsMannVsMachineMode() && (CTFPlayer(player).IsMiniBoss() || GetEntPropFloat(player, Prop_Send, "m_flModelScale") > 1.0))
	{
		ret.Value = true;
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTFPlayer_IsAllowedToPickUpFlag_Post(int player, DHookReturn ret)
{
	if (!ret.Value)
	{
		return MRES_Ignored;
	}
	
	// only the leader of a squad can pick up the flag
	if (CTFPlayer(player).IsInASquad() && !CTFPlayer(player).GetSquad().IsLeader(player))
	{
		PrintCenterText(player, "%t", "Squad_NotAllowedToPickUpFlag", CTFPlayer(player).GetSquad().GetLeader());
		
		ret.Value = false;
		return MRES_Supercede;
	}
	
	// mission bots can't pick up the flag
	ret.Value = !CTFPlayer(player).IsOnAnyMission();
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFPlayer_EntSelectSpawnPoint_Pre(int player, DHookReturn ret)
{
	if (TF2_GetClientTeam(player) != TFTeam_Invaders)
		return MRES_Ignored;
	
	// override normal spawn behavior to spawn robots at the right place
	if (IsValidEntity(CTFPlayer(player).m_spawnPointEntity))
	{
		ret.Value = CTFPlayer(player).m_spawnPointEntity;
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
			if (CTFPlayer(entity).HasTag(tags[i]))
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
	CTFPlayer player = CTFPlayer(params.Get(1));
	
	if (IsMannVsMachineMode() && player.GetTFTeam() == TFTeam_Invaders)
	{
		// do not trip up the assert_cast< CTFBot* >
		player.RemoveFlag(FL_FAKECLIENT);
		
		if (player.HasAttribute(IGNORE_FLAG))
			return MRES_Supercede;
		
		player.SetFlagTarget(EntIndexToEntRef(item));
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CCaptureFlag_PickUp_Post(int item, DHookParam params)
{
	CTFPlayer player = CTFPlayer(params.Get(1));
	
	if (IsMannVsMachineMode() && player.GetTFTeam() == TFTeam_Invaders)
	{
		player.AddFlag(FL_FAKECLIENT);
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CTFGameRules_RespawnPlayers_Pre(DHookParam params)
{
	bool bTeam = params.Get(2);
	TFTeam team = params.Get(3);
	
	// do not allow blue team to naturally respawn
	return bTeam && team == TFTeam_Invaders ? MRES_Supercede : MRES_Ignored;
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

static MRESReturn DHookCallback_CBaseCombatWeapon_FVisible_Pre(int weapon, DHookReturn ret, DHookParam params)
{
	int entity = params.Get(1);
	
	// Fixes players rarely spawning without weapons
	if (IsEntityClient(entity))
	{
		ret.Value = true;
		return MRES_Supercede;
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

static MRESReturn DHookCallback_CTFBot_ScriptAddBotAttribute_Pre(int bot, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	CTFPlayer(bot).SetAttribute(params.Get(1));
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptAddBotTag_Pre(int bot, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	char tag[64];
	params.GetString(1, tag, sizeof(tag));
	
	CTFPlayer(bot).AddTag(tag);
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptAddWeaponRestriction_Pre(int bot, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	CTFPlayer(bot).SetWeaponRestriction(params.Get(1));
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptClearAllBotAttributes_Pre(int bot)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	CTFPlayer(bot).ClearAllAttributes();
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptClearAllBotTags_Pre(int bot)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	CTFPlayer(bot).ClearTags();
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptClearAllWeaponRestrictions_Pre(int bot)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	CTFPlayer(bot).ClearWeaponRestrictions();
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_DelayedThreatNotices_Pre(int bot, DHookParam params)
{
	int who = VScript_HScriptToEntity(params.Get(1));
	float flNoticeDelay = params.Get(2);
	
	CTFPlayer(bot).DelayedThreatNotice(who, flNoticeDelay);
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptDisbandCurrentSquad_Pre(int bot)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	CTFBotSquad squad = CTFPlayer(bot).GetSquad();
	if (squad)
	{
		squad.DisbandAndDeleteSquad();
	}
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptGetAllBotTags_Pre(int bot, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	HSCRIPT table = params.Get(1);
	
	ArrayList tags = CTFPlayer(bot).GetAllBotTags();
	for (int i = 0; i < tags.Length; ++i)
	{
		char key[16], value[64];
		if (IntToString(i, key, sizeof(key)) && tags.GetString(i, value, sizeof(value)))
		{
			table.SetValueString(key, FIELD_CSTRING, value);
		}
	}
	delete tags;
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptGetDifficulty_Pre(int bot, DHookReturn ret)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	ret.Value = CTFPlayer(bot).GetDifficulty();
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptGetMission_Pre(int bot, DHookReturn ret)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	ret.Value = CTFPlayer(bot).GetMission();
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptGetMissionTarget_Pre(int bot, DHookReturn ret)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	int target = CTFPlayer(bot).GetMissionTarget();
	
	ret.Value = IsValidEntity(target) ? VScript_EntityToHScript(target) : view_as<HSCRIPT>(0);
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptGetPrevMission_Pre(int bot, DHookReturn ret)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	ret.Value = CTFPlayer(bot).GetPrevMission();
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptHasBotAttribute_Pre(int bot, DHookReturn ret, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	ret.Value = CTFPlayer(bot).HasAttribute(params.Get(1));
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptHasBotTag_Pre(int bot, DHookReturn ret, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	char tag[64];
	params.GetString(1, tag, sizeof(tag));
	
	ret.Value = CTFPlayer(bot).HasTag(tag);
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptHasWeaponRestriction_Pre(int bot, DHookReturn ret, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	ret.Value = CTFPlayer(bot).HasWeaponRestriction(params.Get(1));
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptIsDifficulty_Pre(int bot, DHookReturn ret, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	ret.Value = CTFPlayer(bot).IsDifficulty(params.Get(1));
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptIsInASquad_Pre(int bot, DHookReturn ret)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	ret.Value = CTFPlayer(bot).IsInASquad();
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptIsOnAnyMission_Pre(int bot, DHookReturn ret)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	ret.Value = CTFPlayer(bot).IsOnAnyMission();
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptIsWeaponRestricted_Pre(int bot, DHookReturn ret, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	int weapon = VScript_HScriptToEntity(params.Get(1));
	
	ret.Value = CTFPlayer(bot).IsWeaponRestricted(weapon);
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptLeaveSquad_Pre(int bot)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	CTFPlayer(bot).LeaveSquad();
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptPressAltFireButton_Pre(int bot, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	CTFPlayer(bot).PressAltFireButton(params.Get(1));
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptPressFireButton_Pre(int bot, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	CTFPlayer(bot).PressFireButton(params.Get(1));
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptPressSpecialFireButton_Pre(int bot, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	CTFPlayer(bot).PressSpecialFireButton(params.Get(1));
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptRemoveBotAttribute_Pre(int bot, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	CTFPlayer(bot).ClearAttribute(params.Get(1));
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptRemoveBotTag_Pre(int bot, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	char tag[64];
	params.GetString(1, tag, sizeof(tag));
	
	CTFPlayer(bot).RemoveTag(tag);
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptRemoveWeaponRestriction_Pre(int bot, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	CTFPlayer(bot).RemoveWeaponRestriction(params.Get(1));
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptSetDifficulty_Pre(int bot, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	CTFPlayer(bot).SetDifficulty(params.Get(1));
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptSetMission_Pre(int bot, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	CTFPlayer(bot).SetMission(params.Get(1));
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptSetMissionTarget_Pre(int bot, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	int target = VScript_HScriptToEntity(params.Get(1));
	
	CTFPlayer(bot).SetMissionTarget(target);
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptSetPrevMission_Pre(int bot, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	CTFPlayer(bot).SetPrevMission(params.Get(1));
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptSetScaleOverride_Pre(int bot, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	CTFPlayer(bot).SetScaleOverride(params.Get(1));
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptShouldAutoJump_Pre(int bot, DHookParam params)
{
	if (IsFakeClient(bot))
		return MRES_Ignored;
	
	CTFPlayer(bot).ShouldAutoJump();
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFBot_ScriptUpdateDelayedThreatNotices_Pre(int bot)
{
	CTFPlayer(bot).UpdateDelayedThreatNotices();
	
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CTFPlayer_ScriptIsBotOfType_Pre(int player, DHookReturn ret, DHookParam params)
{
	int botType = params.Get(1);
	
	// make scripts believe that all invaders are TFBots
	if (botType == TF_BOT_TYPE && CTFPlayer(player).IsInvader())
	{
		ret.Value = true;
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_IsPlayerABot_Pre(DHookReturn ret, DHookParam params)
{
	int player = VScript_HScriptToEntity(params.Get(1));
	
	if (IsValidEntity(player) && CTFPlayer(player).IsInvader())
	{
		ret.Value = true;
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}
