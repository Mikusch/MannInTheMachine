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

static DynamicHook g_DHookEventKilled;
static DynamicHook g_DHookShouldGib;
static DynamicHook g_DHookEntSelectSpawnPoint;
static DynamicHook g_DHookPassesFilterImpl;
static DynamicHook g_DHookPickUp;
static DynamicHook g_DHookClientConnected;

static ArrayList m_justSpawnedVector;

static int g_InternalSpawnPoint = INVALID_ENT_REFERENCE;
static SpawnLocationResult s_spawnLocationResult = SPAWN_LOCATION_NOT_FOUND;

// CMissionPopulator
static CountdownTimer m_cooldownTimer;
static int s_activeMissionMembers;
static int s_nSniperCount;

// Engineer Teleporter
static CBaseEntity s_lastTeleporter;
static float s_flLastTeleportTime;

void DHooks_Initialize(GameData gamedata)
{
	m_justSpawnedVector = new ArrayList(MaxClients);
	
	CreateDynamicDetour(gamedata, "CTFGCServerSystem::PreClientUpdate", DHookCallback_PreClientUpdate_Pre, DHookCallback_PreClientUpdate_Post);
	CreateDynamicDetour(gamedata, "CPopulationManager::AllocateBots", DHookCallback_AllocateBots_Pre);
	CreateDynamicDetour(gamedata, "CPopulationManager::RestoreCheckpoint", DHookCallback_RestoreCheckpoint_Pre);
	CreateDynamicDetour(gamedata, "CTFBotSpawner::Spawn", DHookCallback_Spawn_Pre);
	CreateDynamicDetour(gamedata, "CPopulationManager::Update", DHookCallback_PopulationManagerUpdate_Pre, DHookCallback_PopulationManagerUpdate_Post);
	CreateDynamicDetour(gamedata, "CWaveSpawnPopulator::Update", _, DHookCallback_WaveSpawnPopulatorUpdate_Post);
	CreateDynamicDetour(gamedata, "CMissionPopulator::UpdateMission", DHookCallback_MissionPopulatorUpdateMission_Pre, DHookCallback_MissionPopulatorUpdateMission_Post);
	CreateDynamicDetour(gamedata, "CMissionPopulator::UpdateMissionDestroySentries", DHookCallback_UpdateMissionDestroySentries_Pre);
	CreateDynamicDetour(gamedata, "CPointPopulatorInterface::InputChangeBotAttributes", DHookCallback_InputChangeBotAttributes_Pre);
	CreateDynamicDetour(gamedata, "CTFGameRules::GetTeamAssignmentOverride", DHookCallback_GetTeamAssignmentOverride_Pre, DHookCallback_GetTeamAssignmentOverride_Post);
	CreateDynamicDetour(gamedata, "CTFPlayer::GetLoadoutItem", DHookCallback_GetLoadoutItem_Pre, DHookCallback_GetLoadoutItem_Post);
	CreateDynamicDetour(gamedata, "CTFPlayer::CheckInstantLoadoutRespawn", DHookCallback_CheckInstantLoadoutRespawn_Pre);
	CreateDynamicDetour(gamedata, "CTFPlayer::ShouldForceAutoTeam", DHookCallback_ShouldForceAutoTeam_Pre);
	CreateDynamicDetour(gamedata, "CTFPlayer::DoClassSpecialSkill", DHookCallback_DoClassSpecialSkill_Pre);
	CreateDynamicDetour(gamedata, "CBaseObject::FindSnapToBuildPos", DHookCallback_FindSnapToBuildPos_Pre, DHookCallback_FindSnapToBuildPos_Post);
	CreateDynamicDetour(gamedata, "CSpawnLocation::FindSpawnLocation", _, DHookCallback_FindSpawnLocation_Post);
	CreateDynamicDetour(gamedata, "DoTeleporterOverride", _, DHookCallback_DoTeleporterOverride_Post);
	CreateDynamicDetour(gamedata, "OnBotTeleported", DHookCallback_OnBotTeleported_Pre);
	
	g_DHookEventKilled = CreateDynamicHook(gamedata, "CTFPlayer::Event_Killed");
	g_DHookShouldGib = CreateDynamicHook(gamedata, "CTFPlayer::ShouldGib");
	g_DHookEntSelectSpawnPoint = CreateDynamicHook(gamedata, "CBasePlayer::EntSelectSpawnPoint");
	g_DHookPassesFilterImpl = CreateDynamicHook(gamedata, "CBaseFilter::PassesFilterImpl");
	g_DHookPickUp = CreateDynamicHook(gamedata, "CTFItem::PickUp");
	g_DHookClientConnected = CreateDynamicHook(gamedata, "CTFGameRules::ClientConnected");
}

