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

static Handle g_SDKCallGetClassIconLinux;
static Handle g_SDKCallGetClassIconWindows;
static Handle g_SDKCallPlayThrottledAlert;
static Handle g_SDKCallPostInventoryApplication;
static Handle g_SDKCallUpdateModelToClass;
static Handle g_SDKCallPickUp;
static Handle g_SDKCallCapture;
static Handle g_SDKCallDoAnimationEvent;
static Handle g_SDKCallPlaySpecificSequence;
static Handle g_SDKCallDoClassSpecialSkill;
static Handle g_SDKCallResetRageBuffs;
static Handle g_SDKCallIsInEndlessWaves;
static Handle g_SDKCallGetHealthMultiplier;
static Handle g_SDKCallResetMap;
static Handle g_SDKCallIsSpaceToSpawnHere;
static Handle g_SDKCallWeaponSwitch;
static Handle g_SDKCallRemoveObject;
static Handle g_SDKCallFindHint;
static Handle g_SDKCallPushAllPlayersAway;
static Handle g_SDKCallDistributeCurrencyAmount;
static Handle g_SDKCallTeamMayCapturePoint;
static Handle g_SDKCallGetSentryHint;
static Handle g_SDKCallGetTeleporterHint;
static Handle g_SDKCallGetCurrentWave;
static Handle g_SDKCallIsCombatItem;
static Handle g_SDKCallGetMaxHealthForCurrentLevel;
static Handle g_SDKCallClip1;
static Handle g_SDKCallFindSpawnLocation;
static Handle g_SDKCallGetSentryBusterDamageAndKillThreshold;
static Handle g_SDKCallCTFBotSpawnerSpawn;
static Handle g_SDKCallGetBombInfo;
static Handle g_SDKCallIsStaleNest;
static Handle g_SDKCallDetonateStaleNest;
static Handle g_SDKCallGetLiveTime;

void SDKCalls_Init(GameData gamedata)
{
	int os = gamedata.GetOffset("Operating System");
	if (os == OS_LINUX)
	{
		g_SDKCallGetClassIconLinux = PrepSDKCall_GetClassIcon_Linux(gamedata);
	}
	else if (os == OS_WINDOWS)
	{
		g_SDKCallGetClassIconWindows = PrepSDKCall_GetClassIcon_Windows(gamedata);
	}
	
	g_SDKCallPlayThrottledAlert = PrepSDKCall_PlayThrottledAlert(gamedata);
	g_SDKCallPostInventoryApplication = PrepSDKCall_PostInventoryApplication(gamedata);
	g_SDKCallUpdateModelToClass = PrepSDKCall_UpdateModelToClass(gamedata);
	g_SDKCallPickUp = PrepSDKCall_PickUp(gamedata);
	g_SDKCallCapture = PrepSDKCall_Capture(gamedata);
	g_SDKCallDoAnimationEvent = PrepSDKCall_DoAnimationEvent(gamedata);
	g_SDKCallPlaySpecificSequence = PrepSDKCall_PlaySpecificSequence(gamedata);
	g_SDKCallDoClassSpecialSkill = PrepSDKCall_DoClassSpecialSkill(gamedata);
	g_SDKCallResetRageBuffs = PrepSDKCall_ResetRageBuffs(gamedata);
	g_SDKCallIsInEndlessWaves = PrepSDKCall_IsInEndlessWaves(gamedata);
	g_SDKCallGetHealthMultiplier = PrepSDKCall_GetHealthMultiplier(gamedata);
	g_SDKCallResetMap = PrepSDKCall_ResetMap(gamedata);
	g_SDKCallIsSpaceToSpawnHere = PrepSDKCall_IsSpaceToSpawnHere(gamedata);
	g_SDKCallWeaponSwitch = PrepSDKCall_WeaponSwitch(gamedata);
	g_SDKCallRemoveObject = PrepSDKCall_RemoveObject(gamedata);
	g_SDKCallFindHint = PrepSDKCall_FindHint(gamedata);
	g_SDKCallPushAllPlayersAway = PrepSDKCall_PushAllPlayersAway(gamedata);
	g_SDKCallDistributeCurrencyAmount = PrepSDKCall_DistributeCurrencyAmount(gamedata);
	g_SDKCallTeamMayCapturePoint = PrepSDKCall_TeamMayCapturePoint(gamedata);
	g_SDKCallGetSentryHint = PrepSDKCall_GetSentryHint(gamedata);
	g_SDKCallGetTeleporterHint = PrepSDKCall_GetTeleporterHint(gamedata);
	g_SDKCallGetCurrentWave = PrepSDKCall_GetCurrentWave(gamedata);
	g_SDKCallIsCombatItem = PrepSDKCall_IsCombatItem(gamedata);
	g_SDKCallGetMaxHealthForCurrentLevel = PrepSDKCall_GetMaxHealthForCurrentLevel(gamedata);
	g_SDKCallClip1 = PrepSDKCall_Clip1(gamedata);
	g_SDKCallFindSpawnLocation = PrepSDKCall_FindSpawnLocation(gamedata);
	g_SDKCallGetSentryBusterDamageAndKillThreshold = PrepSDKCall_GetSentryBusterDamageAndKillThreshold(gamedata);
	g_SDKCallCTFBotSpawnerSpawn = PrepSDKCall_IPopulationSpawnerSpawn(gamedata);
	g_SDKCallGetBombInfo = PrepSDKCall_GetBombInfo(gamedata);
	g_SDKCallIsStaleNest = PrepSDKCall_IsStaleNest(gamedata);
	g_SDKCallDetonateStaleNest = PrepSDKCall_DetonateStaleNest(gamedata);
	g_SDKCallGetLiveTime = PrepSDKCall_GetLiveTime(gamedata);
}

