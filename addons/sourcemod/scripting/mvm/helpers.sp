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

bool GameRules_IsMannVsMachineMode()
{
	return view_as<bool>(GameRules_GetProp("m_bPlayingMannVsMachine"));
}

void SetModelScale(int entity, float scale, float duration = 0.0)
{
	float vecScale[3];
	vecScale[0] = scale;
	vecScale[1] = scale;
	vecScale[2] = duration;
	
	SetVariantVector3D(vecScale);
	AcceptEntityInput(entity, "SetModelScale");
}

bool IsMiscSlot(int iSlot)
{
	return iSlot == LOADOUT_POSITION_MISC
		|| iSlot == LOADOUT_POSITION_MISC2
		|| iSlot == LOADOUT_POSITION_HEAD;
}

bool IsTauntSlot(int iSlot)
{
	return iSlot == LOADOUT_POSITION_TAUNT
		|| iSlot == LOADOUT_POSITION_TAUNT2
		|| iSlot == LOADOUT_POSITION_TAUNT3
		|| iSlot == LOADOUT_POSITION_TAUNT4
		|| iSlot == LOADOUT_POSITION_TAUNT5
		|| iSlot == LOADOUT_POSITION_TAUNT6
		|| iSlot == LOADOUT_POSITION_TAUNT7
		|| iSlot == LOADOUT_POSITION_TAUNT8;
}

bool IsWearableSlot(int iSlot)
{
	return iSlot == LOADOUT_POSITION_HEAD
		|| iSlot == LOADOUT_POSITION_MISC
		|| iSlot == LOADOUT_POSITION_ACTION
		|| IsMiscSlot(iSlot)
		|| IsTauntSlot(iSlot);
}

void AddItem(int player, const char[] pszItemName)
{
	int defindex = FindItemByName(pszItemName);
	
	// If we already have an item in that slot, remove it
	TFClassType class = TF2_GetPlayerClass(player);
	int slot = TF2Econ_GetItemLoadoutSlot(defindex, class);
	int newItemRegionMask = TF2Econ_GetItemEquipRegionMask(defindex);
	
	if (IsWearableSlot(slot))
	{
		// Remove any wearable that has a conflicting equip_region
		for (int wbl = 0; wbl < TF2Util_GetPlayerWearableCount(player); wbl++)
		{
			int pWearable = TF2Util_GetPlayerWearable(player, wbl);
			if (pWearable == -1)
				continue;
			
			int wearableDefindex = GetEntProp(pWearable, Prop_Send, "m_iItemDefinitionIndex");
			
			// TODO: What causes this?
			if (wearableDefindex == 65535)
				continue;
			
			int wearableRegionMask = TF2Econ_GetItemEquipRegionMask(wearableDefindex);
			
			if (wearableRegionMask & newItemRegionMask)
			{
				TF2_RemoveWeaponSlot(player, pWearable);
			}
		}
	}
	else
	{
		int entity = TF2Util_GetPlayerLoadoutEntity(player, slot);
		if (entity != -1)
		{
			SDKCall_WeaponDetach(player, entity);
			RemoveEntity(entity);
		}
	}
	
	int item = CreateAndEquipItem(player, defindex);
	
	if (TF2Util_IsEntityWearable(item))
		TF2Util_EquipPlayerWearable(player, item)
	else
		EquipPlayerWeapon(player, item);
	
	SDKCall_PostInventoryApplication(player);
}

int CreateAndEquipItem(int player, int defindex)
{
	Handle hItem = TF2Items_CreateItem(PRESERVE_ATTRIBUTES | FORCE_GENERATION);
	
	char classname[64];
	TF2Econ_GetItemClassName(defindex, classname, sizeof(classname));
	
	TF2Items_SetClassname(hItem, classname);
	TF2Items_SetItemIndex(hItem, defindex);
	TF2Items_SetQuality(hItem, 1);
	TF2Items_SetLevel(hItem, 1);
	
	int item = TF2Items_GiveNamedItem(player, hItem);
	
	delete hItem;
	
	SetEntProp(item, Prop_Send, "m_bValidatedAttachedEntity", true);
	
	return item;
}

int FindItemByName(const char[] name)
{
	if (!name[0])
	{
		return TF_ITEMDEF_DEFAULT;
	}
	
	static StringMap s_ItemDefsByName;
	if (s_ItemDefsByName)
	{
		int value = TF_ITEMDEF_DEFAULT;
		return s_ItemDefsByName.GetValue(name, value) ? value : TF_ITEMDEF_DEFAULT;
	}
	
	s_ItemDefsByName = new StringMap();
	
	ArrayList itemList = TF2Econ_GetItemList();
	char nameBuffer[64];
	for (int i, nItems = itemList.Length; i < nItems; i++)
	{
		int itemdef = itemList.Get(i);
		TF2Econ_GetItemName(itemdef, nameBuffer, sizeof(nameBuffer));
		s_ItemDefsByName.SetValue(nameBuffer, itemdef);
	}
	delete itemList;
	
	return FindItemByName(name);
}

