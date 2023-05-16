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

static Handle g_hSDKCallGetClassIconLinux;
static Handle g_hSDKCallGetClassIconWindows;
static Handle g_hSDKCall_CTeamplayRoundBasedRules_PlayThrottledAlert;
static Handle g_hSDKCall_CTFPlayer_PostInventoryApplication;
static Handle g_hSDKCall_CEconEntity_UpdateModelToClass;
static Handle g_hSDKCall_CTFItem_PickUp;
static Handle g_hSDKCall_CCaptureZone_Capture;
static Handle g_hSDKCall_CTFPlayer_DoAnimationEvent;
static Handle g_hSDKCall_CTFPlayer_PlaySpecificSequence;
static Handle g_hSDKCall_CTFPlayer_DoClassSpecialSkill;
static Handle g_hSDKCall_CTFPlayerShared_ResetRageBuffs;
static Handle g_hSDKCall_CPopulationManager_IsInEndlessWaves;
static Handle g_hSDKCall_CPopulationManager_GetHealthMultiplier;
static Handle g_hSDKCall_CPopulationManager_ResetMap;
static Handle g_hSDKCall_IsSpaceToSpawnHere;
static Handle g_hSDKCall_CTFPlayer_RemoveObject;
static Handle g_hSDKCall_CTFBotMvMEngineerHintFinder_FindHint;
static Handle g_hSDKCall_CTFGameRules_PushAllPlayersAway;
static Handle g_hSDKCall_CTFGameRules_DistributeCurrencyAmount;
static Handle g_hSDKCall_CGameRules_ShouldCollide;
static Handle g_hSDKCall_CTeamplayRules_TeamMayCapturePoint;
static Handle g_hSDKCall_CTFBotHintEngineerNest_GetSentryHint;
static Handle g_hSDKCall_CTFBotHintEngineerNest_GetTeleporterHint;
static Handle g_hSDKCall_CPopulationManager_GetCurrentWave;
static Handle g_hSDKCall_CBaseEntity_IsCombatItem;
static Handle g_hSDKCall_CBaseObject_GetMaxHealthForCurrentLevel;
static Handle g_hSDKCall_CBaseCombatWeapon_Clip1;
static Handle g_hSDKCall_CSpawnLocation_FindSpawnLocation;
static Handle g_hSDKCall_CPopulationManager_GetSentryBusterDamageAndKillThreshold;
static Handle g_hSDKCall_IPopulationSpawner_Spawn;
static Handle g_hSDKCall_GetBombInfo;
static Handle g_hSDKCall_CTFBotHintEngineerNest_IsStaleNest;
static Handle g_hSDKCall_CTFBotHintEngineerNest_DetonateStaleNest;
static Handle g_hSDKCall_CTFGrenadePipebombProjectile_GetLiveTime;
static Handle g_hSDKCall_CBaseTrigger_PassesTriggerFilters;
static Handle g_hSDKCall_CBaseEntity_ShouldCollide;

