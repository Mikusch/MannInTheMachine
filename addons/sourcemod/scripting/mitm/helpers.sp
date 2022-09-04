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
			delete itemList;
			return itemdef;
		}
	}
	delete itemList;
	
	return TF_ITEMDEF_DEFAULT;
}

void IncrementMannVsMachineWaveClassCount(any iszClassIconName, int iFlags)
{
	int objective = TFObjectiveResource();
	
	for (int i = 0; i < GetEntPropArraySize(objective, Prop_Send, "m_iszMannVsMachineWaveClassNames"); ++i)
	{
		if (GetEntData(objective, FindSendPropInfo("CTFObjectiveResource", "m_iszMannVsMachineWaveClassNames") + (i * 4)) == iszClassIconName && (GetEntProp(objective, Prop_Send, "m_nMannVsMachineWaveClassFlags", _, i) & iFlags))
		{
			SetEntProp(objective, Prop_Send, "m_nMannVsMachineWaveClassCounts", GetEntProp(objective, Prop_Send, "m_nMannVsMachineWaveClassCounts", _, i) + 1, _, i);
			
			if (GetEntProp(objective, Prop_Send, "m_nMannVsMachineWaveClassCounts", _, i) <= 0)
			{
				SetEntProp(objective, Prop_Send, "m_nMannVsMachineWaveClassCounts", 1, _, i);
			}
			
			return;
		}
	}
	
	for (int i = 0; i < GetEntPropArraySize(objective, Prop_Send, "m_iszMannVsMachineWaveClassNames2"); ++i)
	{
		if (GetEntData(objective, FindSendPropInfo("CTFObjectiveResource", "m_iszMannVsMachineWaveClassNames2") + (i * 4)) == iszClassIconName && (GetEntProp(objective, Prop_Send, "m_nMannVsMachineWaveClassFlags2", _, i) & iFlags))
		{
			SetEntProp(objective, Prop_Send, "m_nMannVsMachineWaveClassCounts2", GetEntProp(objective, Prop_Send, "m_nMannVsMachineWaveClassCounts2", _, i) + 1, _, i);
			
			if (GetEntProp(objective, Prop_Send, "m_nMannVsMachineWaveClassCounts2", _, i) <= 0)
			{
				SetEntProp(objective, Prop_Send, "m_nMannVsMachineWaveClassCounts2", 1, _, i);
			}
			
			return;
		}
	}
}

void SetMannVsMachineWaveClassActive(any iszClassIconName, bool bActive = true)
{
	int objective = TFObjectiveResource();
	
	for (int i = 0; i < GetEntPropArraySize(objective, Prop_Send, "m_iszMannVsMachineWaveClassNames"); ++i)
	{
		if (GetEntData(objective, FindSendPropInfo("CTFObjectiveResource", "m_iszMannVsMachineWaveClassNames") + (i * 4)) == iszClassIconName)
		{
			SetEntProp(objective, Prop_Send, "m_bMannVsMachineWaveClassActive", bActive, _, i);
			return;
		}
	}
	
	for (int i = 0; i < GetEntPropArraySize(objective, Prop_Send, "m_iszMannVsMachineWaveClassNames2"); ++i)
	{
		if (GetEntData(objective, FindSendPropInfo("CTFObjectiveResource", "m_iszMannVsMachineWaveClassNames2") + (i * 4)) == iszClassIconName)
		{
			SetEntProp(objective, Prop_Send, "m_bMannVsMachineWaveClassActive2", bActive, _, i);
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

ArrayList GetInvaderQueue(bool bMiniBoss = false)
{
	ArrayList queue = new ArrayList();
	
	// collect valid players
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (IsClientSourceTV(client))
			continue;
		
		if (TF2_GetClientTeam(client) != TFTeam_Spectator)
			continue;
		
		if (Player(client).HasPreference(PREF_DISABLE_SPAWNING))
			continue;
		
		if (bMiniBoss && Player(client).HasPreference(PREF_DISABLE_GIANT))
			continue;
		
		queue.Push(client);
	}
	
	// sort players by priority
	queue.SortCustom(SortPlayersByPriority);
	
	return queue;
}

int GetRobotToSpawn(bool bMiniBoss)
{
	ArrayList queue = GetInvaderQueue(bMiniBoss);
	int priorityClient = -1;
	for (int i = 0; i < queue.Length; i++)
	{
		int client = queue.Get(i);
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
	delete queue;
	
	// check whether every invader has been a miniboss at least once, then reset everyone
	int playerCount = 0, miniBossCount = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!Player(client).IsInvader())
			continue;
		
		if (Player(client).HasPreference(PREF_DISABLE_GIANT))
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
			
			if (!Player(client).IsInvader())
				continue;
			
			Player(client).m_bWasMiniBoss = false;
		}
	}
	
	return priorityClient;
}