int UTIL_StringtToCharArray(Address string_t, char[] buffer, int maxlen)
{
	if (string_t == Address_Null)
		ThrowError("string_t address is null");
	
	if (maxlen <= 0)
		ThrowError("Buffer size is negative or zero");
	
	int max = maxlen - 1;
	int i = 0;
	for (; i < max; i++)
	if ((buffer[i] = view_as<char>(LoadFromAddress(string_t + view_as<Address>(i), NumberType_Int8))) == '\0')
		return i;
	
	buffer[i] = '\0';
	return i;
}

void IncrementMannVsMachineWaveClassCount(const char[] iszClassIconName, int iFlags)
{
	int obj = FindEntityByClassname(MaxClients + 1, "tf_objective_resource");
	if (obj == -1)
		return;
	
	int i = 0;
	for (i = 0; i < GetEntPropArraySize(obj, Prop_Send, "m_iszMannVsMachineWaveClassNames"); ++i)
	{
		char waveClassName[64];
		if (GetEntPropString(obj, Prop_Send, "m_iszMannVsMachineWaveClassNames", waveClassName, sizeof(waveClassName), i) && StrEqual(waveClassName, iszClassIconName) && (GetEntProp(obj, Prop_Send, "m_nMannVsMachineWaveClassFlags", _, i) & iFlags))
		{
			SetEntProp(obj, Prop_Send, "m_nMannVsMachineWaveClassCounts", GetEntProp(obj, Prop_Send, "m_nMannVsMachineWaveClassCounts", _, i) + 1, _, i);
			
			if (GetEntProp(obj, Prop_Send, "m_nMannVsMachineWaveClassCounts", _, i) <= 0)
			{
				SetEntProp(obj, Prop_Send, "m_nMannVsMachineWaveClassCounts", 1, _, i);
			}
			
			return;
		}
	}
	
	for (i = 0; i < GetEntPropArraySize(obj, Prop_Send, "m_iszMannVsMachineWaveClassNames2"); ++i)
	{
		char waveClassName[64];
		if (GetEntPropString(obj, Prop_Send, "m_iszMannVsMachineWaveClassNames2", waveClassName, sizeof(waveClassName), i) && StrEqual(waveClassName, iszClassIconName) && (GetEntProp(obj, Prop_Send, "m_nMannVsMachineWaveClassFlags2", _, i) & iFlags))
		{
			SetEntProp(obj, Prop_Send, "m_nMannVsMachineWaveClassCounts2", GetEntProp(obj, Prop_Send, "m_nMannVsMachineWaveClassCounts2", _, i) + 1, _, i);
			
			if (GetEntProp(obj, Prop_Send, "m_nMannVsMachineWaveClassCounts2", _, i) <= 0)
			{
				SetEntProp(obj, Prop_Send, "m_nMannVsMachineWaveClassCounts2", 1, _, i);
			}
			
			return;
		}
	}
}

void SetMannVsMachineWaveClassActive(const char[] iszClassIconName, bool bActive = true)
{
	int obj = FindEntityByClassname(MaxClients + 1, "tf_objective_resource");
	if (obj == -1)
		return;
	
	for (int i = 0; i < GetEntPropArraySize(obj, Prop_Send, "m_iszMannVsMachineWaveClassNames"); ++i)
	{
		char waveClassName[64];
		if (GetEntPropString(obj, Prop_Send, "m_iszMannVsMachineWaveClassNames", waveClassName, sizeof(waveClassName), i) && StrEqual(waveClassName, iszClassIconName))
		{
			SetEntProp(obj, Prop_Send, "m_bMannVsMachineWaveClassActive", bActive, _, i);
			return;
		}
	}
	
	for (int i = 0; i < GetEntPropArraySize(obj, Prop_Send, "m_iszMannVsMachineWaveClassNames2"); ++i)
	{
		char waveClassName[64];
		if (GetEntPropString(obj, Prop_Send, "m_iszMannVsMachineWaveClassNames2", waveClassName, sizeof(waveClassName), i) && StrEqual(waveClassName, iszClassIconName))
		{
			SetEntProp(obj, Prop_Send, "m_bMannVsMachineWaveClassActive2", bActive, _, i);
			return;
		}
	}
}

bool IsSpaceToSpawnHere(const float where[3])
{
	// make sure a player will fit here
	const float bloat = 5.0;
	
	float mins[3], maxs[3];
	SubtractVectors(VEC_HULL_MIN, { bloat, bloat, 0.0 }, mins);
	AddVectors(VEC_HULL_MAX, { bloat, bloat, bloat }, maxs);
	
	TR_TraceHull(where, where, mins, maxs, MASK_SOLID | CONTENTS_PLAYERCLIP);
	
	return TR_GetFraction() >= 1.0;
}

float[] Vector(float x, float y, float z)
{
	float vec[3];
	vec[0] = x;
	vec[1] = y;
	vec[2] = z;
	return vec;
}
