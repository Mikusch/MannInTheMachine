/*
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
static Handle g_SDKCallPostInventoryApplication;
static Handle g_SDKCallUpdateModelToClass;
static Handle g_SDKCallHasTheFlag;
static Handle g_SDKCallPickUp;
static Handle g_SDKCallCapture;
static Handle g_SDKCallDoAnimationEvent;
static Handle g_SDKCallPlaySpecificSequence;
static Handle g_SDKCallDoClassSpecialSkill;
static Handle g_SDKCallGetHealthMultiplier;
static Handle g_SDKCallResetMap;
static Handle g_SDKCallIsSpaceToSpawnHere;
static Handle g_SDKCallWeaponSwitch;
static Handle g_SDKCallFindHint;

void SDKCalls_Initialize(GameData gamedata)
{
	g_SDKCallGetClassIconLinux = PrepSDKCall_GetClassIcon_Linux(gamedata);
	if (!g_SDKCallGetClassIconLinux)
	{
		g_SDKCallGetClassIconWindows = PrepSDKCall_GetClassIcon_Windows(gamedata);
	}
	
	if (!g_SDKCallGetClassIconLinux && !g_SDKCallGetClassIconWindows)
	{
		LogMessage("Failed to create SDKCall: CTFBotSpawner::GetClassIcon");
	}
	
	g_SDKCallPostInventoryApplication = PrepSDKCall_PostInventoryApplication(gamedata);
	g_SDKCallUpdateModelToClass = PrepSDKCall_UpdateModelToClass(gamedata);
	g_SDKCallHasTheFlag = PrepSDKCall_HasTheFlag(gamedata);
	g_SDKCallPickUp = PrepSDKCall_PickUp(gamedata);
	g_SDKCallCapture = PrepSDKCall_Capture(gamedata);
	g_SDKCallDoAnimationEvent = PrepSDKCall_DoAnimationEvent(gamedata);
	g_SDKCallPlaySpecificSequence = PrepSDKCall_PlaySpecificSequence(gamedata);
	g_SDKCallDoClassSpecialSkill = PrepSDKCall_DoClassSpecialSkill(gamedata);
	g_SDKCallGetHealthMultiplier = PrepSDKCall_GetHealthMultiplier(gamedata);
	g_SDKCallResetMap = PrepSDKCall_ResetMap(gamedata);
	g_SDKCallIsSpaceToSpawnHere = PrepSDKCall_IsSpaceToSpawnHere(gamedata);
	g_SDKCallWeaponSwitch = PrepSDKCall_WeaponSwitch(gamedata);
	g_SDKCallFindHint = PrepSDKCall_FindHint(gamedata);
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
	
	return EndPrepSDKCall();
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
	
	return EndPrepSDKCall();
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

static Handle PrepSDKCall_HasTheFlag(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::HasTheFlag");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CTFPlayer::HasTheFlag");
	
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

bool SDKCall_HasTheFlag(int player, int exceptionTypes = 0, int nNumExceptions = 0)
{
	if (g_SDKCallHasTheFlag)
		return SDKCall(g_SDKCallHasTheFlag, player, exceptionTypes, nNumExceptions);
	
	return false;
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

bool SDKCall_FindHint(bool bShouldCheckForBlockingObjects, bool bAllowOutOfRangeNest, int& pFoundNest = -1)
{
	if (g_SDKCallFindHint)
		return SDKCall(g_SDKCallFindHint, bShouldCheckForBlockingObjects, bAllowOutOfRangeNest, pFoundNest);
	
	return false;
}

bool SDKCall_WeaponSwitch(int player, int weapon, int viewmodelindex = 0)
{
	if (g_SDKCallWeaponSwitch)
		return SDKCall(g_SDKCallWeaponSwitch, player, weapon, viewmodelindex);
	
	return false;
}
