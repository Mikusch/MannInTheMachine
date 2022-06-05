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

any Max(any a, any b)
{
	return a >= b ? a : b;
}

bool GameRules_IsMannVsMachineMode()
{
	return view_as<bool>(GameRules_GetProp("m_bPlayingMannVsMachine"));
}

void TFGameRules_BroadcastSound(int iTeam, const char[] sound, int iAdditionalSoundFlags = 0)
{
	Event event = CreateEvent("teamplay_broadcast_audio");
	if (event)
	{
		event.SetInt("team", iTeam);
		event.SetString("sound", sound);
		event.SetInt("additional_flags", iAdditionalSoundFlags);
		event.Fire();
	}
}

bool TFGameRules_PlayThrottledAlert(int iTeam, const char[] sound, float fDelayBeforeNext)
{
	static float m_flNewThrottledAlertTime = 0.0;
	
	if (m_flNewThrottledAlertTime <= GetGameTime())
	{
		TFGameRules_BroadcastSound(iTeam, sound);
		m_flNewThrottledAlertTime = GetGameTime() + fDelayBeforeNext;
		return true;
	}
	
	return false;
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

int CreateRobotItem(int player, int defindex)
{
	Handle hItem = TF2Items_CreateItem(PRESERVE_ATTRIBUTES | FORCE_GENERATION);
	
	char classname[64];
	TF2Econ_GetItemClassName(defindex, classname, sizeof(classname));
	TF2Econ_TranslateWeaponEntForClass(classname, sizeof(classname), TF2_GetPlayerClass(player));
	
	TF2Items_SetClassname(hItem, classname);
	TF2Items_SetItemIndex(hItem, defindex);
	TF2Items_SetQuality(hItem, 0);
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

int GetRobotToSpawn(bool bMiniBoss)
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
		
		if (Player(client).HasPreference(PREF_NO_SPAWNING))
			continue;
		
		if (bMiniBoss && Player(client).HasPreference(PREF_NO_GIANT))
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
			Player(client).m_invaderPriority = 0;
			
			// this player is becoming a miniboss
			if (bMiniBoss)
			{
				Player(client).m_bWasMiniBoss = true;
			}
		}
		else
		{
			// every player who didn't get picked gets a priority point
			Player(client).m_invaderPriority++;
		}
	}
	
	delete players;
	
	// check whether every invader has been a miniboss at least once, then reset everyone
	int playerCount = 0, miniBossCount = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		// check active and waiting invaders
		if (TF2_GetClientTeam(client) != TFTeam_Spectator || TF2_GetClientTeam(client) != TFTeam_Invaders)
			continue;
		
		playerCount++;
		
		if (Player(client).m_bWasMiniBoss)
		{
			miniBossCount++;
		}
	}
	
	// every client has been miniboss at least once, reset everyone
	if (playerCount == miniBossCount)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client))
				continue;
			
			if (TF2_GetClientTeam(client) != TFTeam_Spectator || TF2_GetClientTeam(client) != TFTeam_Invaders)
				continue;
			
			Player(client).m_bWasMiniBoss = false;
		}
	}
	
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
	
	int c = 0;
	
	// sort by priority
	if (c == 0)
	{
		c = Compare(Player(client2).m_invaderPriority, Player(client1).m_invaderPriority);
	}
	
	// sort by players who have not been miniboss yet
	if (c == 0)
	{
		c = Compare(Player(client1).m_bWasMiniBoss, Player(client2).m_bWasMiniBoss);
	}
	
	return c;
}

bool IsRangeLessThan(int client1, int client2, float range)
{
	float origin1[3], origin2[3];
	GetClientAbsOrigin(client1, origin1);
	GetClientAbsOrigin(client2, origin2);
	return GetVectorDistance(origin1, origin2) < range;
}

bool IsDistanceBetweenLessThan(int client, const float target[3], float range)
{
	float origin[3];
	GetClientAbsOrigin(client, origin);
	
	SubtractVectors(origin, target, origin);
	
	return GetVectorLength(origin) < range;
}