void SDKCalls_Init(GameData hGameData)
{
	char platform[64];
	if (hGameData.GetKeyValue("Platform", platform, sizeof(platform)))
	{
		if (StrEqual(platform, "linux"))
		{
			g_hSDKCallGetClassIconLinux = PrepSDKCall_GetClassIcon_Linux(hGameData);
		}
		else if (StrEqual(platform, "windows"))
		{
			g_hSDKCallGetClassIconWindows = PrepSDKCall_GetClassIcon_Windows(hGameData);
		}
		else
		{
			ThrowError("Unknown or unsupported platform '%s'", platform);
		}
	}
	else
	{
		ThrowError("Could not find 'Platform' key in gamedata");
	}
	
	g_hSDKCall_CTeamplayRoundBasedRules_PlayThrottledAlert = PrepSDKCall_CTeamplayRoundBasedRules_PlayThrottledAlert(hGameData);
	g_hSDKCall_CTFPlayer_PostInventoryApplication = PrepSDKCall_CTFPlayer_PostInventoryApplication(hGameData);
	g_hSDKCall_CEconEntity_UpdateModelToClass = PrepSDKCall_CEconEntity_UpdateModelToClass(hGameData);
	g_hSDKCall_CTFItem_PickUp = PrepSDKCall_CTFItem_PickUp(hGameData);
	g_hSDKCall_CCaptureZone_Capture = PrepSDKCall_CCaptureZone_Capture(hGameData);
	g_hSDKCall_CTFPlayer_DoAnimationEvent = PrepSDKCall_CTFPlayer_DoAnimationEvent(hGameData);
	g_hSDKCall_CTFPlayer_PlaySpecificSequence = PrepSDKCall_CTFPlayer_PlaySpecificSequence(hGameData);
	g_hSDKCall_CTFPlayer_DoClassSpecialSkill = PrepSDKCall_CTFPlayer_DoClassSpecialSkill(hGameData);
	g_hSDKCall_CTFPlayerShared_ResetRageBuffs = PrepSDKCall_CTFPlayerShared_ResetRageBuffs(hGameData);
	g_hSDKCall_CPopulationManager_IsInEndlessWaves = PrepSDKCall_CPopulationManager_IsInEndlessWaves(hGameData);
	g_hSDKCall_CPopulationManager_GetHealthMultiplier = PrepSDKCall_CPopulationManager_GetHealthMultiplier(hGameData);
	g_hSDKCall_CPopulationManager_ResetMap = PrepSDKCall_CPopulationManager_ResetMap(hGameData);
	g_hSDKCall_IsSpaceToSpawnHere = PrepSDKCall_IsSpaceToSpawnHere(hGameData);
	g_hSDKCall_CTFPlayer_RemoveObject = PrepSDKCall_CTFPlayer_RemoveObject(hGameData);
	g_hSDKCall_CTFBotMvMEngineerHintFinder_FindHint = PrepSDKCall_CTFBotMvMEngineerHintFinder_FindHint(hGameData);
	g_hSDKCall_CTFGameRules_PushAllPlayersAway = PrepSDKCall_CTFGameRules_PushAllPlayersAway(hGameData);
	g_hSDKCall_CGameRules_ShouldCollide = PrepSDKCall_CGameRules_ShouldCollide(hGameData);
	g_hSDKCall_CTFGameRules_DistributeCurrencyAmount = PrepSDKCall_CTFGameRules_DistributeCurrencyAmount(hGameData);
	g_hSDKCall_CTeamplayRules_TeamMayCapturePoint = PrepSDKCall_CTeamplayRules_TeamMayCapturePoint(hGameData);
	g_hSDKCall_CTFBotHintEngineerNest_GetSentryHint = PrepSDKCall_CTFBotHintEngineerNest_GetSentryHint(hGameData);
	g_hSDKCall_CTFBotHintEngineerNest_GetTeleporterHint = PrepSDKCall_CTFBotHintEngineerNest_GetTeleporterHint(hGameData);
	g_hSDKCall_CPopulationManager_GetCurrentWave = PrepSDKCall_CPopulationManager_GetCurrentWave(hGameData);
	g_hSDKCall_CBaseEntity_IsCombatItem = PrepSDKCall_CBaseEntity_IsCombatItem(hGameData);
	g_hSDKCall_CBaseObject_GetMaxHealthForCurrentLevel = PrepSDKCall_CBaseObject_GetMaxHealthForCurrentLevel(hGameData);
	g_hSDKCall_CBaseCombatWeapon_Clip1 = PrepSDKCall_CBaseCombatWeapon_Clip1(hGameData);
	g_hSDKCall_CSpawnLocation_FindSpawnLocation = PrepSDKCall_CSpawnLocation_FindSpawnLocation(hGameData);
	g_hSDKCall_CPopulationManager_GetSentryBusterDamageAndKillThreshold = PrepPrepSDKCall_CPopulationManager_GetSentryBusterDamageAndKillThreshold(hGameData);
	g_hSDKCall_IPopulationSpawner_Spawn = PrepSDKCall_IPopulationSpawner_Spawn(hGameData);
	g_hSDKCall_GetBombInfo = PrepSDKCall_GetBombInfo(hGameData);
	g_hSDKCall_CTFBotHintEngineerNest_IsStaleNest = PrepSDKCall_CTFBotHintEngineerNest_IsStaleNest(hGameData);
	g_hSDKCall_CTFBotHintEngineerNest_DetonateStaleNest = PrepSDKCall_CTFBotHintEngineerNest_DetonateStaleNest(hGameData);
	g_hSDKCall_CTFGrenadePipebombProjectile_GetLiveTime = PrepSDKCall_CTFGrenadePipebombProjectile_GetLiveTime(hGameData);
	g_hSDKCall_CBaseTrigger_PassesTriggerFilters = PrepSDKCall_CBaseTrigger_PassesTriggerFilters(hGameData);
	g_hSDKCall_CBaseEntity_ShouldCollide = PrepSDKCall_CBaseEntity_ShouldCollide(hGameData);
}