static Handle PrepSDKCall_GetClassIcon_Linux(GameData gamedata)
{
	// linux signature. this uses a hidden pointer passed in before `this` on the stack
	// so we'll do our best with static since SM doesn't support that calling convention
	// no subclasses override this virtual function so we'll just call it directly
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFBotSpawner::GetClassIcon");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer); // return value
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // thisptr
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // int nSpawnNum
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain); // return string_t
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CTFBotSpawner::GetClassIcon");
	
	return call;
}

static Handle PrepSDKCall_GetClassIcon_Windows(GameData gamedata)
{
	// windows vcall. this one also uses a hidden pointer, but it's passed as the first param
	// `this` remains unchanged so we can still use a vcall
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTFBotSpawner::GetClassIcon");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer); // return value
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // int nSpawnNum
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain); // return string_t
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CTFBotSpawner::GetClassIcon");
	
	return call;
}

static Handle PrepSDKCall_PlayThrottledAlert(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTeamplayRoundBasedRules::PlayThrottledAlert");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_ByValue);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CTeamplayRoundBasedRules::PlayThrottledAlert");
	
	return call;
}

static Handle PrepSDKCall_PostInventoryApplication(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::PostInventoryApplication");
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CTFPlayer::PostInventoryApplication");
	
	return call;
}

static Handle PrepSDKCall_UpdateModelToClass(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CEconEntity::UpdateModelToClass");
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CEconEntity::UpdateModelToClass");
	
	return call;
}

static Handle PrepSDKCall_PickUp(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTFItem::PickUp");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CTFItem::PickUp");
	
	return call;
}

static Handle PrepSDKCall_Capture(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CCaptureZone::Capture");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CCaptureZone::Capture");
	
	return call;
}

static Handle PrepSDKCall_DoAnimationEvent(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::DoAnimationEvent");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CTFPlayer::DoAnimationEvent");
	
	return call;
}

static Handle PrepSDKCall_PlaySpecificSequence(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::PlaySpecificSequence");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CTFPlayer::PlaySpecificSequence");
	
	return call;
}

static Handle PrepSDKCall_DoClassSpecialSkill(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::DoClassSpecialSkill");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CTFPlayer::DoClassSpecialSkill");
	
	return call;
}

static Handle PrepSDKCall_ResetRageBuffs(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayerShared::ResetRageBuffs");
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CTFPlayerShared::ResetRageBuffs");
	
	return call;
}

static Handle PrepSDKCall_IsInEndlessWaves(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CPopulationManager::IsInEndlessWaves");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CPopulationManager::IsInEndlessWaves");
	
	return call;
}