// Return true if a weapon has no obstructions along the line between the given points
bool IsLineOfFireClear2(int client, const float from[3], const float to[3])
{
	TR_TraceRayFilter(from, to, MASK_SOLID_BRUSHONLY, RayType_EndPoint, TraceEntityFilter_IgnoreActorsAndFriendlyCombatItems, GetClientTeam(client));
	return !TR_DidHit();
}

// Return true if a weapon has no obstructions along the line from our eye to the given position
bool IsLineOfFireClear(int client, const float where[3])
{
	float pos[3];
	GetClientEyePosition(client, pos);
	
	return IsLineOfFireClear2(client, pos, where);
}

// Return true if a weapon has no obstructions along the line between the given point and entity
bool IsLineOfFireClear4(int client, const float from[3], int who)
{
	float center[3];
	CBaseEntity(who).WorldSpaceCenter(center);
	
	TR_TraceRayFilter(from, center, MASK_SOLID_BRUSHONLY, RayType_EndPoint, TraceEntityFilter_IgnoreActorsAndFriendlyCombatItems, GetClientTeam(client));
	
	return !TR_DidHit() || TR_GetEntityIndex() == who;
}

// Return true if a weapon has no obstructions along the line from our eye to the given entity
bool IsLineOfFireClear3(int client, int who)
{
	float pos[3];
	GetClientEyePosition(client, pos);
	
	return IsLineOfFireClear4(client, pos, who);
}

bool TraceEntityFilter_IgnoreActorsAndFriendlyCombatItems(int entity, int contentsMask, int m_iIgnoreTeam)
{
	if (CBaseEntity(entity).MyCombatCharacterPointer())
		return false;
	
	if (SDKCall_IsCombatItem(entity))
	{
		if (GetEntProp(entity, Prop_Data, "m_iTeamNum") == m_iIgnoreTeam)
			return false;
	}
	
	return true;
}

void TE_TFParticleEffect(const char[] name, const float vecOrigin[3] = NULL_VECTOR,
	const float vecStart[3] = NULL_VECTOR, const float vecAngles[3] = NULL_VECTOR,
	int entity = -1, ParticleAttachment_t attachType = PATTACH_ABSORIGIN,
	int attachPoint = -1, bool bResetParticles = false)
{
	int particleTable, particleIndex;
	
	if ((particleTable = FindStringTable("ParticleEffectNames")) == INVALID_STRING_TABLE)
	{
		ThrowError("Could not find string table: ParticleEffectNames");
	}
	
	if ((particleIndex = FindStringIndex(particleTable, name)) == INVALID_STRING_INDEX)
	{
		ThrowError("Could not find particle index: %s", name);
	}
	
	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", vecOrigin[0]);
	TE_WriteFloat("m_vecOrigin[1]", vecOrigin[1]);
	TE_WriteFloat("m_vecOrigin[2]", vecOrigin[2]);
	TE_WriteFloat("m_vecStart[0]", vecStart[0]);
	TE_WriteFloat("m_vecStart[1]", vecStart[1]);
	TE_WriteFloat("m_vecStart[2]", vecStart[2]);
	TE_WriteVector("m_vecAngles", vecAngles);
	TE_WriteNum("m_iParticleSystemIndex", particleIndex);
	
	if (entity != -1)
	{
		TE_WriteNum("entindex", entity);
	}
	
	if (attachType != PATTACH_ABSORIGIN)
	{
		TE_WriteNum("m_iAttachType", view_as<int>(attachType));
	}
	
	if (attachPoint != -1)
	{
		TE_WriteNum("m_iAttachmentPointIndex", attachPoint);
	}
	
	TE_WriteNum("m_bResetParticles", bResetParticles ? 1 : 0);
	
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

int GetCurrentWaveIndex()
{
	int stats = FindEntityByClassname(MaxClients + 1, "tf_mann_vs_machine_stats");
	return GetEntProp(stats, Prop_Send, "m_iCurrentWaveIdx");
}

Address GetPlayerShared(int client)
{
	Address offset = view_as<Address>(GetEntSendPropOffs(client, "m_Shared", true));
	return GetEntityAddress(client) + offset;
}
