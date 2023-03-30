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
static Handle g_hSDKCallPlayThrottledAlert;
static Handle g_hSDKCallPostInventoryApplication;
static Handle g_hSDKCallUpdateModelToClass;
static Handle g_hSDKCallPickUp;
static Handle g_hSDKCallCapture;
static Handle g_hSDKCallDoAnimationEvent;
static Handle g_hSDKCallPlaySpecificSequence;
static Handle g_hSDKCallDoClassSpecialSkill;
static Handle g_hSDKCallResetRageBuffs;
static Handle g_hSDKCallIsInEndlessWaves;
static Handle g_hSDKCallGetHealthMultiplier;
static Handle g_hSDKCallResetMap;
static Handle g_hSDKCallIsSpaceToSpawnHere;
static Handle g_hSDKCallRemoveObject;
static Handle g_hSDKCallFindHint;
static Handle g_hSDKCallPushAllPlayersAway;
static Handle g_hSDKCallDistributeCurrencyAmount;
static Handle g_hSDKCallTeamMayCapturePoint;
static Handle g_hSDKCallGetSentryHint;
static Handle g_hSDKCallGetTeleporterHint;
static Handle g_hSDKCallGetCurrentWave;
static Handle g_hSDKCallIsCombatItem;
static Handle g_hSDKCallGetMaxHealthForCurrentLevel;
static Handle g_hSDKCallClip1;
static Handle g_hSDKCallFindSpawnLocation;
static Handle g_hSDKCallGetSentryBusterDamageAndKillThreshold;
static Handle g_hSDKCallCTFBotSpawnerSpawn;
static Handle g_hSDKCallGetBombInfo;
static Handle g_hSDKCallIsStaleNest;
static Handle g_hSDKCallDetonateStaleNest;
static Handle g_hSDKCallGetLiveTime;
static Handle g_hSDKCallPassesTriggerFilters;

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
	
	g_hSDKCallPlayThrottledAlert = PrepSDKCall_PlayThrottledAlert(hGameData);
	g_hSDKCallPostInventoryApplication = PrepSDKCall_PostInventoryApplication(hGameData);
	g_hSDKCallUpdateModelToClass = PrepSDKCall_UpdateModelToClass(hGameData);
	g_hSDKCallPickUp = PrepSDKCall_PickUp(hGameData);
	g_hSDKCallCapture = PrepSDKCall_Capture(hGameData);
	g_hSDKCallDoAnimationEvent = PrepSDKCall_DoAnimationEvent(hGameData);
	g_hSDKCallPlaySpecificSequence = PrepSDKCall_PlaySpecificSequence(hGameData);
	g_hSDKCallDoClassSpecialSkill = PrepSDKCall_DoClassSpecialSkill(hGameData);
	g_hSDKCallResetRageBuffs = PrepSDKCall_ResetRageBuffs(hGameData);
	g_hSDKCallIsInEndlessWaves = PrepSDKCall_IsInEndlessWaves(hGameData);
	g_hSDKCallGetHealthMultiplier = PrepSDKCall_GetHealthMultiplier(hGameData);
	g_hSDKCallResetMap = PrepSDKCall_ResetMap(hGameData);
	g_hSDKCallIsSpaceToSpawnHere = PrepSDKCall_IsSpaceToSpawnHere(hGameData);
	g_hSDKCallRemoveObject = PrepSDKCall_RemoveObject(hGameData);
	g_hSDKCallFindHint = PrepSDKCall_FindHint(hGameData);
	g_hSDKCallPushAllPlayersAway = PrepSDKCall_PushAllPlayersAway(hGameData);
	g_hSDKCallDistributeCurrencyAmount = PrepSDKCall_DistributeCurrencyAmount(hGameData);
	g_hSDKCallTeamMayCapturePoint = PrepSDKCall_TeamMayCapturePoint(hGameData);
	g_hSDKCallGetSentryHint = PrepSDKCall_GetSentryHint(hGameData);
	g_hSDKCallGetTeleporterHint = PrepSDKCall_GetTeleporterHint(hGameData);
	g_hSDKCallGetCurrentWave = PrepSDKCall_GetCurrentWave(hGameData);
	g_hSDKCallIsCombatItem = PrepSDKCall_IsCombatItem(hGameData);
	g_hSDKCallGetMaxHealthForCurrentLevel = PrepSDKCall_GetMaxHealthForCurrentLevel(hGameData);
	g_hSDKCallClip1 = PrepSDKCall_Clip1(hGameData);
	g_hSDKCallFindSpawnLocation = PrepSDKCall_FindSpawnLocation(hGameData);
	g_hSDKCallGetSentryBusterDamageAndKillThreshold = PrepSDKCall_GetSentryBusterDamageAndKillThreshold(hGameData);
	g_hSDKCallCTFBotSpawnerSpawn = PrepSDKCall_IPopulationSpawnerSpawn(hGameData);
	g_hSDKCallGetBombInfo = PrepSDKCall_GetBombInfo(hGameData);
	g_hSDKCallIsStaleNest = PrepSDKCall_IsStaleNest(hGameData);
	g_hSDKCallDetonateStaleNest = PrepSDKCall_DetonateStaleNest(hGameData);
	g_hSDKCallGetLiveTime = PrepSDKCall_GetLiveTime(hGameData);
	g_hSDKCallPassesTriggerFilters = PrepSDKCall_PassesTriggerFilters(hGameData);
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

