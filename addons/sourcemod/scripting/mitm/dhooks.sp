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

static DynamicHook g_DHookSetModel;
static DynamicHook g_DHookCanBeUpgraded;
static DynamicHook g_DHookComeToRest;
static DynamicHook g_DHookEventKilled;
static DynamicHook g_DHookShouldGib;
static DynamicHook g_DHookIsAllowedToPickUpFlag;
static DynamicHook g_DHookEntSelectSpawnPoint;
static DynamicHook g_DHookPassesFilterImpl;
static DynamicHook g_DHookPickUp;
static DynamicHook g_DHookClientConnected;
static DynamicHook g_DHookFPlayerCanTakeDamage;

static ArrayList m_justSpawnedList;

static int g_internalSpawnPoint = INVALID_ENT_REFERENCE;
static SpawnLocationResult s_spawnLocationResult = SPAWN_LOCATION_NOT_FOUND;

// CMissionPopulator
static CountdownTimer m_cooldownTimer;
static CountdownTimer m_checkForDangerousSentriesTimer;
static CMissionPopulator s_MissionPopulator;
static int s_activeMissionMembers;
static int s_nSniperCount;

// Engineer Teleporter
static CBaseEntity s_lastTeleporter;
static float s_flLastTeleportTime;

void DHooks_Init(GameData gamedata)
{
	m_justSpawnedList = new ArrayList();
	
	CreateDynamicDetour(gamedata, "CTFGCServerSystem::PreClientUpdate", DHookCallback_PreClientUpdate_Pre, DHookCallback_PreClientUpdate_Post);
	CreateDynamicDetour(gamedata, "CPopulationManager::AllocateBots", DHookCallback_AllocateBots_Pre);
	CreateDynamicDetour(gamedata, "CPopulationManager::RestoreCheckpoint", DHookCallback_RestoreCheckpoint_Pre);
	CreateDynamicDetour(gamedata, "CTFBotSpawner::Spawn", DHookCallback_CTFBotSpawnerSpawn_Pre);
	CreateDynamicDetour(gamedata, "CSquadSpawner::Spawn", _, DHookCallback_CSquadSpawner_Post);
	CreateDynamicDetour(gamedata, "CPopulationManager::Update", DHookCallback_PopulationManagerUpdate_Pre, DHookCallback_PopulationManagerUpdate_Post);
	CreateDynamicDetour(gamedata, "CPeriodicSpawnPopulator::Update", _, DHookCallback_PeriodicSpawnPopulatorUpdate_Post);
	CreateDynamicDetour(gamedata, "CWaveSpawnPopulator::Update", _, DHookCallback_WaveSpawnPopulatorUpdate_Post);
	CreateDynamicDetour(gamedata, "CMissionPopulator::UpdateMission", DHookCallback_MissionPopulatorUpdateMission_Pre, DHookCallback_MissionPopulatorUpdateMission_Post);
	CreateDynamicDetour(gamedata, "CMissionPopulator::UpdateMissionDestroySentries", DHookCallback_UpdateMissionDestroySentries_Pre, DHookCallback_UpdateMissionDestroySentries_Post);
	CreateDynamicDetour(gamedata, "CPointPopulatorInterface::InputChangeBotAttributes", DHookCallback_InputChangeBotAttributes_Pre);
	CreateDynamicDetour(gamedata, "CTFGameRules::GetTeamAssignmentOverride", DHookCallback_GetTeamAssignmentOverride_Pre, DHookCallback_GetTeamAssignmentOverride_Post);
	CreateDynamicDetour(gamedata, "CTFPlayer::GetLoadoutItem", DHookCallback_GetLoadoutItem_Pre, DHookCallback_GetLoadoutItem_Post);
	CreateDynamicDetour(gamedata, "CTFPlayer::CheckInstantLoadoutRespawn", DHookCallback_CheckInstantLoadoutRespawn_Pre);
	CreateDynamicDetour(gamedata, "CTFPlayer::ShouldForceAutoTeam", DHookCallback_ShouldForceAutoTeam_Pre);
	CreateDynamicDetour(gamedata, "CTFPlayer::DoClassSpecialSkill", DHookCallback_DoClassSpecialSkill_Pre);
	CreateDynamicDetour(gamedata, "CTFPlayer::RemoveAllOwnedEntitiesFromWorld", DHookCallback_RemoveAllOwnedEntitiesFromWorld_Pre);
	CreateDynamicDetour(gamedata, "CTFPlayer::CanBuild", DHookCallback_CanBuild_Pre, DHookCallback_CanBuild_Post);
	CreateDynamicDetour(gamedata, "CWeaponMedigun::AllowedToHealTarget", DHookCallback_AllowedToHealTarget_Pre);
	CreateDynamicDetour(gamedata, "CSpawnLocation::FindSpawnLocation", _, DHookCallback_FindSpawnLocation_Post);
	CreateDynamicDetour(gamedata, "CTraceFilterObject::ShouldHitEntity", _, DHookCallback_ShouldHitEntity_Post);
	CreateDynamicDetour(gamedata, "CLagCompensationManager::StartLagCompensation", DHookCallback_StartLagCompensation_Pre, DHookCallback_StartLagCompensation_Post);
	CreateDynamicDetour(gamedata, "DoTeleporterOverride", _, DHookCallback_DoTeleporterOverride_Post);
	CreateDynamicDetour(gamedata, "OnBotTeleported", DHookCallback_OnBotTeleported_Pre);
	
	g_DHookSetModel = CreateDynamicHook(gamedata, "CBaseEntity::SetModel");
	g_DHookCanBeUpgraded = CreateDynamicHook(gamedata, "CBaseObject::CanBeUpgraded");
	g_DHookComeToRest = CreateDynamicHook(gamedata, "CItem::ComeToRest");
	g_DHookEventKilled = CreateDynamicHook(gamedata, "CTFPlayer::Event_Killed");
	g_DHookShouldGib = CreateDynamicHook(gamedata, "CTFPlayer::ShouldGib");
	g_DHookIsAllowedToPickUpFlag = CreateDynamicHook(gamedata, "CTFPlayer::IsAllowedToPickUpFlag");
	g_DHookEntSelectSpawnPoint = CreateDynamicHook(gamedata, "CBasePlayer::EntSelectSpawnPoint");
	g_DHookPassesFilterImpl = CreateDynamicHook(gamedata, "CBaseFilter::PassesFilterImpl");
	g_DHookPickUp = CreateDynamicHook(gamedata, "CTFItem::PickUp");
	g_DHookClientConnected = CreateDynamicHook(gamedata, "CTFGameRules::ClientConnected");
	g_DHookFPlayerCanTakeDamage = CreateDynamicHook(gamedata, "CTFGameRules::FPlayerCanTakeDamage");
}