static Handle PrepSDKCall_GetClassIcon_Linux(GameData hGameData)
{
	// linux signature. this uses a hidden pointer passed in before `this` on the stack
	// so we'll do our best with static since SM doesn't support that calling convention
	// no subclasses override this virtual function so we'll just call it directly
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFBotSpawner::GetClassIcon");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer); // return value
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // thisptr
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // int nSpawnNum
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain); // return string_t
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFBotSpawner::GetClassIcon");
	
	return call;
}

static Handle PrepSDKCall_GetClassIcon_Windows(GameData hGameData)
{
	// windows vcall. this one also uses a hidden pointer, but it's passed as the first param
	// `this` remains unchanged so we can still use a vcall
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTFBotSpawner::GetClassIcon");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer); // return value
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // int nSpawnNum
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain); // return string_t
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFBotSpawner::GetClassIcon");
	
	return call;
}

static Handle PrepSDKCall_CTeamplayRoundBasedRules_PlayThrottledAlert(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTeamplayRoundBasedRules::PlayThrottledAlert");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_ByValue);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTeamplayRoundBasedRules::PlayThrottledAlert");
	
	return call;
}

static Handle PrepSDKCall_CTFPlayer_PostInventoryApplication(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayer::PostInventoryApplication");
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFPlayer::PostInventoryApplication");
	
	return call;
}

static Handle PrepSDKCall_CEconEntity_UpdateModelToClass(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CEconEntity::UpdateModelToClass");
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CEconEntity::UpdateModelToClass");
	
	return call;
}

static Handle PrepSDKCall_CTFItem_PickUp(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTFItem::PickUp");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFItem::PickUp");
	
	return call;
}

static Handle PrepSDKCall_CCaptureZone_Capture(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CCaptureZone::Capture");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CCaptureZone::Capture");
	
	return call;
}

static Handle PrepSDKCall_CTFPlayer_DoAnimationEvent(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayer::DoAnimationEvent");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFPlayer::DoAnimationEvent");
	
	return call;
}

static Handle PrepSDKCall_CTFPlayer_PlaySpecificSequence(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayer::PlaySpecificSequence");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFPlayer::PlaySpecificSequence");
	
	return call;
}

static Handle PrepSDKCall_CTFPlayer_DoClassSpecialSkill(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayer::DoClassSpecialSkill");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFPlayer::DoClassSpecialSkill");
	
	return call;
}

static Handle PrepSDKCall_CTFPlayerShared_ResetRageBuffs(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayerShared::ResetRageBuffs");
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFPlayerShared::ResetRageBuffs");
	
	return call;
}

static Handle PrepSDKCall_CPopulationManager_IsInEndlessWaves(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CPopulationManager::IsInEndlessWaves");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CPopulationManager::IsInEndlessWaves");
	
	return call;
}

static Handle PrepSDKCall_CPopulationManager_GetHealthMultiplier(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CPopulationManager::GetHealthMultiplier");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CPopulationManager::GetHealthMultiplier");
	
	return call;
}

static Handle PrepSDKCall_CPopulationManager_ResetMap(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CPopulationManager::ResetMap");
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CPopulationManager::ResetMap");
	
	return call;
}

static Handle PrepSDKCall_IsSpaceToSpawnHere(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "IsSpaceToSpawnHere");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: IsSpaceToSpawnHere");
	
	return call;
}

