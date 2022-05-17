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

bool GameRules_IsMannVsMachineMode()
{
	return view_as<bool>(GameRules_GetProp("m_bPlayingMannVsMachine"));
}

void SetModelScale(int entity, float scale, float duration = 0.0)
{
	float vecScale[3];
	vecScale[0] = scale;
	vecScale[1] = duration;
	
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
	int defindex = GetItemDefinitionByName(pszItemName);
	
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
			if (wearableDefindex == DEFINDEX_UNDEFINED)
				continue;
			
			int wearableRegionMask = TF2Econ_GetItemEquipRegionMask(wearableDefindex);
			
			if (wearableRegionMask & newItemRegionMask)
			{
				TF2_RemoveWearable(player, pWearable);
			}
		}
	}
	else
	{
		int pEntity = TF2Util_GetPlayerLoadoutEntity(player, slot);
		if (pEntity != -1)
		{
			RemovePlayerItem(player, pEntity);
			RemoveEntity(pEntity);
		}
	}
	
	int item = CreateAndEquipItem(player, defindex);
	
	if (TF2Util_IsEntityWearable(item))
		TF2Util_EquipPlayerWearable(player, item);
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

int GetItemDefinitionByName(const char[] name)
{
	if (!name[0])
	{
		return TF_ITEMDEF_DEFAULT;
	}
	
	ArrayList itemList = TF2Econ_GetItemList();
	for (int i, nItems = itemList.Length; i < nItems; i++)
	{
		int itemdef = itemList.Get(i);
		
		char itemName[64];
		TF2Econ_GetItemName(itemdef, itemName, sizeof(itemName));
		
		if (StrEqual(itemName, name, false))
		{
			return itemdef;
		}
	}
	delete itemList;
	
	return TF_ITEMDEF_DEFAULT;
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
	{
		if ((buffer[i] = Deref(string_t + view_as<Address>(i), NumberType_Int8)) == EOS)
			return i;
	}
	
	buffer[i] = EOS;
	return i;
}

void IncrementMannVsMachineWaveClassCount(const char[] iszClassIconName, int iFlags)
{
	int obj = TFObjectiveResource();
	
	for (int i = 0; i < GetEntPropArraySize(obj, Prop_Send, "m_iszMannVsMachineWaveClassNames"); ++i)
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
	
	for (int i = 0; i < GetEntPropArraySize(obj, Prop_Send, "m_iszMannVsMachineWaveClassNames2"); ++i)
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
	int obj = TFObjectiveResource();
	
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

int GetPopulator()
{
	return FindEntityByClassname(MaxClients + 1, "info_populator");
}

int TFObjectiveResource()
{
	return FindEntityByClassname(MaxClients + 1, "tf_objective_resource");
}

TFTeam GetEnemyTeam(TFTeam team)
{
	switch (team)
	{
		case TFTeam_Red: { return TFTeam_Blue; }
		case TFTeam_Blue: { return TFTeam_Red; }
		default: { return team; }
	}
}

int GetRobotToSpawn()
{
	ArrayList players = new ArrayList(MaxClients);
	
	// collect valid players
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (IsFakeClient(client))
			continue;
		
		if (TF2_GetClientTeam(client) != TFTeam_Spectator)
			continue;
		
		players.Push(client);
	}
	
	// sort players by priority
	players.SortCustom(SortPlayersByPriority);
	
	int priorityClient = -1;
	for (int i = 0; i < players.Length; i++)
	{
		int client = players.Get(i);
		if (i == 0)
		{
			// store the player and reset priority
			priorityClient = client;
			Player(client).m_iPriority = 0;
		}
		else
		{
			// every player who didn't get picked gets a priority point
			Player(client).m_iPriority++;
		}
	}
	
	delete players;
	return priorityClient;
}

int Compare(any val1, any val2)
{
	if (val1 > val2)
		return 1;
	else if (val1 < val2)
		return -1;
	
	return 0;
}

public int SortPlayersByPriority(int index1, int index2, Handle array, Handle hndl)
{
	ArrayList list = view_as<ArrayList>(array);
	int client1 = list.Get(index1);
	int client2 = list.Get(index2);
	
	return Compare(Player(client2).m_iPriority, Player(client1).m_iPriority);
}

bool IsRangeLessThan(int client1, int client2, float range)
{
	float origin1[3], origin2[3];
	GetClientAbsOrigin(client1, origin1);
	GetClientAbsOrigin(client2, origin2);
	return GetVectorDistance(origin1, origin2) < range;
}

int GetParticleSystemIndex(const char[] szParticleSystemName)
{
	int tableidx = FindStringTable("ParticleEffectNames");
	int numstrings = GetStringTableNumStrings(tableidx);
	
	for (int stringidx = 0; stringidx < numstrings; stringidx++)
	{
		char str[64];
		ReadStringTable(tableidx, stringidx, str, sizeof(str));
		
		if (StrEqual(str, szParticleSystemName))
		{
			return stringidx;
		}
	}
	
	// This is the invalid string index
	return 0;
}

void DispatchParticleEffect(const char[] name, ParticleAttachment_t attachType, int entity, const char[] attachmentName, bool resetAllParticlesOnEntity = false)
{
	TE_Start("TFParticleEffect");
	TE_WriteNum("m_iParticleSystemIndex", GetParticleSystemIndex(name));
	TE_WriteNum("m_iAttachType", view_as<int>(attachType));
	TE_WriteNum("entindex", entity);
	TE_WriteNum("m_iAttachmentPointIndex", LookupEntityAttachment(entity, attachmentName));
	TE_WriteNum("m_bResetParticles", resetAllParticlesOnEntity);
	TE_SendToAll();
}

void HaveAllPlayersSpeakConceptIfAllowed(const char[] concept, TFTeam team)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (TF2_GetClientTeam(client) != team)
			continue;
		
		SetVariantString(concept);
		AcceptEntityInput(client, "SpeakResponseConcept");
		AcceptEntityInput(client, "ClearContext");
	}
}

bool IsAreaValidForWanderingPopulation(CTFNavArea area)
{
	if (area.HasAttributeTF(BLOCKED | RED_SPAWN_ROOM | BLUE_SPAWN_ROOM | NO_SPAWNING | RESCUE_CLOSET))
		return false;
	
	return true;
}

bool IsAreaPotentiallyVisibleToTeam(CNavArea area, TFTeam team)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (TF2_GetClientTeam(client) != team)
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		CNavArea from = CBaseCombatCharacter(client).GetLastKnownArea();
		
		if (from && from.IsPotentiallyVisible(area))
		{
			return true;
		}
	}
	
	return false;
}

float[] Vector(float x, float y, float z)
{
	float vec[3];
	vec[0] = x;
	vec[1] = y;
	vec[2] = z;
	return vec;
}

any Min(any a, any b)
{
	return a <= b ? a : b;
}
