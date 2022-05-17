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

void DHooks_Initialize(GameData gamedata)
{
	m_justSpawnedVector = new ArrayList(MaxClients);
	
	CreateDynamicDetour(gamedata, "CTFGCServerSystem::PreClientUpdate", DHookCallback_PreClientUpdate_Pre, DHookCallback_PreClientUpdate_Post);
	CreateDynamicDetour(gamedata, "CPopulationManager::AllocateBots", DHookCallback_AllocateBots_Pre);
	CreateDynamicDetour(gamedata, "CPopulationManager::RestoreCheckpoint", _, DHookCallback_RestoreCheckpoint_Post);
	CreateDynamicDetour(gamedata, "CTFBotSpawner::Spawn", DHookCallback_Spawn_Pre);
	CreateDynamicDetour(gamedata, "CWaveSpawnPopulator::Update", _, DHookCallback_WaveSpawnPopulatorUpdate_Post);
	CreateDynamicDetour(gamedata, "CMissionPopulator::UpdateMission", _, DHookCallback_MissionPopulatorUpdateMission_Post);
	CreateDynamicDetour(gamedata, "CMissionPopulator::UpdateMissionDestroySentries", DHookCallback_UpdateMissionDestroySentries_Pre);
	CreateDynamicDetour(gamedata, "CPointPopulatorInterface::InputChangeBotAttributes", DHookCallback_InputChangeBotAttributes_Pre);
	CreateDynamicDetour(gamedata, "CTFGameRules::GetTeamAssignmentOverride", DHookCallback_GetTeamAssignmentOverride_Pre, DHookCallback_GetTeamAssignmentOverride_Post);
	CreateDynamicDetour(gamedata, "CTFPlayer::GetLoadoutItem", DHookCallback_GetLoadoutItem_Pre, DHookCallback_GetLoadoutItem_Post);
	CreateDynamicDetour(gamedata, "CTFPlayer::ShouldForceAutoTeam", DHookCallback_ShouldForceAutoTeam_Pre);
	CreateDynamicDetour(gamedata, "CBaseObject::FindSnapToBuildPos", DHookCallback_FindSnapToBuildPos_Pre, DHookCallback_FindSnapToBuildPos_Post);
	CreateDynamicDetour(gamedata, "CSpawnLocation::FindSpawnLocation", _, DHookCallback_FindSpawnLocation_Post);
	
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
		g_DHookPassesFilterImpl.HookEntity(Hook_Pre, entity, DHookCallback_PassesFilterImpl_Pre);
	}
	else if (StrEqual(classname, "item_teamflag"))
	{
		g_DHookPickUp.HookEntity(Hook_Pre, entity, DHookCallback_PickUp_Pre);
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

public MRESReturn DHookCallback_RestoreCheckpoint_Post(int populator)
{
	PrintToChatAll("Selecting a new set of defenders...");
	
	SelectNewDefenders();
	
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
	
	// TODO: Engineer hints
	/*if (TFGameRules() && TFGameRules()- > GameRules_IsMannVsMachineMode())
	{
		if (m_class == TF_CLASS_ENGINEER && m_defaultAttributes.m_attributeFlags & CTFBot::TELEPORT_TO_HINT && CTFBotMvMEngineerHintFinder::FindHint(true, false) == false)
		{
			if (tf_populator_debug.GetBool())
			{
				DevMsg("CTFBotSpawner: %3.2f: *** No teleporter hint for engineer\n", gpGlobals- > curtime);
			}
			
			return false;
		}
	}*/
	
	// find dead player we can re-use
	int newPlayer = GetRobotToSpawn();
	
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
		g_bAllowTeamChange = true;
		TF2_ChangeClientTeam(newPlayer, team);
		g_bAllowTeamChange = false;
		
		char m_iszClassIcon[64];
		m_spawner.GetClassIcon(m_iszClassIcon, sizeof(m_iszClassIcon));
		LogMessage("m_iszClassIcon: %s", m_iszClassIcon);
		
		SetEntProp(newPlayer, Prop_Data, "m_bAllowInstantSpawn", true);
		FakeClientCommand(newPlayer, "joinclass %s", g_aRawPlayerClassNames[m_spawner.m_class]);
		SetEntPropString(newPlayer, Prop_Send, "m_iszClassIcon", m_iszClassIcon);
		
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
			Player(newPlayer).m_flAutoJumpMin = m_spawner.m_flAutoJumpMin;
			Player(newPlayer).m_flAutoJumpMax = m_spawner.m_flAutoJumpMax;
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
		UTIL_StringtToCharArray(view_as<Address>(GetEntData(GetPopulator(), GetOffset("CPopulationManager::m_defaultEventChangeAttributesName"))), defaultEventChangeAttributesName, sizeof(defaultEventChangeAttributesName));
		
		EventChangeAttributes_t pEventChangeAttributes = Player(newPlayer).GetEventChangeAttributes(defaultEventChangeAttributesName);
		if (!pEventChangeAttributes)
		{
			pEventChangeAttributes = m_spawner.m_defaultAttributes;
		}
		Player(newPlayer).OnEventChangeAttributes(pEventChangeAttributes);
		
		int pFlag = Player(newPlayer).GetFlagToFetch();
		if (pFlag != -1)
		{
			Player(newPlayer).m_hFollowingFlagTarget = pFlag;
		}
		
		if (Player(newPlayer).HasAttribute(SPAWN_WITH_FULL_CHARGE))
		{
			// charge up our weapons
			
			// Medigun Ubercharge
			int weapon = GetPlayerWeaponSlot(newPlayer, TFWeaponSlot_Secondary);
			if (weapon != -1 && HasEntProp(weapon, Prop_Send, "m_flChargeLevel"))
			{
				SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", 1.0);
			}
			
			SetEntPropFloat(newPlayer, Prop_Send, "m_flRageMeter", 100.0);
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
				if (m_spawner.m_scale >= FindConVar("tf_mvm_miniboss_scale").FloatValue || GetEntProp(newPlayer, Prop_Send, "m_bIsMiniBoss") && FileExists(g_szBotBossModels[nClassIndex], true))
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
		
		// Populated from CSpawnLocation::FindSpawnLocation detour.
		// We can't use CWaveSpawnPopulator::m_spawnLocationResult because it gets overridden in some cases.
		if (s_spawnLocationResult == SPAWN_LOCATION_TELEPORTER)
		{
			OnBotTeleported(newPlayer);
		}
		
		// For easy access in WaveSpawnPopulator::Update()
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
		
		// TODO
		/*
		// what bot should do after spawning at teleporter exit
		if ( bTeleported )
		{
			OnBotTeleported( bot );
		}
		*/
	}
	
	// After we are done, clear the vector
	m_justSpawnedVector.Clear();
	
	return MRES_Supercede;
}

public MRESReturn DHookCallback_MissionPopulatorUpdateMission_Post(Address pThis, DHookReturn ret, DHookParam params)
{
	for (int i = 0; i < m_justSpawnedVector.Length; i++)
	{
		int player = m_justSpawnedVector.Get(i);
		
		Player(player).m_hFollowingFlagTarget = -1;
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
	UTIL_StringtToCharArray(iszVal, pszEventName, sizeof(pszEventName));
	
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
	
	if (tf_mvm_min_players_to_start.IntValue != 0)
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
		
		float flRatio = float(iInvaderCount) / float(iDefenderCount);
		if (flRatio < mitm_robots_humans_ratio.FloatValue)
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
	// Generate base items for robot players
	if (TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
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

public MRESReturn DHookCallback_ShouldForceAutoTeam_Pre(int player, DHookReturn ret)
{
	// don't allow game logic to force players on a team
	ret.Value = false;
	return MRES_Supercede;
}

public MRESReturn DHookCallback_FindSnapToBuildPos_Pre(int obj, DHookReturn ret, DHookParam params)
{
	int builder = GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
	
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
	// store for use in CTFBotSpawner::Spawn detour
	s_spawnLocationResult = ret.Value;
	
	return MRES_Handled;
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
	if (Player(player).m_spawnPointEntity != -1)
	{
		ret.Value = Player(player).m_spawnPointEntity;
		return MRES_Supercede;
	}
	
	return MRES_Handled;
}

public MRESReturn DHookCallback_PassesFilterImpl_Pre(int filter, DHookReturn ret, DHookParam params)
{
	int pEntity = params.Get(2);
	if (0 < pEntity < MaxClients && TF2_GetClientTeam(pEntity) == TFTeam_Invaders)
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
			if (Player(pEntity).HasTag(tags[i]))
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
	int pPlayer = params.Get(1);
	
	if (GameRules_IsMannVsMachineMode() && TF2_GetClientTeam(pPlayer) == TFTeam_Invaders)
	{
		Player(pPlayer).UpgradeStart();
		
		if (Player(pPlayer).HasAttribute(IGNORE_FLAG))
			return MRES_Supercede;
		
		Player(pPlayer).m_hFollowingFlagTarget = item;
	}
	
	return MRES_Handled;
}

public MRESReturn DHookCallback_ClientConnected_Pre(DHookReturn ret, DHookParam params)
{
	// MvM will start rejecting connections if the server has 10 humans
	ret.Value = true;
	return MRES_Supercede;
}