static Handle PrepSDKCall_CTFBotMvMEngineerHintFinder_FindHint(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFBotMvMEngineerHintFinder::FindHint");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFBotMvMEngineerHintFinder::FindHint");
	
	return call;
}

static Handle PrepSDKCall_CTFGameRules_PushAllPlayersAway(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFGameRules::PushAllPlayersAway");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFGameRules::PushAllPlayersAway");
	
	return call;
}

static Handle PrepSDKCall_CTFGameRules_DistributeCurrencyAmount(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFGameRules::DistributeCurrencyAmount");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	Handle call = EndPrepSDKCall();
	if (!call)
	{
		LogError("Failed to create SDKCall: CTFGameRules::DistributeCurrencyAmount");
	}
	
	return call;
}

static Handle PrepSDKCall_CGameRules_ShouldCollide(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CGameRules::ShouldCollide");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
	{
		LogError("Failed to create SDKCall: CGameRules::ShouldCollide");
	}
	
	return call;
}

static Handle PrepSDKCall_CTeamplayRules_TeamMayCapturePoint(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTeamplayRules::TeamMayCapturePoint");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
	{
		LogError("Failed to create SDKCall: CTeamplayRules::TeamMayCapturePoint");
	}
	
	return call;
}

static Handle PrepSDKCall_CTFBotHintEngineerNest_GetSentryHint(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFBotHintEngineerNest::GetSentryHint");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFBotHintEngineerNest::GetSentryHint");
	
	return call;
}

static Handle PrepSDKCall_CTFBotHintEngineerNest_GetTeleporterHint(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFBotHintEngineerNest::GetTeleporterHint");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFBotHintEngineerNest::GetTeleporterHint");
	
	return call;
}

int SDKCall_CTFBotHintEngineerNest_GetSentryHint(int hint)
{
	if (g_hSDKCall_CTFBotHintEngineerNest_GetSentryHint)
		return SDKCall(g_hSDKCall_CTFBotHintEngineerNest_GetSentryHint, hint);
	
	return -1;
}

int SDKCall_CTFBotHintEngineerNest_GetTeleporterHint(int hint)
{
	if (g_hSDKCall_CTFBotHintEngineerNest_GetTeleporterHint)
		return SDKCall(g_hSDKCall_CTFBotHintEngineerNest_GetTeleporterHint, hint);
	
	return -1;
}

static Handle PrepSDKCall_CPopulationManager_GetCurrentWave(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CPopulationManager::GetCurrentWave");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CPopulationManager::GetCurrentWave");
	
	return call;
}

static Handle PrepSDKCall_CBaseEntity_ShouldCollide(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CBaseEntity::ShouldCollide");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CBaseEntity::ShouldCollide");
	
	return call;
}

static Handle PrepSDKCall_CBaseEntity_IsCombatItem(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CBaseEntity::IsCombatItem");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CBaseEntity::IsCombatItem");
	
	return call;
}

static Handle PrepSDKCall_CBaseObject_GetMaxHealthForCurrentLevel(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CBaseObject::GetMaxHealthForCurrentLevel");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CBaseObject::GetMaxHealthForCurrentLevel");
	
	return call;
}

static Handle PrepSDKCall_CBaseCombatWeapon_Clip1(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CBaseCombatWeapon::Clip1");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CBaseCombatWeapon::Clip1");
	
	return call;
}

static Handle PrepSDKCall_CSpawnLocation_FindSpawnLocation(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CSpawnLocation::FindSpawnLocation");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CSpawnLocation::FindSpawnLocation");
	
	return call;
}

static Handle PrepPrepSDKCall_CPopulationManager_GetSentryBusterDamageAndKillThreshold(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CPopulationManager::GetSentryBusterDamageAndKillThreshold");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByRef, VDECODE_FLAG_BYREF, VENCODE_FLAG_COPYBACK);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByRef, VDECODE_FLAG_BYREF, VENCODE_FLAG_COPYBACK);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CPopulationManager::GetSentryBusterDamageAndKillThreshold");
	
	return call;
}