static Handle PrepSDKCall_GetHealthMultiplier(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CPopulationManager::GetHealthMultiplier");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CPopulationManager::GetHealthMultiplier");
	
	return call;
}

static Handle PrepSDKCall_ResetMap(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CPopulationManager::ResetMap");
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CPopulationManager::ResetMap");
	
	return call;
}

static Handle PrepSDKCall_IsSpaceToSpawnHere(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "IsSpaceToSpawnHere");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: IsSpaceToSpawnHere");
	
	return call;
}

static Handle PrepSDKCall_FindHint(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFBotMvMEngineerHintFinder::FindHint");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CTFBotMvMEngineerHintFinder::FindHint");
	
	return call;
}

static Handle PrepSDKCall_PushAllPlayersAway(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFGameRules::PushAllPlayersAway");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CTFGameRules::PushAllPlayersAway");
	
	return call;
}

static Handle PrepSDKCall_DistributeCurrencyAmount(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFGameRules::DistributeCurrencyAmount");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	Handle call = EndPrepSDKCall();
	if (!call)
	{
		LogMessage("Failed to create SDKCall: CTFGameRules::DistributeCurrencyAmount");
	}
	
	return call;
}

static Handle PrepSDKCall_TeamMayCapturePoint(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTFGameRules::TeamMayCapturePoint");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
	{
		LogMessage("Failed to create SDKCall: CTFGameRules::TeamMayCapturePoint");
	}
	
	return call;
}

static Handle PrepSDKCall_GetSentryHint(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFBotHintEngineerNest::GetSentryHint");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CTFBotHintEngineerNest::GetSentryHint");
	
	return call;
}

static Handle PrepSDKCall_GetTeleporterHint(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFBotHintEngineerNest::GetTeleporterHint");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CTFBotHintEngineerNest::GetTeleporterHint");
	
	return call;
}

int SDKCall_GetSentryHint(int hint)
{
	if (g_SDKCallGetSentryHint)
		return SDKCall(g_SDKCallGetSentryHint, hint);
	
	return -1;
}

int SDKCall_GetTeleporterHint(int hint)
{
	if (g_SDKCallGetTeleporterHint)
		return SDKCall(g_SDKCallGetTeleporterHint, hint);
	
	return -1;
}

static Handle PrepSDKCall_GetCurrentWave(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CPopulationManager::GetCurrentWave");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CPopulationManager::GetCurrentWave");
	
	return call;
}

static Handle PrepSDKCall_IsCombatItem(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBaseEntity::IsCombatItem");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CBaseEntity::IsCombatItem");
	
	return call;
}

static Handle PrepSDKCall_GetMaxHealthForCurrentLevel(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBaseObject::GetMaxHealthForCurrentLevel");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CBaseObject::GetMaxHealthForCurrentLevel");
	
	return call;
}

static Handle PrepSDKCall_Clip1(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTFWeaponBase::Clip1");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CTFWeaponBase::Clip1");
	
	return call;
}

static Handle PrepSDKCall_FindSpawnLocation(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CSpawnLocation::FindSpawnLocation");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CSpawnLocation::FindSpawnLocation");
	
	return call;
}

static Handle PrepSDKCall_GetSentryBusterDamageAndKillThreshold(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CPopulationManager::GetSentryBusterDamageAndKillThreshold");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByRef, VDECODE_FLAG_BYREF, VENCODE_FLAG_COPYBACK);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByRef, VDECODE_FLAG_BYREF, VENCODE_FLAG_COPYBACK);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CPopulationManager::GetSentryBusterDamageAndKillThreshold");
	
	return call;
}

static Handle PrepSDKCall_IPopulationSpawnerSpawn(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "IPopulationSpawner::Spawn");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: IPopulationSpawner::Spawn");
	
	return call;
}

static Handle PrepSDKCall_WeaponSwitch(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTFPlayer::Weapon_Switch");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CTFPlayer::Weapon_Switch");
	
	return call;
}

static Handle PrepSDKCall_RemoveObject(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::RemoveObject");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CTFPlayer::RemoveObject");
	
	return call;
}

static Handle PrepSDKCall_GetBombInfo(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "GetBombInfo");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: GetBombInfo");
	
	return call;
}