void DHooks_OnClientPutInServer(int client)
{
	if (g_DHookEventKilled)
	{
		g_DHookEventKilled.HookEntity(Hook_Pre, client, DHookCallback_EventKilled_Pre);
	}
	
	if (g_DHookShouldGib)
	{
		g_DHookShouldGib.HookEntity(Hook_Pre, client, DHookCallback_ShouldGib_Pre);
	}
	
	if (g_DHookIsAllowedToPickUpFlag)
	{
		g_DHookIsAllowedToPickUpFlag.HookEntity(Hook_Pre, client, DHookCallback_IsAllowedToPickUpFlag_Post);
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
	
	if (g_DHookFPlayerCanTakeDamage)
	{
		g_DHookFPlayerCanTakeDamage.HookGamerules(Hook_Pre, DHookCallback_FPlayerCanTakeDamage_Pre);
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
			g_DHookPickUp.HookEntity(Hook_Post, entity, DHookCallback_PickUp_Post);
		}
	}
	else if (StrEqual(classname, "obj_teleporter"))
	{
		if (g_DHookCanBeUpgraded)
		{
			g_DHookCanBeUpgraded.HookEntity(Hook_Pre, entity, DHookCallback_CanBeUpgraded_Pre);
		}
	}
	else if (strncmp(classname, "item_currencypack_", 18) == 0)
	{
		if (g_DHookComeToRest)
		{
			g_DHookComeToRest.HookEntity(Hook_Pre, entity, DHookCallback_ComeToRest_Pre);
		}
	}
	else if (StrEqual(classname, "obj_sentrygun"))
	{
		if (g_DHookSetModel)
		{
			g_DHookSetModel.HookEntity(Hook_Post, entity, DHookCallback_SetModel_Post);
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

static MRESReturn DHookCallback_PreClientUpdate_Pre()
{
	// Allows us to have an MvM server with 32 visible player slots
	GameRules_SetProp("m_bPlayingMannVsMachine", false);
	
	return MRES_Handled;
}

static MRESReturn DHookCallback_PreClientUpdate_Post()
{
	// Set it back afterwards
	GameRules_SetProp("m_bPlayingMannVsMachine", true);
	
	return MRES_Handled;
}

static MRESReturn DHookCallback_AllocateBots_Pre(int populator)
{
	// Do not allow the populator to allocate bots
	return MRES_Supercede;
}

static MRESReturn DHookCallback_RestoreCheckpoint_Pre(int populator)
{
	if (!g_bInWaitingForPlayers)
	{
		// The populator calls this multiple times, but we only want it once...
		if (g_flNextRestoreCheckpointTime < GetGameTime())
		{
			SelectNewDefenders();
			
			g_flNextRestoreCheckpointTime = GetGameTime() + 0.1;
		}
	}
	
	return MRES_Handled;
}

/*
 * This detour supercedes the original function and recreates it
 * as accurately as possible to spawn players instead of bots.
 */
static MRESReturn DHookCallback_CTFBotSpawnerSpawn_Pre(Address pThis, DHookReturn ret, DHookParam params)
{
	CTFBotSpawner spawner = CTFBotSpawner(pThis);
	
	float rawHere[3];
	params.GetVector(1, rawHere);
	
	float here[3];
	here = Vector(rawHere[0], rawHere[1], rawHere[2]);
	
	CTFNavArea area = view_as<CTFNavArea>(TheNavMesh.GetNavArea(here));
	if (area && area.HasAttributeTF(NO_SPAWNING))
	{
		if (tf_populator_debug.BoolValue)
		{
			LogMessage("CTFBotSpawner: %3.2f: *** Tried to spawn in a NO_SPAWNING area at (%f, %f, %f)", GetGameTime(), here[0], here[1], here[2]);
		}
		
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
		if (tf_populator_debug.BoolValue)
		{
			LogMessage("CTFBotSpawner: %3.2f: *** No space to spawn at (%f, %f, %f)", GetGameTime(), here[0], here[1], here[2]);
		}
		
		ret.Value = false;
		return MRES_Supercede;
	}
	
	if (GameRules_IsMannVsMachineMode())
	{
		if (spawner.m_class == TFClass_Engineer && spawner.m_defaultAttributes.m_attributeFlags & TELEPORT_TO_HINT && SDKCall_FindHint(true, false) == false)
		{
			if (tf_populator_debug.BoolValue)
			{
				LogMessage("CTFBotSpawner: %3.2f: *** No teleporter hint for engineer", GetGameTime());
			}
			
			ret.Value = false;
			return MRES_Supercede;
		}
	}
	
	// find dead player we can re-use
	int newPlayer = GetRobotToSpawn(spawner.m_defaultAttributes.m_attributeFlags & MINIBOSS);
	
	if (newPlayer != -1)
	{
		Player(newPlayer).ClearAllAttributes();
		
		// Remove any player attributes
		TF2Attrib_RemoveAll(newPlayer);
		
		// clear any old TeleportWhere settings 
		Player(newPlayer).ClearTeleportWhere();
		
		if (g_internalSpawnPoint == INVALID_ENT_REFERENCE || EntRefToEntIndex(g_internalSpawnPoint) == -1)
		{
			g_internalSpawnPoint = EntIndexToEntRef(CreateEntityByName("populator_internal_spawn_point"));
			DispatchSpawn(g_internalSpawnPoint);
		}
		
		char name[MAX_NAME_LENGTH];
		spawner.GetName(name, sizeof(name), "TFBot");
		
		if (mitm_rename_robots.BoolValue)
		{
			Player(newPlayer).SetName(name);
		}
		
		DispatchKeyValueVector(g_internalSpawnPoint, "origin", here);
		Player(newPlayer).SetSpawnPoint(g_internalSpawnPoint);
		
		TFTeam team = TFTeam_Red;
		
		if (GameRules_IsMannVsMachineMode())
		{
			team = TFTeam_Invaders;
		}
		
		TF2_ChangeClientTeam(newPlayer, team);
		
		SetEntProp(newPlayer, Prop_Data, "m_bAllowInstantSpawn", true);
		FakeClientCommand(newPlayer, "joinclass %s", g_aRawPlayerClassNames[spawner.m_class]);
		
		// Set the address of CTFPlayer::m_iszClassIcon from the return value of CTFBotSpawner::GetClassIcon.
		// Simply setting the value using SetEntPropString leads to segfaults, don't do that!
		SetEntData(newPlayer, FindSendPropInfo("CTFPlayer", "m_iszClassIcon"), spawner.GetClassIcon());
		
		Player(newPlayer).ClearEventChangeAttributes();
		for (int i = 0; i < spawner.m_eventChangeAttributes.Count(); ++i)
		{
			Player(newPlayer).AddEventChangeAttributes(spawner.m_eventChangeAttributes.Get(i, 108));
		}
		
		Player(newPlayer).SetTeleportWhere(spawner.m_teleportWhereName);
		
		if (spawner.m_defaultAttributes.m_attributeFlags & MINIBOSS)
		{
			SetEntProp(newPlayer, Prop_Send, "m_bIsMiniBoss", true);
		}
		
		if (spawner.m_defaultAttributes.m_attributeFlags & USE_BOSS_HEALTH_BAR)
		{
			SetEntProp(newPlayer, Prop_Send, "m_bUseBossHealthBar", true);
		}
		
		if (spawner.m_defaultAttributes.m_attributeFlags & AUTO_JUMP)
		{
			Player(newPlayer).SetAutoJump(spawner.m_flAutoJumpMin, spawner.m_flAutoJumpMax);
		}
		
		if (spawner.m_defaultAttributes.m_attributeFlags & BULLET_IMMUNE)
		{
			TF2_AddCondition(newPlayer, TFCond_BulletImmune);
		}
		
		if (spawner.m_defaultAttributes.m_attributeFlags & BLAST_IMMUNE)
		{
			TF2_AddCondition(newPlayer, TFCond_BlastImmune);
		}
		
		if (spawner.m_defaultAttributes.m_attributeFlags & FIRE_IMMUNE)
		{
			TF2_AddCondition(newPlayer, TFCond_FireImmune);
		}
		
		if (GameRules_IsMannVsMachineMode())
		{
			// initialize currency to be dropped on death to zero
			SetEntProp(newPlayer, Prop_Send, "m_nCurrency", 0);
			
			// announce Spies
			if (spawner.m_class == TFClass_Spy)
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
		
		Player(newPlayer).SetScaleOverride(spawner.m_scale);
		
		int nHealth = spawner.m_health;
		
		if (nHealth <= 0.0)
		{
			nHealth = TF2Util_GetEntityMaxHealth(newPlayer);
		}
		
		nHealth = RoundToFloor(float(nHealth) * GetPopulationManager().GetHealthMultiplier(false));
		Player(newPlayer).ModifyMaxHealth(nHealth);
		
		Player(newPlayer).StartIdleSound();
		
		// Add our items first, they'll get replaced below by the normal MvM items if any are needed
		if (GameRules_IsMannVsMachineMode() && (TF2_GetClientTeam(newPlayer) == TFTeam_Invaders))
		{
			// Apply the Rome 2 promo items to each player. They'll be 
			// filtered out for clients that do not have Romevision.
			CMissionPopulator pMission = s_MissionPopulator;
			if (pMission && pMission.m_mission == MISSION_DESTROY_SENTRIES)
			{
				Player(newPlayer).AddItem("tw_sentrybuster");
			}
			else
			{
				Player(newPlayer).AddItem(g_szRomePromoItems_Hat[spawner.m_class]);
				Player(newPlayer).AddItem(g_szRomePromoItems_Misc[spawner.m_class]);
			}
		}
		
		EventChangeAttributes_t pEventChangeAttributes = Player(newPlayer).GetEventChangeAttributes(GetPopulationManager().GetDefaultEventChangeAttributesName());
		if (!pEventChangeAttributes)
		{
			pEventChangeAttributes = spawner.m_defaultAttributes;
		}
		Player(newPlayer).OnEventChangeAttributes(pEventChangeAttributes);
		
		int flag = Player(newPlayer).GetFlagToFetch();
		if (IsValidEntity(flag))
		{
			Player(newPlayer).SetFlagTarget(flag);
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
				if (spawner.m_scale >= tf_mvm_miniboss_scale.FloatValue || GetEntProp(newPlayer, Prop_Send, "m_bIsMiniBoss") && FileExists(g_szBotBossModels[nClassIndex], true))
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
		
		// for easy access in populator spawner callbacks
		m_justSpawnedList.Push(newPlayer);
		
		if (GameRules_IsMannVsMachineMode())
		{
			if (GetEntProp(newPlayer, Prop_Send, "m_bIsMiniBoss"))
			{
				HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_GIANT_CALLOUT", TFTeam_Defenders);
			}
			
			if (!Player(newPlayer).HasPreference(PREF_DISABLE_SPAWN_NOTIFICATION))
			{
				EmitSoundToClient(newPlayer, "ui/system_message_alert.wav", .channel = SNDCHAN_STATIC);
			}
			
			PrintCenterText(newPlayer, "%t", "Invader_Spawned", name);
		}
		
		if (tf_populator_debug.BoolValue)
		{
			LogMessage("%3.2f: Spawned player '%N'", GetGameTime(), newPlayer);
		}
	}
	else
	{
		if (tf_populator_debug.BoolValue)
		{
			LogMessage("CTFBotSpawner: %3.2f: *** Can't find player to spawn.", GetGameTime());
		}
		
		ret.Value = false;
		return MRES_Supercede;
	}
	
	ret.Value = true;
	return MRES_Supercede;
}

static MRESReturn DHookCallback_CSquadSpawner_Post(Address pThis, DHookReturn ret, DHookParam params)
{
	CSquadSpawner spawner = CSquadSpawner(pThis);
	CUtlVector result = CUtlVector(params.Get(2));
	
	if (ret.Value && result)
	{
		// create the squad
		CTFBotSquad squad = CTFBotSquad.Create();
		if (squad)
		{
			squad.SetFormationSize(spawner.m_formationSize);
			squad.SetShouldPreserveSquad(spawner.m_bShouldPreserveSquad);
			
			for (int i = 0; i < result.Count(); ++i)
			{
				int bot = GetEntityFromHandle(Deref(result.Get(i)));
				if (IsEntityClient(bot))
				{
					Player(bot).JoinSquad(squad);
				}
			}
		}
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_PopulationManagerUpdate_Pre(int populator)
{
	// allows spawners to freely switch teams of players
	g_bAllowTeamChange = true;
	
	return MRES_Handled;
}

static MRESReturn DHookCallback_PopulationManagerUpdate_Post(int populator)
{
	g_bAllowTeamChange = false;
	
	return MRES_Handled;
}

static MRESReturn DHookCallback_PeriodicSpawnPopulatorUpdate_Post(Address pThis)
{
	for (int i = 0; i < m_justSpawnedList.Length; i++)
	{
		int player = m_justSpawnedList.Get(i);
		
		// what bot should do after spawning at teleporter exit
		if (s_spawnLocationResult == SPAWN_LOCATION_TELEPORTER)
		{
			OnBotTeleported(player);
		}
	}
	
	// after we are done, clear the list
	m_justSpawnedList.Clear();
	
	return MRES_Handled;
}

static MRESReturn DHookCallback_WaveSpawnPopulatorUpdate_Post(Address pThis)
{
	for (int i = 0; i < m_justSpawnedList.Length; i++)
	{
		int player = m_justSpawnedList.Get(i);
		
		SetEntProp(player, Prop_Send, "m_nCurrency", 0);
		SetEntData(player, GetOffset("CTFPlayer::m_pWaveSpawnPopulator"), pThis);
		
		// Allows client UI to know if a specific spawner is active
		SetMannVsMachineWaveClassActive(GetEntData(player, FindSendPropInfo("CTFPlayer", "m_iszClassIcon")));
		
		if (CWaveSpawnPopulator(pThis).IsSupportWave())
		{
			Player(player).MarkAsSupportEnemy();
		}
		
		if (CWaveSpawnPopulator(pThis).IsLimitedSupportWave())
		{
			Player(player).MarkAsLimitedSupportEnemy();
		}
		
		// what bot should do after spawning at teleporter exit
		if (s_spawnLocationResult == SPAWN_LOCATION_TELEPORTER)
		{
			OnBotTeleported(player);
		}
	}
	
	// after we are done, clear the list
	m_justSpawnedList.Clear();
	
	return MRES_Handled;
}

static MRESReturn DHookCallback_MissionPopulatorUpdateMission_Pre(Address pThis, DHookReturn ret, DHookParam params)
{
	CMissionPopulator populator = CMissionPopulator(pThis);
	MissionType mission = params.Get(1);
	
	ArrayList livePlayerList = new ArrayList();
	
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (TF2_GetClientTeam(client) != TFTeam_Invaders)
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		livePlayerList.Push(client);
	}
	
	s_activeMissionMembers = 0;
	
	for (int i = 0; i < livePlayerList.Length; i++)
	{
		int player = livePlayerList.Get(i);
		if (Player(player).HasMission(mission))
		{
			++s_activeMissionMembers;
		}
	}
	
	if (s_activeMissionMembers > 0)
	{
		// wait until prior mission is dead
		
		// cooldown is time after death of last mission member
		m_cooldownTimer.Start(populator.m_cooldownDuration);
		
		delete livePlayerList;
		ret.Value = false;
		return MRES_Supercede;
	}
	
	if (!m_cooldownTimer.IsElapsed())
	{
		delete livePlayerList;
		ret.Value = false;
		return MRES_Supercede;
	}
	
	s_nSniperCount = 0;
	for (int i = 0; i < livePlayerList.Length; i++)
	{
		int liveBot = livePlayerList.Get(i);
		if (TF2_GetPlayerClass(liveBot) == TFClass_Sniper)
		{
			s_nSniperCount++;
		}
	}
	
	delete livePlayerList;
	return MRES_Handled;
}

static MRESReturn DHookCallback_MissionPopulatorUpdateMission_Post(Address pThis, DHookReturn ret, DHookParam params)
{
	MissionType mission = params.Get(1);
	
	for (int i = 0; i < m_justSpawnedList.Length; i++)
	{
		int player = m_justSpawnedList.Get(i);
		
		Player(player).SetFlagTarget(INVALID_ENT_REFERENCE);
		Player(player).SetMission(mission);
		SetEntData(player, GetOffset("CTFPlayer::m_bIsMissionEnemy"), true, 1);
		
		int iFlags = MVM_CLASS_FLAG_MISSION;
		if (GetEntProp(player, Prop_Send, "m_bIsMiniBoss"))
		{
			iFlags |= MVM_CLASS_FLAG_MINIBOSS;
		}
		else if (Player(player).HasAttribute(ALWAYS_CRIT))
		{
			iFlags |= MVM_CLASS_FLAG_ALWAYSCRIT;
		}
		IncrementMannVsMachineWaveClassCount(GetEntData(player, FindSendPropInfo("CTFPlayer", "m_iszClassIcon")), iFlags);
		
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
	
	// after we are done, clear the list
	m_justSpawnedList.Clear();
	
	return MRES_Handled;
}

static MRESReturn DHookCallback_UpdateMissionDestroySentries_Pre(Address pThis, DHookReturn ret)
{
	CMissionPopulator populator = CMissionPopulator(pThis);
	s_MissionPopulator = populator;
	
	if (!m_cooldownTimer.IsElapsed())
	{
		ret.Value = false;
		return MRES_Supercede;
	}
	
	if (!m_checkForDangerousSentriesTimer.IsElapsed())
	{
		ret.Value = false;
		return MRES_Supercede;
	}
	
	if (GetPopulationManager().IsSpawningPaused())
	{
		ret.Value = false;
		return MRES_Supercede;
	}
	
	m_checkForDangerousSentriesTimer.Start(GetRandomFloat(5.0, 10.0));
	
	// collect all of the dangerous sentries
	ArrayList dangerousSentryList = new ArrayList();
	
	int nDmgLimit = 0;
	int nKillLimit = 0;
	GetPopulationManager().GetSentryBusterDamageAndKillThreshold(nDmgLimit, nKillLimit);
	
	int obj = MaxClients + 1;
	while ((obj = FindEntityByClassname(obj, "obj_*")) != -1)
	{
		if (TF2_GetObjectType(obj) == TFObject_Sentry)
		{
			// Disposable sentries are not valid targets
			if (GetEntProp(obj, Prop_Send, "m_bDisposableBuilding"))
				continue;
			
			if (view_as<TFTeam>(GetEntProp(obj, Prop_Data, "m_iTeamNum")) == TFTeam_Defenders)
			{
				int sentryOwner = GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
				if (sentryOwner != -1)
				{
					int nDmgDone = RoundToFloor(GetEntDataFloat(sentryOwner, GetOffset("CTFPlayer::m_accumulatedSentryGunDamageDealt")));
					int nKillsMade = GetEntData(sentryOwner, GetOffset("CTFPlayer::m_accumulatedSentryGunKillCount"));
					
					if (nDmgDone >= nDmgLimit || nKillsMade >= nKillLimit)
					{
						dangerousSentryList.Push(obj);
					}
				}
			}
		}
	}
	
	ArrayList livePlayerList = new ArrayList();
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (TF2_GetClientTeam(client) != TFTeam_Invaders)
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		livePlayerList.Push(client);
	}
	
	// dispatch a sentry busting squad for each dangerous sentry
	bool didSpawn = false;
	
	for (int i = 0; i < dangerousSentryList.Length; ++i)
	{
		int targetSentry = dangerousSentryList.Get(i);
		
		// if there is already a squad out there destroying this sentry, don't spawn another one
		int j;
		for (j = 0; j < livePlayerList.Length; ++j)
		{
			int bot = livePlayerList.Get(j);
			if (Player(bot).HasMission(MISSION_DESTROY_SENTRIES) && Player(bot).GetMissionTarget() == targetSentry)
			{
				// there is already a sentry busting squad active for this sentry
				break;
			}
		}
		
		if (j < livePlayerList.Length)
		{
			continue;
		}
		
		// spawn a sentry buster squad to destroy this sentry
		float vSpawnPosition[3];
		SpawnLocationResult spawnLocationResult = SDKCall_FindSpawnLocation(populator.m_where, vSpawnPosition);
		if (spawnLocationResult != SPAWN_LOCATION_NOT_FOUND)
		{
			// We don't actually pass a CUtlVector because it would require fetching or creating one in memory.
			// This is very tedious, so we just use our temporary list hack.
			if (populator.m_spawner && SDKCall_IPopulationSpawnerSpawn(populator.m_spawner, vSpawnPosition))
			{
				// success
				if (tf_populator_debug.BoolValue)
				{
					LogMessage("MANN VS MACHINE: %3.2f: <<<< Spawning Sentry Busting Mission >>>>", GetGameTime());
				}
				
				for (int k = 0; k < m_justSpawnedList.Length; ++k)
				{
					int bot = m_justSpawnedList.Get(k);
					
					Player(bot).SetFlagTarget(INVALID_ENT_REFERENCE);
					Player(bot).SetMission(MISSION_DESTROY_SENTRIES);
					Player(bot).SetMissionTarget(targetSentry);
					
					SetEntData(bot, GetOffset("CTFPlayer::m_bIsMissionEnemy"), true, 1);
					
					didSpawn = true;
					
					SetVariantString(g_szBotBossSentryBusterModel);
					AcceptEntityInput(bot, "SetCustomModel");
					SetEntProp(bot, Prop_Send, "m_bUseClassAnimations", true);
					SetEntProp(bot, Prop_Data, "m_bloodColor", DONT_BLEED);
					
					SetVariantInt(1);
					AcceptEntityInput(bot, "SetForcedTauntCam");
					
					int iFlags = MVM_CLASS_FLAG_MISSION;
					if (GetEntProp(bot, Prop_Send, "m_bIsMiniBoss"))
					{
						iFlags |= MVM_CLASS_FLAG_MINIBOSS;
					}
					if (Player(bot).HasAttribute(ALWAYS_CRIT))
					{
						iFlags |= MVM_CLASS_FLAG_ALWAYSCRIT;
					}
					IncrementMannVsMachineWaveClassCount(CTFBotSpawner(populator.m_spawner).GetClassIcon(k), iFlags);
					
					HaveAllPlayersSpeakConceptIfAllowed("TLK_MVM_SENTRY_BUSTER", TFTeam_Defenders);
					
					// what bot should do after spawning at teleporter exit
					if (spawnLocationResult == SPAWN_LOCATION_TELEPORTER)
					{
						OnBotTeleported(bot);
					}
				}
				
				// after we are done, clear the list
				m_justSpawnedList.Clear();
			}
		}
		else if (tf_populator_debug.BoolValue)
		{
			LogError("MissionPopulator: %3.2f: Can't find a place to spawn a sentry destroying squad", GetGameTime());
		}
	}
	
	if (didSpawn)
	{
		float flCoolDown = populator.m_cooldownDuration;
		
		CWave wave = GetPopulationManager().GetCurrentWave();
		if (wave)
		{
			wave.m_nSentryBustersSpawned++;
			
			if (wave.m_nSentryBustersSpawned > 1)
			{
				TFGameRules_BroadcastSound(255, "Announcer.MVM_Sentry_Buster_Alert_Another");
			}
			else
			{
				TFGameRules_BroadcastSound(255, "Announcer.MVM_Sentry_Buster_Alert");
			}
			
			flCoolDown = populator.m_cooldownDuration + wave.m_nSentryBustersSpawned * populator.m_cooldownDuration;
			
			wave.m_nSentryBustersSpawned = 0;
		}
		
		m_cooldownTimer.Start(flCoolDown);
	}
	
	delete dangerousSentryList;
	delete livePlayerList;
	
	ret.Value = didSpawn;
	return MRES_Supercede;
}

static MRESReturn DHookCallback_UpdateMissionDestroySentries_Post(Address pThis, DHookReturn ret)
{
	s_MissionPopulator = CMissionPopulator(Address_Null);
	
	return MRES_Handled;
}

static MRESReturn DHookCallback_InputChangeBotAttributes_Pre(int populatorInterface, DHookParam params)
{
	Address pszEventName = params.GetObjectVar(1, 0x8, ObjectValueType_Int);
	
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

static MRESReturn DHookCallback_GetTeamAssignmentOverride_Pre(DHookReturn ret, DHookParam params)
{
	int player = params.Get(1);
	TFTeam nDesiredTeam = params.Get(2);
	
	if (IsClientSourceTV(player))
	{
		return MRES_Ignored;
	}
	else if (g_bInWaitingForPlayers)
	{
		// funnel players into defender team during waiting for players so they can run around
		ret.Value = TFTeam_Defenders;
		return MRES_Supercede;
	}
	else if (g_bAllowTeamChange || (mitm_developer.BoolValue && !IsFakeClient(player)))
	{
		// allow player through
		GameRules_SetProp("m_bPlayingMannVsMachine", false);
		return MRES_Handled;
	}
	else
	{
		if (nDesiredTeam == TFTeam_Spectator && TF2_GetClientTeam(player) == TFTeam_Invaders && !mitm_invader_allow_suicide.BoolValue)
		{
			PrintCenterText(player, "%t", "Invader_NotAllowedToSuicide");
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
			else if (Player(client).IsInvader())
				iInvaderCount++;
		}
		
		float flReqRatio = float(MaxClients - mitm_defender_max_count.IntValue) / mitm_defender_max_count.FloatValue;
		float flCurRatio = float(iInvaderCount) / float(iDefenderCount);
		if (flCurRatio < flReqRatio || Player(player).HasPreference(PREF_DISABLE_DEFENDER) || Player(player).HasPreference(PREF_DISABLE_SPAWNING))
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

static MRESReturn DHookCallback_GetTeamAssignmentOverride_Post(DHookReturn ret, DHookParam params)
{
	if (g_bAllowTeamChange)
	{
		GameRules_SetProp("m_bPlayingMannVsMachine", true);
	}
	
	return MRES_Handled;
}

static MRESReturn DHookCallback_GetLoadoutItem_Pre(int player, DHookReturn ret, DHookParam params)
{
	if (IsClientInGame(player) && TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		// Generate base items for robot players
		GameRules_SetProp("m_bIsInTraining", true);
	}
	
	return MRES_Handled;
}

static MRESReturn DHookCallback_GetLoadoutItem_Post(int player, DHookReturn ret, DHookParam params)
{
	if (IsClientInGame(player) && TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		GameRules_SetProp("m_bIsInTraining", false);
	}
	
	return MRES_Handled;
}

static MRESReturn DHookCallback_CheckInstantLoadoutRespawn_Pre(int player)
{
	if (TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		// Never allow invaders to respawn with a new loadout, this breaks spawners
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_ShouldForceAutoTeam_Pre(int player, DHookReturn ret)
{
	// don't allow game logic to force players on a team
	ret.Value = false;
	return MRES_Supercede;
}

static MRESReturn DHookCallback_DoClassSpecialSkill_Pre(int player, DHookReturn ret)
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

static MRESReturn DHookCallback_RemoveAllOwnedEntitiesFromWorld_Pre(int player, DHookParam params)
{
	if (Player(player).HasAttribute(RETAIN_BUILDINGS))
	{
		// keep this bot's buildings
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CanBuild_Pre(int player, DHookReturn ret, DHookParam params)
{
	if (TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		// disallow human robot engineers from building multiple sentries
		SetEntityFlags(player, GetEntityFlags(player) & ~FL_FAKECLIENT);
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_CanBuild_Post(int player, DHookReturn ret, DHookParam params)
{
	if (TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		SetEntityFlags(player, GetEntityFlags(player) | FL_FAKECLIENT);
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_AllowedToHealTarget_Pre(int medigun, DHookReturn ret, DHookParam params)
{
	int target = params.Get(1);
	int owner = GetEntPropEnt(medigun, Prop_Send, "m_hOwnerEntity");
	
	if (TF2_GetClientTeam(owner) == TFTeam_Invaders)
	{
		// medics in a squad should only ever heal their squad leader
		if (Player(owner).IsInASquad() && Player(owner).GetSquad().GetLeader() != -1)
		{
			CTFBotSquad squad = Player(owner).GetSquad();
			if (squad.IsLeader(owner) || squad.IsLeader(target))
			{
				// allow healing the squad leader, or everyone if we are the leader
				return MRES_Ignored;
			}
			
			PrintCenterText(owner, "%t", "Medic_Squad_NotAllowedToHeal", squad.GetLeader());
			
			// disallow healing everyone else
			ret.Value = false;
			return MRES_Supercede;
		}
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_FindSpawnLocation_Post(Address where, DHookReturn ret, DHookParam params)
{
	// Store for use in populator callbacks.
	// We can't use CWaveSpawnPopulator::m_spawnLocationResult because it gets overridden in some cases.
	s_spawnLocationResult = ret.Value;
	
	return MRES_Handled;
}

static MRESReturn DHookCallback_ShouldHitEntity_Post(Address pFilter, DHookReturn ret, DHookParam params)
{
	int me = GetEntityFromAddress(Deref(pFilter + view_as<Address>(0x4)));
	int entity = GetEntityFromAddress(params.Get(1));
	
	if (IsEntityClient(entity))
	{
		if (GameRules_IsMannVsMachineMode())
		{
			if (Player(entity).HasMission(MISSION_DESTROY_SENTRIES))
			{
				// Don't collide with sentry busters since they don't collide with us
				ret.Value = false;
				return MRES_Supercede;
			}
			
			if (Player(me).HasMission(MISSION_DESTROY_SENTRIES))
			{
				// Sentry Busters don't collide with enemies (so they can't be body-blocked)
				ret.Value = false;
				return MRES_Supercede;
			}
		}
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_StartLagCompensation_Pre(DHookParam params)
{
	int player = params.Get(1);
	
	if (TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		// re-enable lag compensation for our "human bots"
		SetEntityFlags(player, GetEntityFlags(player) & ~FL_FAKECLIENT);
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_StartLagCompensation_Post(DHookParam params)
{
	int player = params.Get(1);
	
	if (TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		SetEntityFlags(player, GetEntityFlags(player) | FL_FAKECLIENT);
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_DoTeleporterOverride_Post(DHookReturn ret, DHookParam params)
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
		
		if (GetEntProp(obj, Prop_Send, "m_bCarried"))
			continue;
		
		if (GetEntProp(obj, Prop_Send, "m_bHasSapper"))
			continue;
		
		if (GetEntProp(obj, Prop_Send, "m_bPlasmaDisable"))
			continue;
		
		char szSpawnPointName[64];
		spawnEnt.GetPropString(Prop_Data, "m_iName", szSpawnPointName, sizeof(szSpawnPointName));
		
		for (int iTelePoints = 0; iTelePoints < Entity(obj).GetTeleportWhere().Length; ++iTelePoints)
		{
			char teleportWhereName[64];
			Entity(obj).GetTeleportWhere().GetString(iTelePoints, teleportWhereName, sizeof(teleportWhereName));
			
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

static MRESReturn DHookCallback_OnBotTeleported_Pre(DHookParam params)
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
	TeleportEntity(bot, .angles = angles);
	
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

static MRESReturn DHookCallback_EventKilled_Pre(int player, DHookParam params)
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
			// in MVM, when an engineer dies, we need to decouple his objects so they stay alive when his bot slot gets recycled
			while (TF2Util_GetPlayerObjectCount(player) > 0)
			{
				// set to not have owner
				int obj = TF2Util_GetPlayerObject(player, 0);
				if (obj != -1)
				{
					SetEntityOwner(obj, -1);
					SetEntPropEnt(obj, Prop_Send, "m_hBuilder", -1);
				}
				SDKCall_RemoveObject(player, obj);
			}
			
			// unown engineer nest if owned any
			int hint = MaxClients + 1;
			while ((hint = FindEntityByClassname(hint, "bot_hint_*")) != -1)
			{
				if (GetEntPropEnt(hint, Prop_Send, "m_hOwnerEntity") == player)
				{
					SetEntityOwner(hint, -1);
				}
			}
			
			bool bShouldAnnounceLastEngineerBotDeath = Player(player).HasAttribute(TELEPORT_TO_HINT);
			if (bShouldAnnounceLastEngineerBotDeath)
			{
				for (int client = 1; client <= MaxClients; client++)
				{
					if (!IsClientInGame(client))
						continue;
					
					if (TF2_GetClientTeam(client) != TFTeam_Invaders)
						continue;
					
					if (!IsPlayerAlive(client))
						continue;
					
					if (client != player && TF2_GetPlayerClass(client) == TFClass_Engineer)
					{
						bShouldAnnounceLastEngineerBotDeath = false;
						break;
					}
				}
			}
			
			if (bShouldAnnounceLastEngineerBotDeath)
			{
				bool bEngineerTeleporterInTheWorld = false;
				int obj = MaxClients + 1;
				while ((obj = FindEntityByClassname(obj, "obj_teleporter")) != -1)
				{
					if (TF2_GetObjectType(obj) == TFObject_Teleporter && view_as<TFTeam>(GetEntProp(obj, Prop_Data, "m_iTeamNum")) == TFTeam_Invaders)
					{
						bEngineerTeleporterInTheWorld = true;
					}
				}
				
				if (bEngineerTeleporterInTheWorld)
				{
					TFGameRules_BroadcastSound(255, "Announcer.MVM_An_Engineer_Bot_Is_Dead_But_Not_Teleporter");
				}
				else
				{
					TFGameRules_BroadcastSound(255, "Announcer.MVM_An_Engineer_Bot_Is_Dead");
				}
			}
		}
		
		if (Player(player).IsInASquad())
		{
			Player(player).LeaveSquad();
		}
		
		Player(player).StopIdleSound();
	}
	
	return MRES_Handled;
}

static MRESReturn DHookCallback_ShouldGib_Pre(int player, DHookReturn ret, DHookParam params)
{
	// only gib giant/miniboss
	if (GameRules_IsMannVsMachineMode() && (GetEntProp(player, Prop_Send, "m_bIsMiniBoss") || GetEntPropFloat(player, Prop_Send, "m_flModelScale") > 1.0))
	{
		ret.Value = true;
		return MRES_Supercede;
	}
	
	return MRES_Handled;
}

static MRESReturn DHookCallback_IsAllowedToPickUpFlag_Post(int player, DHookReturn ret)
{
	// only the leader of a squad can pick up the flag
	if (Player(player).IsInASquad() && !Player(player).GetSquad().IsLeader(player))
	{
		ret.Value = false;
		return MRES_Supercede;
	}
	
	// mission bots can't pick up the flag
	if (Player(player).IsOnAnyMission())
	{
		ret.Value = false;
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_EntSelectSpawnPoint_Pre(int player, DHookReturn ret)
{
	// override normal spawn behavior to spawn robots at the right place
	if (IsValidEntity(Player(player).m_spawnPointEntity))
	{
		ret.Value = Player(player).m_spawnPointEntity;
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_PassesFilterImpl_Pre(int filter, DHookReturn ret, DHookParam params)
{
	int entity = params.Get(2);
	
	if (IsEntityClient(entity) && TF2_GetClientTeam(entity) == TFTeam_Invaders)
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
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_PickUp_Pre(int item, DHookParam params)
{
	int player = params.Get(1);
	
	if (GameRules_IsMannVsMachineMode() && TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		// do not trip up the assert_cast< CTFBot* >
		SetEntityFlags(player, GetEntityFlags(player) & ~FL_FAKECLIENT);
		
		if (Player(player).HasAttribute(IGNORE_FLAG))
			return MRES_Supercede;
		
		Player(player).SetFlagTarget(EntIndexToEntRef(item));
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_PickUp_Post(int item, DHookParam params)
{
	int player = params.Get(1);
	
	if (GameRules_IsMannVsMachineMode() && TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		SetEntityFlags(player, GetEntityFlags(player) | FL_FAKECLIENT);
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_SetModel_Post(int entity, DHookParam params)
{
	char szModelName[PLATFORM_MAX_PATH];
	params.GetString(1, szModelName, sizeof(szModelName));
	
	int glow = Entity(entity).m_glowEntity;
	if (IsValidEntity(glow))
	{
		// existing glow, update the model
		SetEntityModel(glow, szModelName);
	}
	else
	{
		// no existing glow, create one!
		Entity(entity).m_glowEntity = EntRefToEntIndex(CreateEntityGlow(entity));
	}
	
	return MRES_Handled;
}

static MRESReturn DHookCallback_CanBeUpgraded_Pre(int obj, DHookReturn ret, DHookParam params)
{
	int player = params.Get(1);
	
	if (TF2_GetClientTeam(player) == TFTeam_Invaders)
	{
		if (TF2_GetObjectType(obj) == TFObject_Teleporter)
		{
			ret.Value = false;
			return MRES_Supercede;
		}
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_ComeToRest_Pre(int item)
{
	float origin[3];
	GetEntPropVector(item, Prop_Data, "m_vecAbsOrigin", origin);
	
	// if we've come to rest in the enemy spawn, just grant the money to the player
	CTFNavArea area = view_as<CTFNavArea>(TheNavMesh.GetNavArea(origin));
	
	if (area && (area.HasAttributeTF(BLUE_SPAWN_ROOM) || area.HasAttributeTF(RED_SPAWN_ROOM)))
	{
		SDKCall_DistributeCurrencyAmount(GetEntData(item, GetOffset("CCurrencyPack::m_nAmount")));
		SetEntData(item, GetOffset("CCurrencyPack::m_bTouched"), true, 1);
		RemoveEntity(item);
		
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

static MRESReturn DHookCallback_ClientConnected_Pre(DHookReturn ret, DHookParam params)
{
	// MvM will start rejecting connections if the server has 10 humans
	ret.Value = true;
	return MRES_Supercede;
}

static MRESReturn DHookCallback_FPlayerCanTakeDamage_Pre(DHookReturn ret, DHookParam params)
{
	if (g_bForceFriendlyFire)
	{
		params.SetObjectVar(3, GetOffset("CTakeDamageInfo::m_bForceFriendlyFire"), ObjectValueType_Bool, true);
		return MRES_ChangedHandled;
	}
	
	return MRES_Ignored;
}