static Handle PrepSDKCall_IPopulationSpawner_Spawn(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "IPopulationSpawner::Spawn");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: IPopulationSpawner::Spawn");
	
	return call;
}

static Handle PrepSDKCall_CTFPlayer_RemoveObject(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayer::RemoveObject");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFPlayer::RemoveObject");
	
	return call;
}

static Handle PrepSDKCall_GetBombInfo(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetBombInfo");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: GetBombInfo");
	
	return call;
}

static Handle PrepSDKCall_CTFBotHintEngineerNest_IsStaleNest(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFBotHintEngineerNest::IsStaleNest");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFBotHintEngineerNest::IsStaleNest");
	
	return call;
}

static Handle PrepSDKCall_CTFBotHintEngineerNest_DetonateStaleNest(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFBotHintEngineerNest::DetonateStaleNest");
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFBotHintEngineerNest::DetonateStaleNest");
	
	return call;
}

static Handle PrepSDKCall_CTFGrenadePipebombProjectile_GetLiveTime(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTFGrenadePipebombProjectile::GetLiveTime");
	PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFGrenadePipebombProjectile::GetLiveTime");
	
	return call;
}

static Handle PrepSDKCall_CBaseTrigger_PassesTriggerFilters(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CBaseTrigger::PassesTriggerFilters");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CBaseTrigger::PassesTriggerFilters");
	
	return call;
}

Address SDKCall_GetClassIcon(any spawner, int nSpawnNum = -1)
{
	Address result;
	
	if (g_hSDKCallGetClassIconWindows)
	{
		// windows version; hidden ptr pushes params, `this` still in correct register
		return SDKCall(g_hSDKCallGetClassIconWindows, spawner, result, nSpawnNum);
	}
	else if (g_hSDKCallGetClassIconLinux)
	{
		// linux version; hidden ptr moves the stack and this forward
		return SDKCall(g_hSDKCallGetClassIconLinux, result, spawner, nSpawnNum);
	}
	
	return Address_Null;
}

bool SDKCall_CTeamplayRoundBasedRules_PlayThrottledAlert(int iTeam, const char[] sound, float fDelayBeforeNext)
{
	if (g_hSDKCall_CTeamplayRoundBasedRules_PlayThrottledAlert)
		return SDKCall(g_hSDKCall_CTeamplayRoundBasedRules_PlayThrottledAlert, iTeam, sound, fDelayBeforeNext);
	
	return false;
}

void SDKCall_CTFPlayer_PostInventoryApplication(int player)
{
	if (g_hSDKCall_CTFPlayer_PostInventoryApplication)
		SDKCall(g_hSDKCall_CTFPlayer_PostInventoryApplication, player);
}

void SDKCall_CEconEntity_UpdateModelToClass(int entity)
{
	if (g_hSDKCall_CEconEntity_UpdateModelToClass)
		SDKCall(g_hSDKCall_CEconEntity_UpdateModelToClass, entity);
}

void SDKCall_CTFItem_PickUp(int flag, int player, bool invisible)
{
	SDKCall(g_hSDKCall_CTFItem_PickUp, flag, player, invisible);
}

void SDKCall_CCaptureZone_Capture(int zone, int other)
{
	if (g_hSDKCall_CCaptureZone_Capture)
		SDKCall(g_hSDKCall_CCaptureZone_Capture, zone, other);
}

void SDKCall_CTFPlayer_DoAnimationEvent(int player, PlayerAnimEvent_t event, int mData = 0)
{
	if (g_hSDKCall_CTFPlayer_DoAnimationEvent)
		SDKCall(g_hSDKCall_CTFPlayer_DoAnimationEvent, player, event, mData);
}

void SDKCall_CTFPlayer_PlaySpecificSequence(int player, const char[] sequenceName)
{
	if (g_hSDKCall_CTFPlayer_PlaySpecificSequence)
		SDKCall(g_hSDKCall_CTFPlayer_PlaySpecificSequence, player, sequenceName);
}

bool SDKCall_CTFPlayer_DoClassSpecialSkill(int player)
{
	if (g_hSDKCall_CTFPlayer_DoClassSpecialSkill)
		return SDKCall(g_hSDKCall_CTFPlayer_DoClassSpecialSkill, player);
	
	return false;
}