void DHooks_HookClient(int client)
{
	if (g_DHookEventKilled)
	{
		g_DHookEventKilled.HookEntity(Hook_Pre, client, DHookCallback_EventKilled_Pre);
		g_DHookEventKilled.HookEntity(Hook_Post, client, DHookCallback_EventKilled_Post);
	}
	
	if (g_DHookShouldGib)
	{
		g_DHookShouldGib.HookEntity(Hook_Pre, client, DHookCallback_ShouldGib_Pre);
	}
	
	if (g_DHookEntSelectSpawnPoint)
	{
		g_DHookEntSelectSpawnPoint.HookEntity(Hook_Pre, client, DHookCallback_EntSelectSpawnPoint_Pre);
	}
}

void DHooks_HookGamerules()
{
	if (g_DHookClientConnected)
	{
		g_DHookClientConnected.HookGamerules(Hook_Pre, DHookCallback_ClientConnected_Pre);
	}
}

void DHooks_OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "filter_tf_bot_has_tag"))
	{
		if (g_DHookPassesFilterImpl)
		{
			g_DHookPassesFilterImpl.HookEntity(Hook_Pre, entity, DHookCallback_PassesFilterImpl_Pre);
		}
	}
	else if (StrEqual(classname, "item_teamflag"))
	{
		if (g_DHookPickUp)
		{
			g_DHookPickUp.HookEntity(Hook_Pre, entity, DHookCallback_PickUp_Pre);
		}
	}
}

static void CreateDynamicDetour(GameData gamedata, const char[] name, DHookCallback callbackPre = INVALID_FUNCTION, DHookCallback callbackPost = INVALID_FUNCTION)
{
	DynamicDetour detour = DynamicDetour.FromConf(gamedata, name);
	if (detour)
	{
		if (callbackPre != INVALID_FUNCTION)
			detour.Enable(Hook_Pre, callbackPre);
		
		if (callbackPost != INVALID_FUNCTION)
			detour.Enable(Hook_Post, callbackPost);
	}
	else
	{
		LogError("Failed to create detour setup handle for %s", name);
	}
}

static DynamicHook CreateDynamicHook(GameData gamedata, const char[] name)
{
	DynamicHook hook = DynamicHook.FromConf(gamedata, name);
	if (!hook)
		LogError("Failed to create hook setup handle for %s", name);
	
	return hook;
}

public MRESReturn DHookCallback_PreClientUpdate_Pre()
{
	// Allows us to have an MvM server with 32 visible player slots
	GameRules_SetProp("m_bPlayingMannVsMachine", false);
	
	return MRES_Handled;
}

public MRESReturn DHookCallback_PreClientUpdate_Post()
{
	// Set it back afterwards
	GameRules_SetProp("m_bPlayingMannVsMachine", true);
	
	return MRES_Handled;
}

public MRESReturn DHookCallback_AllocateBots_Pre(int populator)
{
	// Do not allow the populator to allocate bots
	return MRES_Supercede;
}

public MRESReturn DHookCallback_RestoreCheckpoint_Pre(int populator)
{
	if (!g_bInWaitingForPlayers)
	{
		// The populator calls this multiple times, but we only want it once...
		if ((g_restoreCheckpointTime + 0.1) < GetGameTime())
		{
			g_restoreCheckpointTime = GetGameTime();
			SelectNewDefenders();
		}
	}
	
	return MRES_Handled;
}

/*
 * This detour supercedes the original function and recreates it
 * as accurately as possible to spawn players instead of bots.
 */