static Handle PrepSDKCall_PlayThrottledAlert(GameData hGameData)
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

static Handle PrepSDKCall_PostInventoryApplication(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayer::PostInventoryApplication");
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFPlayer::PostInventoryApplication");
	
	return call;
}

static Handle PrepSDKCall_UpdateModelToClass(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CEconEntity::UpdateModelToClass");
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CEconEntity::UpdateModelToClass");
	
	return call;
}

static Handle PrepSDKCall_PickUp(GameData hGameData)
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

static Handle PrepSDKCall_Capture(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CCaptureZone::Capture");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CCaptureZone::Capture");
	
	return call;
}

static Handle PrepSDKCall_DoAnimationEvent(GameData hGameData)
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

static Handle PrepSDKCall_PlaySpecificSequence(GameData hGameData)
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

static Handle PrepSDKCall_DoClassSpecialSkill(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayer::DoClassSpecialSkill");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFPlayer::DoClassSpecialSkill");
	
	return call;
}

static Handle PrepSDKCall_ResetRageBuffs(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayerShared::ResetRageBuffs");
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFPlayerShared::ResetRageBuffs");
	
	return call;
}

static Handle PrepSDKCall_IsInEndlessWaves(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CPopulationManager::IsInEndlessWaves");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CPopulationManager::IsInEndlessWaves");
	
	return call;
}

static Handle PrepSDKCall_GetHealthMultiplier(GameData hGameData)
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

static Handle PrepSDKCall_ResetMap(GameData hGameData)
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

static Handle PrepSDKCall_FindHint(GameData hGameData)
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

static Handle PrepSDKCall_PushAllPlayersAway(GameData hGameData)
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

static Handle PrepSDKCall_DistributeCurrencyAmount(GameData hGameData)
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

static Handle PrepSDKCall_TeamMayCapturePoint(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTFGameRules::TeamMayCapturePoint");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
	{
		LogError("Failed to create SDKCall: CTFGameRules::TeamMayCapturePoint");
	}
	
	return call;
}

static Handle PrepSDKCall_GetSentryHint(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFBotHintEngineerNest::GetSentryHint");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFBotHintEngineerNest::GetSentryHint");
	
	return call;
}

static Handle PrepSDKCall_GetTeleporterHint(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFBotHintEngineerNest::GetTeleporterHint");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFBotHintEngineerNest::GetTeleporterHint");
	
	return call;
}

int SDKCall_GetSentryHint(int hint)
{
	if (g_hSDKCallGetSentryHint)
		return SDKCall(g_hSDKCallGetSentryHint, hint);
	
	return -1;
}

int SDKCall_GetTeleporterHint(int hint)
{
	if (g_hSDKCallGetTeleporterHint)
		return SDKCall(g_hSDKCallGetTeleporterHint, hint);
	
	return -1;
}

static Handle PrepSDKCall_GetCurrentWave(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CPopulationManager::GetCurrentWave");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CPopulationManager::GetCurrentWave");
	
	return call;
}

static Handle PrepSDKCall_IsCombatItem(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CBaseEntity::IsCombatItem");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CBaseEntity::IsCombatItem");
	
	return call;
}

static Handle PrepSDKCall_GetMaxHealthForCurrentLevel(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CBaseObject::GetMaxHealthForCurrentLevel");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CBaseObject::GetMaxHealthForCurrentLevel");
	
	return call;
}