void SDKCall_CTFPlayerShared_ResetRageBuffs(any m_Shared)
{
	if (g_hSDKCall_CTFPlayerShared_ResetRageBuffs)
		SDKCall(g_hSDKCall_CTFPlayerShared_ResetRageBuffs, m_Shared);
}

bool SDKCall_CPopulationManager_IsInEndlessWaves(int populator)
{
	if (g_hSDKCall_CPopulationManager_IsInEndlessWaves)
		return SDKCall(g_hSDKCall_CPopulationManager_IsInEndlessWaves, populator);
	
	return false;
}

float SDKCall_CPopulationManager_GetHealthMultiplier(int populator, bool bIsTank = false)
{
	if (g_hSDKCall_CPopulationManager_GetHealthMultiplier)
		return SDKCall(g_hSDKCall_CPopulationManager_GetHealthMultiplier, populator, bIsTank);
	
	return 0.0;
}

void SDKCall_CPopulationManager_ResetMap(int populator)
{
	if (g_hSDKCall_CPopulationManager_ResetMap)
		SDKCall(g_hSDKCall_CPopulationManager_ResetMap, populator);
}

bool SDKCall_IsSpaceToSpawnHere(const float where[3])
{
	if (g_hSDKCall_IsSpaceToSpawnHere)
		return SDKCall(g_hSDKCall_IsSpaceToSpawnHere, where);
	
	return false;
}

bool SDKCall_CTFBotMvMEngineerHintFinder_FindHint(bool bShouldCheckForBlockingObjects, bool bAllowOutOfRangeNest, int &foundNest = -1)
{
	if (g_hSDKCall_CTFBotMvMEngineerHintFinder_FindHint)
	{
		Address pFoundNest;
		bool result = SDKCall(g_hSDKCall_CTFBotMvMEngineerHintFinder_FindHint, bShouldCheckForBlockingObjects, bAllowOutOfRangeNest, pFoundNest);
		
		if (pFoundNest)
		{
			foundNest = GetEntityFromHandle(pFoundNest);
		}
		
		return result;
	}
	
	return false;
}

void SDKCall_CTFGameRules_PushAllPlayersAway(const float vFromThisPoint[3], float flRange, float flForce, TFTeam nTeam, int pPushedPlayers = 0)
{
	if (g_hSDKCall_CTFGameRules_PushAllPlayersAway)
		SDKCall(g_hSDKCall_CTFGameRules_PushAllPlayersAway, vFromThisPoint, flRange, flForce, nTeam, pPushedPlayers);
}

int SDKCall_CTFGameRules_DistributeCurrencyAmount(int amount, int player = -1, bool shared = true, bool countAsDropped = false, bool isBonus = false)
{
	if (g_hSDKCall_CTFGameRules_DistributeCurrencyAmount)
		return SDKCall(g_hSDKCall_CTFGameRules_DistributeCurrencyAmount, amount, player, shared, countAsDropped, isBonus);
	
	return 0;
}

bool SDKCall_CGameRules_ShouldCollide(Collision_Group_t collisionGroup0, Collision_Group_t collisionGroup1)
{
	if (g_hSDKCall_CGameRules_ShouldCollide)
		return SDKCall(g_hSDKCall_CGameRules_ShouldCollide, collisionGroup0, collisionGroup1);
	
	return false;
}

bool SDKCall_CTeamplayRules_TeamMayCapturePoint(TFTeam team, int pointIndex)
{
	if (g_hSDKCall_CTeamplayRules_TeamMayCapturePoint)
		return SDKCall(g_hSDKCall_CTeamplayRules_TeamMayCapturePoint, team, pointIndex);
	
	return false;
}

Address SDKCall_CPopulationManager_GetCurrentWave(int populator)
{
	if (g_hSDKCall_CPopulationManager_GetCurrentWave)
		return SDKCall(g_hSDKCall_CPopulationManager_GetCurrentWave, populator);
	
	return Address_Null;
}