public MRESReturn DHookCallback_Spawn_Pre(Address pThis, DHookReturn ret, DHookParam params)
{
	CTFBotSpawner m_spawner = CTFBotSpawner(pThis);
	
	float rawHere[3];
	params.GetVector(1, rawHere);
	
	float here[3];
	here = Vector(rawHere[0], rawHere[1], rawHere[2]);
	
	CTFNavArea area = view_as<CTFNavArea>(TheNavMesh.GetNearestNavArea(here, .checkGround = false));
	if (area && area.HasAttributeTF(NO_SPAWNING))
	{
		ret.Value = false;
		return MRES_Supercede;
	}
	
	if (GameRules_IsMannVsMachineMode())
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
	for (z = 0.0; z < sv_stepsize.FloatValue; z += 4.0)
	{
		here[2] = rawHere[2] + sv_stepsize.FloatValue;
		
		if (SDKCall_IsSpaceToSpawnHere(here))
		{
			break;
		}
	}
	
	if (z >= sv_stepsize.FloatValue)
	{
		ret.Value = false;
		return MRES_Supercede;
	}
	
	if (GameRules_IsMannVsMachineMode())
	{
		if (m_spawner.m_class == TFClass_Engineer && m_spawner.m_defaultAttributes.m_attributeFlags & TELEPORT_TO_HINT && SDKCall_FindHint(true, false) == false)
		{
			ret.Value = false;
			return MRES_Supercede;
		}
	}
	
	// find dead player we can re-use
	int newPlayer = GetRobotToSpawn(m_spawner.m_defaultAttributes.m_attributeFlags & MINIBOSS);
	
	if (newPlayer != -1)
	{
		Player(newPlayer).ClearAllAttributes();
		
		// Remove any player attributes
		TF2Attrib_RemoveAll(newPlayer);
		
		// clear any old TeleportWhere settings 
		Player(newPlayer).ClearTeleportWhere();
		
		if (g_InternalSpawnPoint == INVALID_ENT_REFERENCE || EntRefToEntIndex(g_InternalSpawnPoint) == -1)
		{
			g_InternalSpawnPoint = EntIndexToEntRef(CreateEntityByName("populator_internal_spawn_point"));
			DispatchSpawn(g_InternalSpawnPoint);
		}
		
		// print name
		char name[64];
		m_spawner.GetName(name, sizeof(name));
		PrintCenterText(newPlayer, "You have spawned as: %s.", name);
		
		DispatchKeyValueVector(g_InternalSpawnPoint, "origin", here);
		Player(newPlayer).m_spawnPointEntity = g_InternalSpawnPoint;
		
		TFTeam team = TFTeam_Red;
		
		if (GameRules_IsMannVsMachineMode())
		{
			team = TFTeam_Invaders;
		}
		
		// TODO: CTFBot::ChangeTeam does a little bit more, like making team switches silent
		TF2_ChangeClientTeam(newPlayer, team);
		
		SetEntProp(newPlayer, Prop_Data, "m_bAllowInstantSpawn", true);
		FakeClientCommand(newPlayer, "joinclass %s", g_aRawPlayerClassNames[m_spawner.m_class]);
		
		// Set the address of CTFPlayer::m_iszClassIcon from the return value of CTFBotSpawner::GetClassIcon.
		// Simply setting the value using SetEntPropString leads to segfaults, don't do that!
		int offset = FindSendPropInfo("CTFPlayer", "m_iszClassIcon");
		SetEntData(newPlayer, offset, m_spawner.GetClassIcon());
		
		Player(newPlayer).ClearEventChangeAttributes();
		for (int i = 0; i < m_spawner.m_eventChangeAttributes.Count(); ++i)
		{
			Player(newPlayer).AddEventChangeAttributes(m_spawner.m_eventChangeAttributes.Get(i, 108));
		}
		
		Player(newPlayer).SetTeleportWhere(m_spawner.m_teleportWhereName);
		
		if (m_spawner.m_defaultAttributes.m_attributeFlags & MINIBOSS)
		{
			SetEntProp(newPlayer, Prop_Send, "m_bIsMiniBoss", true);
		}
		
		if (m_spawner.m_defaultAttributes.m_attributeFlags & USE_BOSS_HEALTH_BAR)
		{
			SetEntProp(newPlayer, Prop_Send, "m_bUseBossHealthBar", true);
		}
		
		if (m_spawner.m_defaultAttributes.m_attributeFlags & AUTO_JUMP)
		{
			Player(newPlayer).SetAutoJump(m_spawner.m_flAutoJumpMin, m_spawner.m_flAutoJumpMax);
		}
		
		if (m_spawner.m_defaultAttributes.m_attributeFlags & BULLET_IMMUNE)
		{
			TF2_AddCondition(newPlayer, TFCond_BulletImmune);
		}
		
		if (m_spawner.m_defaultAttributes.m_attributeFlags & BLAST_IMMUNE)
		{
			TF2_AddCondition(newPlayer, TFCond_BlastImmune);
		}
		
		if (m_spawner.m_defaultAttributes.m_attributeFlags & FIRE_IMMUNE)
		{
			TF2_AddCondition(newPlayer, TFCond_FireImmune);
		}
		
		if (GameRules_IsMannVsMachineMode())
		{
			// initialize currency to be dropped on death to zero
			SetEntProp(newPlayer, Prop_Send, "m_nCurrency", 0);
			
			// announce Spies
			if (m_spawner.m_class == TFClass_Spy)
			{
				int spyCount = 0;
				for (int client = 1; client <= MaxClients; client++)
				{
					if (IsClientInGame(client) && IsPlayerAlive(client) && TF2_GetClientTeam(client) == TFTeam_Invaders)
					{
						if (TF2_GetPlayerClass(client) == TFClass_Spy)
						{
							++spyCount;
						}
					}
				}
				
				Event event = CreateEvent("mvm_mission_update");
				if (event)
				{
					event.SetInt("class", view_as<int>(TFClass_Spy));
					event.SetInt("count", spyCount);
					event.Fire();
				}
			}
			
		}
		
		Player(newPlayer).SetScaleOverride(m_spawner.m_scale);
		
		int nHealth = m_spawner.m_health;
		
		if (nHealth <= 0.0)
		{
			nHealth = TF2Util_GetEntityMaxHealth(newPlayer);
		}
		
		nHealth = RoundToFloor(float(nHealth) * SDKCall_GetHealthMultiplier(false));
		Player(newPlayer).ModifyMaxHealth(nHealth);
		
		Player(newPlayer).StartIdleSound();
		
		// Add our items first, they'll get replaced below by the normal MvM items if any are needed
		if (GameRules_IsMannVsMachineMode() && TF2_GetClientTeam(newPlayer) == TFTeam_Invaders)
		{
			// Apply the Rome 2 promo items to each player. They'll be 
			// filtered out for clients that do not have Romevision.
			Player(newPlayer).AddItem(g_szRomePromoItems_Hat[m_spawner.m_class]);
			Player(newPlayer).AddItem(g_szRomePromoItems_Misc[m_spawner.m_class]);
		}
		
		char defaultEventChangeAttributesName[64];
		PtrToString(GetEntData(GetPopulator(), GetOffset("CPopulationManager::m_defaultEventChangeAttributesName")), defaultEventChangeAttributesName, sizeof(defaultEventChangeAttributesName));
		
		EventChangeAttributes_t pEventChangeAttributes = Player(newPlayer).GetEventChangeAttributes(defaultEventChangeAttributesName);
		if (!pEventChangeAttributes)
		{
			pEventChangeAttributes = m_spawner.m_defaultAttributes;
		}
		Player(newPlayer).OnEventChangeAttributes(pEventChangeAttributes);
		
		if (Player(newPlayer).HasAttribute(SPAWN_WITH_FULL_CHARGE))
		{
			// charge up our weapons
			
			// Medigun Ubercharge
			int weapon = GetPlayerWeaponSlot(newPlayer, TFWeaponSlot_Secondary);
			if (weapon != -1 && HasEntProp(weapon, Prop_Send, "m_flChargeLevel"))
			{
				SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", 1.0);
			}
			
			if (TF2_GetPlayerClass(newPlayer) != TFClass_Medic || Player(newPlayer).HasAttribute(PROJECTILE_SHIELD))
			{
				SetEntPropFloat(newPlayer, Prop_Send, "m_flRageMeter", 100.0);
			}
		}
		
		TFClassType nClassIndex = TF2_GetPlayerClass(newPlayer);
		
		if (GetEntProp(TFObjectiveResource(), Prop_Send, "m_nMvMEventPopfileType") == MVM_EVENT_POPFILE_HALLOWEEN)
		{
			// zombies use the original player models
			SetEntProp(newPlayer, Prop_Send, "m_nSkin", 4);
			
			char item[64];
			Format(item, sizeof(item), "Zombie %s", g_aRawPlayerClassNamesShort[nClassIndex]);
			
			Player(newPlayer).AddItem(item);
		}
		else
		{
			// use the nifty new robot model
			if (nClassIndex >= TFClass_Scout && nClassIndex <= TFClass_Engineer)
			{
				if (m_spawner.m_scale >= tf_mvm_miniboss_scale.FloatValue || GetEntProp(newPlayer, Prop_Send, "m_bIsMiniBoss") && FileExists(g_szBotBossModels[nClassIndex], true))
				{
					SetVariantString(g_szBotBossModels[nClassIndex]);
					AcceptEntityInput(newPlayer, "SetCustomModel");
					SetEntProp(newPlayer, Prop_Send, "m_bUseClassAnimations", true);
					SetEntProp(newPlayer, Prop_Data, "m_bloodColor", DONT_BLEED);
				}
				else if (FileExists(g_szBotModels[nClassIndex], true))
				{
					SetVariantString(g_szBotModels[nClassIndex]);
					AcceptEntityInput(newPlayer, "SetCustomModel");
					SetEntProp(newPlayer, Prop_Send, "m_bUseClassAnimations", true);
					SetEntProp(newPlayer, Prop_Data, "m_bloodColor", DONT_BLEED);
				}
			}
		}
		
		if (params.Get(2))
		{
			// EntityHandleVector_t
			CUtlVector result = CUtlVector(params.Get(2));
			result.AddToTail(GetEntityHandle(newPlayer));
		}
		
		if (GameRules_IsMannVsMachineMode())
		{
			if (GetEntProp(newPlayer, Prop_Send, "m_bIsMiniBoss"))
			{
				HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_GIANT_CALLOUT", TFTeam_Defenders);
			}
		}
		
		// For easy access in populator callbacks
		m_justSpawnedVector.Push(newPlayer);
	}
	else
	{
		ret.Value = false;
		return MRES_Supercede;
	}
	
	ret.Value = true;
	return MRES_Supercede;
}