static Handle PrepSDKCall_Clip1(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTFWeaponBase::Clip1");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFWeaponBase::Clip1");
	
	return call;
}

static Handle PrepSDKCall_FindSpawnLocation(GameData hGameData)
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

static Handle PrepSDKCall_GetSentryBusterDamageAndKillThreshold(GameData hGameData)
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

static Handle PrepSDKCall_IPopulationSpawnerSpawn(GameData hGameData)
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

static Handle PrepSDKCall_RemoveObject(GameData hGameData)
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

static Handle PrepSDKCall_IsStaleNest(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFBotHintEngineerNest::IsStaleNest");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFBotHintEngineerNest::IsStaleNest");
	
	return call;
}

static Handle PrepSDKCall_DetonateStaleNest(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFBotHintEngineerNest::DetonateStaleNest");
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFBotHintEngineerNest::DetonateStaleNest");
	
	return call;
}

static Handle PrepSDKCall_GetLiveTime(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTFGrenadePipebombProjectile::GetLiveTime");
	PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFGrenadePipebombProjectile::GetLiveTime");
	
	return call;
}

static Handle PrepSDKCall_PassesTriggerFilters(GameData hGameData)
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

bool SDKCall_PlayThrottledAlert(int iTeam, const char[] sound, float fDelayBeforeNext)
{
	if (g_hSDKCallPlayThrottledAlert)
		return SDKCall(g_hSDKCallPlayThrottledAlert, iTeam, sound, fDelayBeforeNext);
	
	return false;
}

void SDKCall_PostInventoryApplication(int player)
{
	if (g_hSDKCallPostInventoryApplication)
		SDKCall(g_hSDKCallPostInventoryApplication, player);
}

void SDKCall_UpdateModelToClass(int entity)
{
	if (g_hSDKCallUpdateModelToClass)
		SDKCall(g_hSDKCallUpdateModelToClass, entity);
}

void SDKCall_PickUp(int flag, int player, bool invisible)
{
	SDKCall(g_hSDKCallPickUp, flag, player, invisible);
}

void SDKCall_Capture(int zone, int other)
{
	if (g_hSDKCallCapture)
		SDKCall(g_hSDKCallCapture, zone, other);
}

void SDKCall_DoAnimationEvent(int player, PlayerAnimEvent_t event, int mData = 0)
{
	if (g_hSDKCallDoAnimationEvent)
		SDKCall(g_hSDKCallDoAnimationEvent, player, event, mData);
}

void SDKCall_PlaySpecificSequence(int player, const char[] sequenceName)
{
	if (g_hSDKCallPlaySpecificSequence)
		SDKCall(g_hSDKCallPlaySpecificSequence, player, sequenceName);
}

bool SDKCall_DoClassSpecialSkill(int player)
{
	if (g_hSDKCallDoClassSpecialSkill)
		return SDKCall(g_hSDKCallDoClassSpecialSkill, player);
	
	return false;
}

void SDKCall_ResetRageBuffs(any m_Shared)
{
	if (g_hSDKCallResetRageBuffs)
		SDKCall(g_hSDKCallResetRageBuffs, m_Shared);
}

bool SDKCall_IsInEndlessWaves(int populator)
{
	if (g_hSDKCallIsInEndlessWaves)
		return SDKCall(g_hSDKCallIsInEndlessWaves, populator);
	
	return false;
}

float SDKCall_GetHealthMultiplier(int populator, bool bIsTank = false)
{
	if (g_hSDKCallGetHealthMultiplier)
		return SDKCall(g_hSDKCallGetHealthMultiplier, populator, bIsTank);
	
	return 0.0;
}

void SDKCall_ResetMap(int populator)
{
	if (g_hSDKCallResetMap)
		SDKCall(g_hSDKCallResetMap, populator);
}

bool SDKCall_IsSpaceToSpawnHere(const float where[3])
{
	if (g_hSDKCallIsSpaceToSpawnHere)
		return SDKCall(g_hSDKCallIsSpaceToSpawnHere, where);
	
	return false;
}

bool SDKCall_FindHint(bool bShouldCheckForBlockingObjects, bool bAllowOutOfRangeNest, int &foundNest = -1)
{
	if (g_hSDKCallFindHint)
	{
		Address pFoundNest;
		bool result = SDKCall(g_hSDKCallFindHint, bShouldCheckForBlockingObjects, bAllowOutOfRangeNest, pFoundNest);
		
		if (pFoundNest)
		{
			foundNest = GetEntityFromHandle(pFoundNest);
		}
		
		return result;
	}
	
	return false;
}

