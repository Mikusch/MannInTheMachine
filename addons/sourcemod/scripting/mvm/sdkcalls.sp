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

static Handle g_SDKCallRemovePlayerAttributes;
static Handle g_SDKCallPostInventoryApplication;
static Handle g_SDKCallUpdateModelToClass;
static Handle g_SDKCallWeaponDetach;

void SDKCalls_Initialize(GameData gamedata)
{
	g_SDKCallRemovePlayerAttributes = PrepSDKCall_RemovePlayerAttributes(gamedata);
	g_SDKCallPostInventoryApplication = PrepSDKCall_PostInventoryApplication(gamedata);
	g_SDKCallUpdateModelToClass = PrepSDKCall_UpdateModelToClass(gamedata);
	g_SDKCallWeaponDetach = PrepSDKCall_WeaponDetach(gamedata);
}

static Handle PrepSDKCall_RemovePlayerAttributes(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::RemovePlayerAttributes");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CTFPlayer::RemovePlayerAttributes");
	
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

static Handle PrepSDKCall_WeaponDetach(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBaseCombatCharacter::Weapon_Detach");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create SDKCall: CBaseCombatCharacter::Weapon_Detach");
	
	return call;
}

void SDKCall_RemovePlayerAttributes(int player, bool setBonuses)
{
	if (g_SDKCallRemovePlayerAttributes)
		SDKCall(g_SDKCallRemovePlayerAttributes, player, setBonuses);
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

void SDKCall_WeaponDetach(int player, int weapon)
{
	if (g_SDKCallWeaponDetach)
		SDKCall(g_SDKCallWeaponDetach, player, weapon);
}