public MRESReturn DHookCallback_PopulationManagerUpdate_Pre(int populator)
{
	// allows spawners to freely switch teams of players
	g_bAllowTeamChange = true;
	
	return MRES_Handled;
}

public MRESReturn DHookCallback_PopulationManagerUpdate_Post(int populator)
{
	g_bAllowTeamChange = false;
	
	return MRES_Handled;
}

public MRESReturn DHookCallback_WaveSpawnPopulatorUpdate_Post(Address pThis)
{
	for (int i = 0; i < m_justSpawnedVector.Length; i++)
	{
		int player = m_justSpawnedVector.Get(i);
		
		SetEntProp(player, Prop_Send, "m_nCurrency", 0);
		SetEntData(player, GetOffset("CTFPlayer::m_pWaveSpawnPopulator"), pThis);
		
		char iszClassIconName[64];
		GetEntPropString(player, Prop_Send, "m_iszClassIcon", iszClassIconName, sizeof(iszClassIconName));
		
		// Allows client UI to know if a specific spawner is active
		SetMannVsMachineWaveClassActive(iszClassIconName);
		
		bool bLimitedSupport = Deref(pThis + GetOffset("CWaveSpawnPopulator::m_bLimitedSupport"), NumberType_Int8);
		if (bLimitedSupport)
		{
			SetEntData(player, GetOffset("CTFPlayer::m_bIsLimitedSupportEnemy"), true);
		}
		
		// what bot should do after spawning at teleporter exit
		if (s_spawnLocationResult == SPAWN_LOCATION_TELEPORTER)
		{
			OnBotTeleported(player);
		}
	}
	
	// After we are done, clear the vector
	m_justSpawnedVector.Clear();
	
	return MRES_Supercede;
}