bool SDKCall_CBaseEntity_ShouldCollide(int entity, Collision_Group_t collisionGroup, int contentsMask)
{
	if (g_hSDKCall_CBaseEntity_ShouldCollide)
		return SDKCall(g_hSDKCall_CBaseEntity_ShouldCollide, entity, collisionGroup, contentsMask);
	
	return false;
}

bool SDKCall_CBaseEntity_IsCombatItem(int entity)
{
	if (g_hSDKCall_CBaseEntity_IsCombatItem)
		return SDKCall(g_hSDKCall_CBaseEntity_IsCombatItem, entity);
	
	return false;
}

int SDKCall_CBaseObject_GetMaxHealthForCurrentLevel(int obj)
{
	if (g_hSDKCall_CBaseObject_GetMaxHealthForCurrentLevel)
		return SDKCall(g_hSDKCall_CBaseObject_GetMaxHealthForCurrentLevel, obj);
	
	return 0;
}

int SDKCall_CBaseCombatWeapon_Clip1(int weapon)
{
	if (g_hSDKCall_CBaseCombatWeapon_Clip1)
		return SDKCall(g_hSDKCall_CBaseCombatWeapon_Clip1, weapon);
	
	return 0;
}

SpawnLocationResult SDKCall_CSpawnLocation_FindSpawnLocation(Address pSpawnLocation, float vSpawnPosition[3])
{
	if (g_hSDKCall_CSpawnLocation_FindSpawnLocation)
		return SDKCall(g_hSDKCall_CSpawnLocation_FindSpawnLocation, pSpawnLocation, vSpawnPosition);
	
	return SPAWN_LOCATION_NOT_FOUND;
}

void SDKCall_CPopulationManager_GetSentryBusterDamageAndKillThreshold(int populator, int &nDamage, int &nKills)
{
	if (g_hSDKCall_CPopulationManager_GetSentryBusterDamageAndKillThreshold)
		SDKCall(g_hSDKCall_CPopulationManager_GetSentryBusterDamageAndKillThreshold, populator, nDamage, nKills);
}

bool SDKCall_IPopulationSpawner_Spawn(Address pSpawner, const float vSpawnPosition[3], CUtlVector &spawnVector = view_as<CUtlVector>(0))
{
	if (g_hSDKCall_IPopulationSpawner_Spawn)
		return SDKCall(g_hSDKCall_IPopulationSpawner_Spawn, pSpawner, vSpawnPosition, spawnVector);
	
	return false;
}

void SDKCall_CTFPlayer_RemoveObject(int player, int obj)
{
	if (g_hSDKCall_CTFPlayer_RemoveObject)
		SDKCall(g_hSDKCall_CTFPlayer_RemoveObject, player, obj);
}

bool SDKCall_GetBombInfo(any pBombInfo = Address_Null)
{
	if (g_hSDKCall_GetBombInfo)
		return SDKCall(g_hSDKCall_GetBombInfo, pBombInfo);
	
	return false;
}

bool SDKCall_CTFBotHintEngineerNest_IsStaleNest(int nest)
{
	if (g_hSDKCall_CTFBotHintEngineerNest_IsStaleNest)
		return SDKCall(g_hSDKCall_CTFBotHintEngineerNest_IsStaleNest, nest);
	
	return false;
}

void SDKCall_CTFBotHintEngineerNest_DetonateStaleNest(int nest)
{
	if (g_hSDKCall_CTFBotHintEngineerNest_DetonateStaleNest)
		SDKCall(g_hSDKCall_CTFBotHintEngineerNest_DetonateStaleNest, nest);
}

float SDKCall_CTFGrenadePipebombProjectile_GetLiveTime(int grenade)
{
	if (g_hSDKCall_CTFGrenadePipebombProjectile_GetLiveTime)
		return SDKCall(g_hSDKCall_CTFGrenadePipebombProjectile_GetLiveTime, grenade);
	
	return 0.0;
}

bool SDKCall_CBaseTrigger_PassesTriggerFilters(int trigger, int other)
{
	if (g_hSDKCall_CBaseTrigger_PassesTriggerFilters)
		return SDKCall(g_hSDKCall_CBaseTrigger_PassesTriggerFilters, trigger, other);
	
	return false;
}