static Handle PrepSDKCall_IsStaleNest(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFBotHintEngineerNest::IsStaleNest");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CTFBotHintEngineerNest::IsStaleNest");
	
	return call;
}

static Handle PrepSDKCall_DetonateStaleNest(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFBotHintEngineerNest::DetonateStaleNest");
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CTFBotHintEngineerNest::DetonateStaleNest");
	
	return call;
}

static Handle PrepSDKCall_GetLiveTime(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTFGrenadePipebombProjectile::GetLiveTime");
	PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CTFGrenadePipebombProjectile::GetLiveTime");
	
	return call;
}

Address SDKCall_GetClassIcon(any spawner, int nSpawnNum = -1)
{
	Address result;
	
	if (g_SDKCallGetClassIconWindows)
	{
		// windows version; hidden ptr pushes params, `this` still in correct register
		return SDKCall(g_SDKCallGetClassIconWindows, spawner, result, nSpawnNum);
	}
	else if (g_SDKCallGetClassIconLinux)
	{
		// linux version; hidden ptr moves the stack and this forward
		return SDKCall(g_SDKCallGetClassIconLinux, result, spawner, nSpawnNum);
	}
	
	return Address_Null;
}

bool SDKCall_PlayThrottledAlert(int iTeam, const char[] sound, float fDelayBeforeNext)
{
	if (g_SDKCallPlayThrottledAlert)
		return SDKCall(g_SDKCallPlayThrottledAlert, iTeam, sound, fDelayBeforeNext);
	
	return false;
}

void SDKCall_PostInventoryApplication(int player)
{
	if (g_SDKCallPostInventoryApplication)
		SDKCall(g_SDKCallPostInventoryApplication, player);
}

void SDKCall_UpdateModelToClass(int entity)
{
	if (g_SDKCallUpdateModelToClass)
		SDKCall(g_SDKCallUpdateModelToClass, entity);
}

void SDKCall_PickUp(int flag, int player, bool invisible)
{
	SDKCall(g_SDKCallPickUp, flag, player, invisible);
}

void SDKCall_Capture(int zone, int other)
{
	if (g_SDKCallCapture)
		SDKCall(g_SDKCallCapture, zone, other);
}

void SDKCall_DoAnimationEvent(int player, PlayerAnimEvent_t event, int mData = 0)
{
	if (g_SDKCallDoAnimationEvent)
		SDKCall(g_SDKCallDoAnimationEvent, player, event, mData);
}

void SDKCall_PlaySpecificSequence(int player, const char[] sequenceName)
{
	if (g_SDKCallPlaySpecificSequence)
		SDKCall(g_SDKCallPlaySpecificSequence, player, sequenceName);
}

bool SDKCall_DoClassSpecialSkill(int player)
{
	if (g_SDKCallDoClassSpecialSkill)
		return SDKCall(g_SDKCallDoClassSpecialSkill, player);
	
	return false;
}

void SDKCall_ResetRageBuffs(any m_Shared)
{
	if (g_SDKCallResetRageBuffs)
		SDKCall(g_SDKCallResetRageBuffs, m_Shared);
}

bool SDKCall_IsInEndlessWaves(int populator)
{
	if (g_SDKCallIsInEndlessWaves)
		return SDKCall(g_SDKCallIsInEndlessWaves, populator);
	
	return false;
}

float SDKCall_GetHealthMultiplier(int populator, bool bIsTank = false)
{
	if (g_SDKCallGetHealthMultiplier)
		return SDKCall(g_SDKCallGetHealthMultiplier, populator, bIsTank);
	
	return 0.0;
}

void SDKCall_ResetMap(int populator)
{
	if (g_SDKCallResetMap)
		SDKCall(g_SDKCallResetMap, populator);
}

bool SDKCall_IsSpaceToSpawnHere(const float where[3])
{
	if (g_SDKCallIsSpaceToSpawnHere)
		return SDKCall(g_SDKCallIsSpaceToSpawnHere, where);
	
	return false;
}