public MRESReturn DHookCallback_MissionPopulatorUpdateMission_Pre(Address pThis, DHookReturn ret, DHookParam params)
{
	MissionType mission = params.Get(1);
	
	ArrayList livePlayerVector = new ArrayList(MaxClients);
	
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (TF2_GetClientTeam(client) != TFTeam_Invaders)
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		livePlayerVector.Push(client);
	}
	
	s_activeMissionMembers = 0;
	
	for (int i = 0; i < livePlayerVector.Length; i++)
	{
		int player = livePlayerVector.Get(i);
		if (Player(player).HasMission(mission))
		{
			++s_activeMissionMembers;
		}
	}
	
	if (s_activeMissionMembers > 0)
	{
		// wait until prior mission is dead
		
		// cooldown is time after death of last mission member
		m_cooldownTimer.Start(CMissionPopulator(pThis).m_cooldownDuration);
		
		delete livePlayerVector;
		ret.Value = false;
		return MRES_Supercede;
	}
	
	if (!m_cooldownTimer.IsElapsed())
	{
		delete livePlayerVector;
		ret.Value = false;
		return MRES_Supercede;
	}
	
	s_nSniperCount = 0;
	for (int i = 0; i < livePlayerVector.Length; i++)
	{
		int liveBot = livePlayerVector.Get(i);
		if (TF2_GetPlayerClass(liveBot) == TFClass_Sniper)
		{
			s_nSniperCount++;
		}
	}
	
	delete livePlayerVector;
	return MRES_Handled;
}

public MRESReturn DHookCallback_MissionPopulatorUpdateMission_Post(Address pThis, DHookReturn ret, DHookParam params)
{
	MissionType mission = params.Get(1);
	
	for (int i = 0; i < m_justSpawnedVector.Length; i++)
	{
		int player = m_justSpawnedVector.Get(i);
		
		Player(player).SetMission(mission);
		SetEntData(player, GetOffset("CTFPlayer::m_bIsMissionEnemy"), true);
		
		char iszClassIconName[64];
		GetEntPropString(player, Prop_Send, "m_iszClassIcon", iszClassIconName, sizeof(iszClassIconName));
		
		int iFlags = MVM_CLASS_FLAG_MISSION;
		if (GetEntProp(player, Prop_Send, "m_bIsMiniBoss"))
		{
			iFlags |= MVM_CLASS_FLAG_MINIBOSS;
		}
		else if (Player(player).HasAttribute(ALWAYS_CRIT))
		{
			iFlags |= MVM_CLASS_FLAG_ALWAYSCRIT;
		}
		IncrementMannVsMachineWaveClassCount(iszClassIconName, iFlags);
		
		// Response rules stuff for MvM
		if (GameRules_IsMannVsMachineMode())
		{
			// Only have defenders announce the arrival of the first enemy Sniper
			if (Player(player).HasMission(MISSION_SNIPER))
			{
				s_nSniperCount++;
				
				if (s_nSniperCount == 1)
				{
					HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_SNIPER_CALLOUT", TFTeam_Defenders);
				}
			}
		}
		
		if (s_spawnLocationResult == SPAWN_LOCATION_TELEPORTER)
		{
			OnBotTeleported(player);
		}
	}
	
	// After we are done, clear the vector
	m_justSpawnedVector.Clear();
	
	return MRES_Handled;
}