int CreateEntityGlow(int entity)
{
	int glow = CreateEntityByName("tf_taunt_prop");
	if (glow != -1)
	{
		char iszModel[PLATFORM_MAX_PATH];
		
		if (HasEntProp(entity, Prop_Send, "m_iszCustomModel"))
		{
			GetEntPropString(entity, Prop_Send, "m_iszCustomModel", iszModel, sizeof(iszModel));
		}
		
		if (iszModel[0] == EOS)
		{
			// fall back to default model
			GetEntPropString(entity, Prop_Data, "m_ModelName", iszModel, sizeof(iszModel));
		}
		
		SetEntityModel(glow, iszModel);
		
		if (DispatchSpawn(glow))
		{
			SetEntPropEnt(glow, Prop_Data, "m_hEffectEntity", entity);
			SetEntProp(glow, Prop_Send, "m_bGlowEnabled", true);
			
			SetEntityRenderMode(glow, RENDER_TRANSCOLOR);
			SetEntityRenderColor(glow, 0, 0, 0, 0);
			
			int fEffects = GetEntProp(glow, Prop_Send, "m_fEffects");
			SetEntProp(glow, Prop_Send, "m_fEffects", fEffects | EF_BONEMERGE | EF_NOSHADOW | EF_NORECEIVESHADOW);
			
			SetVariantString("!activator");
			AcceptEntityInput(glow, "SetParent", entity);
			
			SDKHook(glow, SDKHook_SetTransmit, SDKHookCB_EntityGlow_SetTransmit);
			
			return glow;
		}
		else
		{
			RemoveEntity(glow);
		}
	}
	
	return -1;
}

void RemoveEntityGlow(int entity)
{
	// Remove any glows attached to us
	int prop = MaxClients + 1;
	while ((prop = FindEntityByClassname(prop, "tf_taunt_prop")) != -1)
	{
		if (GetEntPropEnt(prop, Prop_Data, "m_hEffectEntity") == entity)
		{
			RemoveEntity(prop);
		}
	}
}

int Compare(any val1, any val2)
{
	if (val1 > val2)
		return 1;
	else if (val1 < val2)
		return -1;
	
	return 0;
}

int SortPlayersByPriority(int index1, int index2, Handle array, Handle hndl)
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

void CalculateMeleeDamageForce(const float vecMeleeDir[3], float flDamage, float flScale, float vecForce[3])
{
	// Calculate an impulse large enough to push a 75kg man 4 in/sec per point of damage
	float flForceScale = flDamage * (75 * 4);
	NormalizeVector(vecMeleeDir, vecForce);
	ScaleVector(vecForce, flForceScale);
	ScaleVector(vecForce, phys_pushscale.FloatValue);
	ScaleVector(vecForce, flScale);
}

int FixedUnsigned16(float value, int scale)
{
	int output;
	
	output = RoundToFloor(value * float(scale));
	if (output < 0)
	{
		output = 0;
	}
	if (output > 0xFFFF)
	{
		output = 0xFFFF;
	}
	
	return output;
}

void UTIL_ScreenFade(int player, const int color[4], float fadeTime, float fadeHold, int flags)
{
	BfWrite bf = UserMessageToBfWrite(StartMessageOne("Fade", player, USERMSG_RELIABLE));
	if (bf != null)
	{
		bf.WriteShort(FixedUnsigned16(fadeTime, 1 << SCREENFADE_FRACBITS));
		bf.WriteShort(FixedUnsigned16(fadeHold, 1 << SCREENFADE_FRACBITS));
		bf.WriteShort(flags);
		bf.WriteByte(color[0]);
		bf.WriteByte(color[1]);
		bf.WriteByte(color[2]);
		bf.WriteByte(color[3]);
		
		EndMessage();
	}
}