bool SDKCall_FindHint(bool bShouldCheckForBlockingObjects, bool bAllowOutOfRangeNest, int &foundNest = -1)
{
	if (g_SDKCallFindHint)
	{
		int pFoundNest;
		bool result = SDKCall(g_SDKCallFindHint, bShouldCheckForBlockingObjects, bAllowOutOfRangeNest, pFoundNest);
		
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
	if (g_SDKCallPushAllPlayersAway)
		SDKCall(g_SDKCallPushAllPlayersAway, vFromThisPoint, flRange, flForce, nTeam, pPushedPlayers);
}

int SDKCall_DistributeCurrencyAmount(int amount, int player = -1, bool shared = true, bool countAsDropped = false, bool isBonus = false)
{
	if (g_SDKCallDistributeCurrencyAmount)
		return SDKCall(g_SDKCallDistributeCurrencyAmount, amount, player, shared, countAsDropped, isBonus);
	
	return 0;
}

bool SDKCall_TeamMayCapturePoint(TFTeam team, int pointIndex)
{
	if (g_SDKCallTeamMayCapturePoint)
		return SDKCall(g_SDKCallTeamMayCapturePoint, team, pointIndex);
	
	return false;
}

Address SDKCall_GetCurrentWave(int populator)
{
	if (g_SDKCallGetCurrentWave)
		return SDKCall(g_SDKCallGetCurrentWave, populator);
	
	return Address_Null;
}

bool SDKCall_IsCombatItem(int entity)
{
	if (g_SDKCallIsCombatItem)
		return SDKCall(g_SDKCallIsCombatItem, entity);
	
	return false;
}

int SDKCall_GetMaxHealthForCurrentLevel(int obj)
{
	if (g_SDKCallGetMaxHealthForCurrentLevel)
		return SDKCall(g_SDKCallGetMaxHealthForCurrentLevel, obj);
	
	return 0;
}

int SDKCall_Clip1(int weapon)
{
	if (g_SDKCallClip1)
		return SDKCall(g_SDKCallClip1, weapon);
	
	return 0;
}

SpawnLocationResult SDKCall_FindSpawnLocation(Address pSpawnLocation, float vSpawnPosition[3])
{
	if (g_SDKCallFindSpawnLocation)
		return SDKCall(g_SDKCallFindSpawnLocation, pSpawnLocation, vSpawnPosition);
	
	return SPAWN_LOCATION_NOT_FOUND;
}

void SDKCall_GetSentryBusterDamageAndKillThreshold(int populator, int &nDamage, int &nKills)
{
	if (g_SDKCallGetSentryBusterDamageAndKillThreshold)
		SDKCall(g_SDKCallGetSentryBusterDamageAndKillThreshold, populator, nDamage, nKills);
}

bool SDKCall_IPopulationSpawnerSpawn(Address pSpawner, const float vSpawnPosition[3], CUtlVector &spawnVector = view_as<CUtlVector>(0))
{
	if (g_SDKCallCTFBotSpawnerSpawn)
		return SDKCall(g_SDKCallCTFBotSpawnerSpawn, pSpawner, vSpawnPosition, spawnVector);
	
	return false;
}

bool SDKCall_WeaponSwitch(int player, int weapon, int viewmodelindex = 0)
{
	if (g_SDKCallWeaponSwitch)
		return SDKCall(g_SDKCallWeaponSwitch, player, weapon, viewmodelindex);
	
	return false;
}

void SDKCall_RemoveObject(int player, int obj)
{
	if (g_SDKCallRemoveObject)
		SDKCall(g_SDKCallRemoveObject, player, obj);
}

bool SDKCall_GetBombInfo(any pBombInfo = Address_Null)
{
	if (g_SDKCallGetBombInfo)
		return SDKCall(g_SDKCallGetBombInfo, pBombInfo);
	
	return false;
}

bool SDKCall_IsStaleNest(int nest)
{
	if (g_SDKCallIsStaleNest)
		return SDKCall(g_SDKCallIsStaleNest, nest);
	
	return false;
}

void SDKCall_DetonateStaleNest(int nest)
{
	if (g_SDKCallDetonateStaleNest)
		SDKCall(g_SDKCallDetonateStaleNest, nest);
}

float SDKCall_GetLiveTime(int grenade)
{
	if (g_SDKCallGetLiveTime)
		return SDKCall(g_SDKCallGetLiveTime, grenade);
	
	return 0.0;
}