public MRESReturn DHookCallback_UpdateMissionDestroySentries_Pre(Address pThis, DHookReturn ret)
{
	// Disable sentry buster spawns for the time being
	ret.Value = false;
	return MRES_Supercede;
}

public MRESReturn DHookCallback_InputChangeBotAttributes_Pre(int populatorInterface, DHookParam params)
{
	Address iszVal = params.GetObjectVar(1, 0x8, ObjectValueType_Int);
	
	char pszEventName[64];
	PtrToString(iszVal, pszEventName, sizeof(pszEventName));
	
	if (GameRules_IsMannVsMachineMode())
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client))
				continue;
			
			if (TF2_GetClientTeam(client) != TFTeam_Invaders)
				continue;
			
			if (!IsPlayerAlive(client))
				continue;
			
			EventChangeAttributes_t pEvent = Player(client).GetEventChangeAttributes(pszEventName);
			if (pEvent)
			{
				Player(client).OnEventChangeAttributes(pEvent);
			}
		}
	}
	
	return MRES_Supercede;
}

public MRESReturn DHookCallback_GetTeamAssignmentOverride_Pre(DHookReturn ret, DHookParam params)
{
	int player = params.Get(1);
	TFTeam desiredTeam = params.Get(2);
	
	if (g_bInWaitingForPlayers)
	{
		// funnel players into defender team during waiting for players so they can run around
		ret.Value = TFTeam_Defenders;
		return MRES_Supercede;
	}
	else if (g_bAllowTeamChange)
	{
		// allow player through
		GameRules_SetProp("m_bPlayingMannVsMachine", false);
		return MRES_Handled;
	}
	else
	{
		if (desiredTeam == TFTeam_Spectator && TF2_GetClientTeam(player) == TFTeam_Invaders)
		{
			PrintCenterText(player, "You are not allowed to suicide as a robot.");
			ret.Value = TFTeam_Invaders;
			return MRES_Supercede;
		}
		
		// determine whether the teams are unbalanced enough to allow switching
		int iDefenderCount = 0, iInvaderCount = 0;
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client))
				continue;
			
			// do not include ourselves in the ratio calculations
			if (client == player)
				continue;
			
			if (TF2_GetClientTeam(client) == TFTeam_Defenders)
				iDefenderCount++;
			else if (TF2_GetClientTeam(client) == TFTeam_Spectator || TF2_GetClientTeam(client) == TFTeam_Invaders)
				iInvaderCount++;
		}
		
		float flReqRatio = float(MaxClients - mitm_defender_max_count.IntValue) / mitm_defender_max_count.FloatValue;
		float flCurRatio = float(iInvaderCount) / float(iDefenderCount);
		if (flCurRatio < flReqRatio)
		{
			ret.Value = TFTeam_Spectator;
		}
		else
		{
			ret.Value = TFTeam_Defenders;
		}
		
		return MRES_Supercede;
	}
}

public MRESReturn DHookCallback_GetTeamAssignmentOverride_Post(DHookReturn ret, DHookParam params)
{
	if (g_bAllowTeamChange)
	{
		GameRules_SetProp("m_bPlayingMannVsMachine", true);
	}
	
	return MRES_Handled;
}

public MRESReturn DHookCallback_GetLoadoutItem_Pre(int player, DHookReturn ret, DHookParam params)
{
	if (TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		// Generate base items for robot players
		GameRules_SetProp("m_bIsInTraining", true);
	}
	
	return MRES_Handled;
}

public MRESReturn DHookCallback_GetLoadoutItem_Post(int player, DHookReturn ret, DHookParam params)
{
	if (TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		GameRules_SetProp("m_bIsInTraining", false);
	}
	
	return MRES_Handled;
}