const float MAX_SHAKE_AMPLITUDE = 16.0;
void UTIL_ScreenShake(const float center[3], float amplitude, float frequency, float duration, float radius, ShakeCommand_t eCommand, bool bAirShake = false)
{
	float localAmplitude;
	
	if (amplitude > MAX_SHAKE_AMPLITUDE)
	{
		amplitude = MAX_SHAKE_AMPLITUDE;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || (!bAirShake && (eCommand == SHAKE_START) && !(GetEntityFlags(i) & FL_ONGROUND)))
		{
			continue;
		}
		
		CBaseCombatCharacter cb = CBaseCombatCharacter(i);
		float playerCenter[3];
		cb.WorldSpaceCenter(playerCenter);
		
		localAmplitude = ComputeShakeAmplitude(center, playerCenter, amplitude, radius);
		
		// This happens if the player is outside the radius, in which case we should ignore 
		// all commands
		if (localAmplitude < 0)
		{
			continue;
		}
		
		TransmitShakeEvent(i, localAmplitude, frequency, duration, eCommand);
	}
}

float ComputeShakeAmplitude(const float center[3], const float shake[3], float amplitude, float radius)
{
	if (radius <= 0)
	{
		return amplitude;
	}
	
	float localAmplitude = -1.0;
	float delta[3];
	SubtractVectors(center, shake, delta);
	float distance = GetVectorLength(delta);
	
	if (distance <= radius)
	{
		// Make the amplitude fall off over distance
		float perc = 1.0 - (distance / radius);
		localAmplitude = amplitude * perc;
	}
	
	return localAmplitude;
}

void TransmitShakeEvent(int player, float localAmplitude, float frequency, float duration, ShakeCommand_t eCommand)
{
	if ((localAmplitude > 0.0) || (eCommand == SHAKE_STOP))
	{
		if (eCommand == SHAKE_STOP)
		{
			localAmplitude = 0.0;
		}
		
		BfWrite msg = UserMessageToBfWrite(StartMessageOne("Shake", player, USERMSG_RELIABLE));
		if (msg != null)
		{
			msg.WriteByte(view_as<int>(eCommand));
			msg.WriteFloat(localAmplitude);
			msg.WriteFloat(frequency);
			msg.WriteFloat(duration);
			
			EndMessage();
		}
	}
}

bool IsEntityClient(int client)
{
	return (0 < client <= MaxClients);
}

bool FClassnameIs(int entity, const char[] szClassname)
{
	char m_iClassname[64];
	return GetEntityClassname(entity, m_iClassname, sizeof(m_iClassname)) && StrEqual(szClassname, m_iClassname);
}

int FindTeleporterHintForPlayer(int player)
{
	int hint = MaxClients + 1;
	while ((hint = FindEntityByClassname(hint, "bot_hint_engineer_nest")) != -1)
	{
		int owner = GetEntPropEnt(hint, Prop_Send, "m_hOwnerEntity");
		if (owner == player)
		{
			return SDKCall_GetTeleporterHint(hint);
		}
	}
	
	return -1;
}

int FindSentryHintForPlayer(int player)
{
	int hint = MaxClients + 1;
	while ((hint = FindEntityByClassname(hint, "bot_hint_engineer_nest")) != -1)
	{
		int owner = GetEntPropEnt(hint, Prop_Send, "m_hOwnerEntity");
		if (owner == player)
		{
			return SDKCall_GetSentryHint(hint);
		}
	}
	
	return -1;
}

bool HasTheFlag(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hItem") != -1;
}

void CreateMsgDialog(int client, const char[] title, int level = cellmax, int time = 10, int color[4] = { 255, 255, 255, 255 } )
{
	KeyValues kv = new KeyValues("Dialog", "title", title);
	kv.SetNum("level", level);
	kv.SetNum("time", time);
	kv.SetColor4("color", color);
	CreateDialog(client, kv, DialogType_Msg);
	delete kv;
}

void ShowAnnotation(int client, int id, const char[] text, int target = 0, const float worldPos[3] = ZERO_VECTOR, float lifeTime = 10.0, const char[] sound = "ui/hint.wav", bool showDistance = true, bool showEffect = true)
{
	if (Player(client).HasPreference(PREF_DISABLE_ANNOTATIONS))
		return;
	
	Event event = CreateEvent("show_annotation");
	if (event)
	{
		event.SetString("text", text);
		event.SetInt("id", id);
		event.SetFloat("worldPosX", worldPos[0]);
		event.SetFloat("worldPosY", worldPos[1]);
		event.SetFloat("worldPosZ", worldPos[2]);
		event.SetInt("follow_entindex", target);
		event.SetFloat("lifetime", lifeTime);
		event.SetString("play_sound", sound);
		event.SetBool("show_distance", showDistance);
		event.SetBool("show_effect", showEffect);
		event.FireToClient(client);
	}
}