void SDKCall_PushAllPlayersAway(const float vFromThisPoint[3], float flRange, float flForce, TFTeam nTeam, int pPushedPlayers = 0)
{
	if (g_hSDKCallPushAllPlayersAway)
		SDKCall(g_hSDKCallPushAllPlayersAway, vFromThisPoint, flRange, flForce, nTeam, pPushedPlayers);
}

int SDKCall_DistributeCurrencyAmount(int amount, int player = -1, bool shared = true, bool countAsDropped = false, bool isBonus = false)
{
	if (g_hSDKCallDistributeCurrencyAmount)
		return SDKCall(g_hSDKCallDistributeCurrencyAmount, amount, player, shared, countAsDropped, isBonus);
	
	return 0;
}

bool SDKCall_TeamMayCapturePoint(TFTeam team, int pointIndex)
{
	if (g_hSDKCallTeamMayCapturePoint)
		return SDKCall(g_hSDKCallTeamMayCapturePoint, team, pointIndex);
	
	return false;
}

Address SDKCall_GetCurrentWave(int populator)
{
	if (g_hSDKCallGetCurrentWave)
		return SDKCall(g_hSDKCallGetCurrentWave, populator);
	
	return Address_Null;
}

bool SDKCall_IsCombatItem(int entity)
{
	if (g_hSDKCallIsCombatItem)
		return SDKCall(g_hSDKCallIsCombatItem, entity);
	
	return false;
}

int SDKCall_GetMaxHealthForCurrentLevel(int obj)
{
	if (g_hSDKCallGetMaxHealthForCurrentLevel)
		return SDKCall(g_hSDKCallGetMaxHealthForCurrentLevel, obj);
	
	return 0;
}

int SDKCall_Clip1(int weapon)
{
	if (g_hSDKCallClip1)
		return SDKCall(g_hSDKCallClip1, weapon);
	
	return 0;
}

SpawnLocationResult SDKCall_FindSpawnLocation(Address pSpawnLocation, float vSpawnPosition[3])
{
	if (g_hSDKCallFindSpawnLocation)
		return SDKCall(g_hSDKCallFindSpawnLocation, pSpawnLocation, vSpawnPosition);
	
	return SPAWN_LOCATION_NOT_FOUND;
}

void SDKCall_GetSentryBusterDamageAndKillThreshold(int populator, int &nDamage, int &nKills)
{
	if (g_hSDKCallGetSentryBusterDamageAndKillThreshold)
		SDKCall(g_hSDKCallGetSentryBusterDamageAndKillThreshold, populator, nDamage, nKills);
}

bool SDKCall_IPopulationSpawnerSpawn(Address pSpawner, const float vSpawnPosition[3], CUtlVector &spawnVector = view_as<CUtlVector>(0))
{
	if (g_hSDKCallCTFBotSpawnerSpawn)
		return SDKCall(g_hSDKCallCTFBotSpawnerSpawn, pSpawner, vSpawnPosition, spawnVector);
	
	return false;
}

void SDKCall_RemoveObject(int player, int obj)
{
	if (g_hSDKCallRemoveObject)
		SDKCall(g_hSDKCallRemoveObject, player, obj);
}

bool SDKCall_GetBombInfo(any pBombInfo = Address_Null)
{
	if (g_hSDKCallGetBombInfo)
		return SDKCall(g_hSDKCallGetBombInfo, pBombInfo);
	
	return false;
}

bool SDKCall_IsStaleNest(int nest)
{
	if (g_hSDKCallIsStaleNest)
		return SDKCall(g_hSDKCallIsStaleNest, nest);
	
	return false;
}

void SDKCall_DetonateStaleNest(int nest)
{
	if (g_hSDKCallDetonateStaleNest)
		SDKCall(g_hSDKCallDetonateStaleNest, nest);
}

float SDKCall_GetLiveTime(int grenade)
{
	if (g_hSDKCallGetLiveTime)
		return SDKCall(g_hSDKCallGetLiveTime, grenade);
	
	return 0.0;
}

bool SDKCall_PassesTriggerFilters(int trigger, int other)
{
	if (g_hSDKCallPassesTriggerFilters)
		return SDKCall(g_hSDKCallPassesTriggerFilters, trigger, other);
	
	return false;
}