public MRESReturn DHookCallback_CheckInstantLoadoutRespawn_Pre(int player)
{
	if (TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		// Never allow invaders to respawn with a new loadout, this breaks spawners
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

public MRESReturn DHookCallback_ShouldForceAutoTeam_Pre(int player, DHookReturn ret)
{
	// don't allow game logic to force players on a team
	ret.Value = false;
	return MRES_Supercede;
}

public MRESReturn DHookCallback_DoClassSpecialSkill_Pre(int player, DHookReturn ret)
{
	if (TF2_GetPlayerClass(player) == TFClass_DemoMan && GetEntProp(player, Prop_Send, "m_bShieldEquipped"))
	{
		float velocity[3];
		GetEntPropVector(player, Prop_Data, "m_vecAbsVelocity", velocity);
		
		if (Player(player).HasAttribute(AIR_CHARGE_ONLY) && (GetEntPropEnt(player, Prop_Send, "m_hGroundEntity") != -1 || velocity[2] > 0.0))
		{
			ret.Value = false;
			return MRES_Supercede;
		}
	}
	
	return MRES_Ignored;
}

public MRESReturn DHookCallback_FindSnapToBuildPos_Pre(int obj, DHookReturn ret, DHookParam params)
{
	int builder = GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
	
	if (TF2_GetClientTeam(builder) != TFTeam_Defenders)
	{
		return MRES_Ignored;
	}
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (TF2_GetClientTeam(client) != GetEnemyTeam(TF2_GetClientTeam(builder)))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		// The robot sapper only works on bots so we make every invader a fake client
		SetEntityFlags(client, GetEntityFlags(client) | FL_FAKECLIENT);
	}
	
	return MRES_Ignored;
}

public MRESReturn DHookCallback_FindSnapToBuildPos_Post(int obj, DHookReturn ret, DHookParam params)
{
	int builder = GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
	
	if (TF2_GetClientTeam(builder) != TFTeam_Defenders)
	{
		return MRES_Ignored;
	}
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (TF2_GetClientTeam(client) != GetEnemyTeam(TF2_GetClientTeam(builder)))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		SetEntityFlags(client, GetEntityFlags(client) & ~FL_FAKECLIENT);
	}
	
	return MRES_Ignored;
}

public MRESReturn DHookCallback_FindSpawnLocation_Post(Address populator, DHookReturn ret, DHookParam params)
{
	// Store for use in populator callbacks.
	// We can't use CWaveSpawnPopulator::m_spawnLocationResult because it gets overridden in some cases.
	s_spawnLocationResult = ret.Value;
	
	return MRES_Handled;
}