void HideAnnotation(int client, int id)
{
	Event event = CreateEvent("hide_annotation");
	if (event)
	{
		event.SetInt("id", id);
		event.FireToClient(client);
	}
}

void ShowGateBotAnnotation(int client)
{
	// show an annotation for gate bots
	if (Player(client).HasTag("bot_gatebot"))
	{
		int trigger = MaxClients + 1;
		while ((trigger = FindEntityByClassname(trigger, "trigger_*")) != -1)
		{
			// only area capture triggers
			if (!HasEntProp(trigger, Prop_Data, "CTriggerAreaCaptureCaptureThink"))
				continue;
			
			if (GetEntProp(trigger, Prop_Data, "m_bDisabled"))
				continue;
			
			char iszCapPointName[64];
			GetEntPropString(trigger, Prop_Data, "m_iszCapPointName", iszCapPointName, sizeof(iszCapPointName));
			
			int point = MaxClients + 1;
			while ((point = FindEntityByClassname(point, "team_control_point")) != -1)
			{
				// locked, requiring preceding points, etc.
				if (!SDKCall_TeamMayCapturePoint(TF2_GetClientTeam(client), GetEntProp(point, Prop_Data, "m_iPointIndex")))
					continue;
				
				char iName[64];
				GetEntPropString(point, Prop_Data, "m_iName", iName, sizeof(iName));
				
				if (StrEqual(iszCapPointName, iName))
				{
					char iszPrintName[64];
					GetEntPropString(point, Prop_Data, "m_iszPrintName", iszPrintName, sizeof(iszPrintName));
					
					float center[3];
					CBaseEntity(trigger).WorldSpaceCenter(center);
					
					char text[64];
					Format(text, sizeof(text), "%T", "Invader_CaptureGate_Annotation", client, iszPrintName);
					
					ShowAnnotation(client, MITM_HINT_MASK | client, text, 0, center, mitm_annotation_lifetime.FloatValue, "coach/coach_go_here.wav");
					return;
				}
			}
		}
	}
}

void LockWeapon(int client, int weapon, int &buttons)
{
	TF2Attrib_SetByName(weapon, "no_attack", 1.0);
	TF2Attrib_SetByName(weapon, "provide on active", 1.0);
	
	// no_attack prevents class special skills, do them manually
	if (buttons & IN_ATTACK2)
	{
		// auto behavior
		if (TF2Util_GetWeaponID(weapon) == TF_WEAPON_GRENADELAUNCHER || GetEntProp(client, Prop_Send, "m_bShieldEquipped"))
		{
			SDKCall_DoClassSpecialSkill(client);
		}
		// semi-auto behaviour
		else
		{
			if (view_as<bool>(GetEntData(weapon, GetOffset("CTFWeaponBase::m_bInAttack2"), 1)) == false)
			{
				SDKCall_DoClassSpecialSkill(client);
				SetEntData(weapon, GetOffset("CTFWeaponBase::m_bInAttack2"), true, 1);
			}
		}
	}
	
	buttons &= ~IN_ATTACK;
	buttons &= ~IN_ATTACK2;
}

void UnlockWeapon(int weapon)
{
	TF2Attrib_RemoveByName(weapon, "no_attack");
	TF2Attrib_RemoveByName(weapon, "provide on active");
}

bool IsBaseObject(int entity)
{
	return HasEntProp(entity, Prop_Data, "CBaseObjectUpgradeThink");
}

void PrintKeyHintText(int client, const char[] format, any...)
{
	char buffer[256];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	
	BfWrite bf = UserMessageToBfWrite(StartMessageOne("KeyHintText", client));
	bf.WriteByte(1);	// One message
	bf.WriteString(buffer);
	EndMessage();
}

bool ArrayListEquals(ArrayList list1, ArrayList list2)
{
	if (list1.Length != list2.Length)
		return false;
	
	for (int i = 0; i < list1.Length; i++)
	{
		for (int j = 0; j < list1.BlockSize; j++)
		{
			if (list1.Get(i, j) != list2.Get(i, j))
				return false;
		}
	}
	
	return true;
}

bool StrPtrEquals(Address psz1, Address psz2)
{
	if (psz1 == psz2)
		return true;
	
	if (!psz1 || !psz2)
		return false;
	
	// should be big enough for our use case
	char sz1[64], sz2[64];
	PtrToString(psz1, sz1, sizeof(sz1));
	PtrToString(psz2, sz2, sizeof(sz2));
	
	return strcmp(sz1, sz2, false) == 0;
}