public MRESReturn DHookCallback_DoTeleporterOverride_Post(DHookReturn ret, DHookParam params)
{
	CBaseEntity spawnEnt = CBaseEntity(params.Get(1));
	
	float vSpawnPosition[3];
	params.GetVector(2, vSpawnPosition);
	
	bool bClosestPointOnNav = params.Get(3);
	
	ArrayList teleporterList = new ArrayList();
	
	int obj = MaxClients + 1;
	while ((obj = FindEntityByClassname(obj, "obj_*")) != -1)
	{
		if (TF2_GetObjectType(obj) != TFObject_Teleporter)
			continue;
		
		if (view_as<TFTeam>(GetEntProp(obj, Prop_Data, "m_iTeamNum")) != TFTeam_Invaders)
			continue;
		
		if (GetEntProp(obj, Prop_Send, "m_bBuilding"))
			continue;
		
		if (GetEntProp(obj, Prop_Send, "m_bHasSapper"))
			continue;
		
		if (GetEntProp(obj, Prop_Send, "m_bPlasmaDisable"))
			continue;
		
		char szSpawnPointName[64];
		spawnEnt.GetPropString(Prop_Data, "m_iName", szSpawnPointName, sizeof(szSpawnPointName));
		
		for (int iTelePoints = 0; iTelePoints < Entity(obj).m_teleportWhereName.Length; ++iTelePoints)
		{
			char teleportWhereName[64];
			Entity(obj).m_teleportWhereName.GetString(iTelePoints, teleportWhereName, sizeof(teleportWhereName));
			
			if (StrEqual(teleportWhereName, szSpawnPointName, false))
			{
				teleporterList.Push(obj);
				break;
			}
		}
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
	
	float spawnEntCenter[3];
	spawnEnt.WorldSpaceCenter(spawnEntCenter);
	
	CNavArea nav = TheNavMesh.GetNearestNavArea(spawnEntCenter);
	if (!nav)
	{
		delete teleporterList;
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
	
	delete teleporterList;
	params.SetVector(2, vSpawnPosition);
	ret.Value = SPAWN_LOCATION_NAV;
	return MRES_Supercede;
}

public MRESReturn DHookCallback_OnBotTeleported_Pre(DHookParam params)
{
	// This crashes our server in local testing due to s_lastTeleporter being null
	return MRES_Supercede;
}

void OnBotTeleported(int bot)
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
	float vForward[3], botOrigin[3];
	GetAngleVectors(angles, vForward, NULL_VECTOR, NULL_VECTOR);
	GetClientAbsOrigin(bot, botOrigin);
	
	ScaleVector(vForward, 50.0);
	AddVectors(botOrigin, vForward, vForward);
	
	TeleportEntity(bot, .angles = vForward);
	
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

public MRESReturn DHookCallback_EventKilled_Pre(int player, DHookParam params)
{
	// Replicate behavior of CTFBot::Event_Killed
	if (TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		// announce Spies
		if (TF2_GetPlayerClass(player) == TFClass_Spy)
		{
			int spyCount = 0;
			for (int client = 1; client <= MaxClients; client++)
			{
				if (!IsClientInGame(client))
					continue;
				
				if (TF2_GetClientTeam(client) != TFTeam_Invaders)
					continue;
				
				if (!IsPlayerAlive(client))
					continue;
				
				if (TF2_GetPlayerClass(client) == TFClass_Spy)
				{
					++spyCount;
				}
			}
			
			Event event = CreateEvent("mvm_mission_update");
			if (event)
			{
				event.SetInt("class", view_as<int>(TFClass_Spy));
				event.SetInt("count", spyCount);
				event.Fire();
			}
		}
		else if (TF2_GetPlayerClass(player) == TFClass_Engineer)
		{
			// TODO: Engineer Behavior
		}
		
		// Enables currency drops from human kills
		SetEntityFlags(player, GetEntityFlags(player) | FL_FAKECLIENT);
	}
	
	Player(player).StopIdleSound();
	
	return MRES_Handled;
}

public MRESReturn DHookCallback_EventKilled_Post(int player, DHookParam params)
{
	if (TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		SetEntityFlags(player, GetEntityFlags(player) & ~FL_FAKECLIENT);
	}
	
	return MRES_Handled;
}

public MRESReturn DHookCallback_ShouldGib_Pre(int player, DHookReturn ret, DHookParam params)
{
	if (GameRules_IsMannVsMachineMode() && (GetEntProp(player, Prop_Send, "m_bIsMiniBoss") || GetEntPropFloat(player, Prop_Send, "m_flModelScale") > 1.0))
	{
		ret.Value = true;
		return MRES_Supercede;
	}
	
	return MRES_Handled;
}

public MRESReturn DHookCallback_EntSelectSpawnPoint_Pre(int player, DHookReturn ret)
{
	// override normal spawn behavior to spawn robots at the right place
	if (IsValidEntity(Player(player).m_spawnPointEntity))
	{
		ret.Value = Player(player).m_spawnPointEntity;
		return MRES_Supercede;
	}
	
	return MRES_Handled;
}

public MRESReturn DHookCallback_PassesFilterImpl_Pre(int filter, DHookReturn ret, DHookParam params)
{
	int entity = params.Get(2);
	
	if (0 < entity < MaxClients && TF2_GetClientTeam(entity) == TFTeam_Invaders)
	{
		bool m_bRequireAllTags = GetEntProp(filter, Prop_Data, "m_bRequireAllTags") != 0;
		
		char m_iszTags[512];
		GetEntPropString(filter, Prop_Data, "m_iszTags", m_iszTags, sizeof(m_iszTags));
		
		// max. 8 tags with a length of 64 characters each
		char tags[8][64];
		int count = ExplodeString(m_iszTags, " ", tags, sizeof(tags), sizeof(tags[]));
		
		bool bPasses = false;
		for (int i = 0; i < count; ++i)
		{
			if (Player(entity).HasTag(tags[i]))
			{
				bPasses = true;
				if (!m_bRequireAllTags)
				{
					break;
				}
			}
			else if (m_bRequireAllTags)
			{
				ret.Value = false;
				return MRES_Supercede;
			}
		}
		
		ret.Value = bPasses;
		return MRES_Supercede;
	}
	
	return MRES_Handled;
}

public MRESReturn DHookCallback_PickUp_Pre(int item, DHookParam params)
{
	int player = params.Get(1);
	
	if (TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		if (Player(player).HasAttribute(IGNORE_FLAG))
		{
			return MRES_Supercede;
		}
	}
	
	return MRES_Handled;
}

public MRESReturn DHookCallback_ClientConnected_Pre(DHookReturn ret, DHookParam params)
{
	// MvM will start rejecting connections if the server has 10 humans
	ret.Value = true;
	return MRES_Supercede;
}
