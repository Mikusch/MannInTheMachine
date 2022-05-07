/*
 * Copyright (C) 2021  Mikusch
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

enum struct PopulatorData
{
	Address spawner;
	Address populator;
}

static DynamicHook g_DHookEventKilled;

static ArrayList g_Populators;

static int g_InternalSpawnPoint = INVALID_ENT_REFERENCE;

void DHooks_Initialize(GameData gamedata)
{
	g_Populators = new ArrayList(sizeof(PopulatorData));
	
	CreateDynamicDetour(gamedata, "CTFBotSpawner::CTFBotSpawner", DHookCallback_CTFBotSpawner_Pre);
	CreateDynamicDetour(gamedata, "CPopulationManager::AllocateBots", DHookCallback_AllocateBots_Pre);
	CreateDynamicDetour(gamedata, "CTFBotSpawner::Spawn", DHookCallback_Spawn_Pre);
	CreateDynamicDetour(gamedata, "CTFGameRules::GetTeamAssignmentOverride", DHookCallback_GetTeamAssignmentOverride_Pre, DHookCallback_GetTeamAssignmentOverride_Post);
	
	g_DHookEventKilled = CreateDynamicHook(gamedata, "CTFPlayer::Event_Killed");
}

void DHooks_HookClient(int client)
{
	if (g_DHookEventKilled)
	{
		g_DHookEventKilled.HookEntity(Hook_Pre, client, DHookCallback_EventKilled_Pre);
		g_DHookEventKilled.HookEntity(Hook_Post, client, DHookCallback_EventKilled_Post);
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

public MRESReturn DHookCallback_CTFBotSpawner_Pre(Address spawner, DHookReturn ret, DHookParam param)
{
	PopulatorData data;
	data.spawner = spawner;
	data.populator = param.Get(1);
	
	g_Populators.PushArray(data, sizeof(data));
	
	return MRES_Ignored;
}

public MRESReturn DHookCallback_AllocateBots_Pre(int populator)
{
	// No bots in MY home!
	return MRES_Supercede;
}

TFClassType GetClass(Address spawner)
{
	return view_as<TFClassType>(LoadFromAddress(spawner + view_as<Address>(g_OffsetClass), NumberType_Int32));
}

// Copy of CTFBotSpawner::GetClassIcon
int GetClassIcon(Address spawner, char[] buffer, int maxlen)
{
	Address string_t = view_as<Address>(LoadFromAddress(spawner + view_as<Address>(g_OffsetClassIcon), NumberType_Int32));
	if (string_t != Address_Null)
		return UTIL_StringtToCharArray(string_t, buffer, maxlen);
	
	return strcopy(buffer, maxlen, g_aRawPlayerClassNamesShort[GetClass(spawner)]);
}

int GetHealth(Address spawner)
{
	return LoadFromAddress(spawner + view_as<Address>(g_OffsetHealth), NumberType_Int32);
}

float GetScale(Address spawner)
{
	return view_as<float>(LoadFromAddress(spawner + view_as<Address>(g_OffsetScale), NumberType_Int32));
}

public MRESReturn DHookCallback_Spawn_Pre(Address spawner, DHookReturn ret, DHookParam params)
{
	EventChangeAttributes_t m_defaultAttributes = CTFBotSpawner(spawner).m_defaultAttributes;
	
	// The player spawning logic.
	// This is essentially a copy of CTFBotSpawner::Spawn, doing everything it does on human players instead.
	
	int newPlayer = -1;
	
	float here[3];
	params.GetVector(1, here);
	
	TFClassType m_class = GetClass(spawner);
	int m_health = GetHealth(spawner);
	float m_scale = GetScale(spawner);
	
	char m_iszClassIcon[64];
	GetClassIcon(spawner, m_iszClassIcon, sizeof(m_iszClassIcon));
	
	if (IsMannVsMachineMode())
	{
		if (GameRules_GetRoundState() != RoundState_RoundRunning)
		{
			ret.Value = false;
			return MRES_Supercede;
		}
	}
	
	/*
	// the ground may be variable here, try a few heights
	float z;
	for( z = 0.0f; z<StepHeight; z += 4.0f )
	{
		here.z = rawHere.z + StepHeight;

		if ( IsSpaceToSpawnHere( here ) )
		{
			break;
		}
	}
	
	if ( z >= StepHeight )
	{
		if ( tf_populator_debug.GetBool() ) 
		{
			DevMsg( "CTFBotSpawner: %3.2f: *** No space to spawn at (%f, %f, %f)\n", gpGlobals->curtime, here.x, here.y, here.z );
		}
		return false;
	}
	*/
	
	/*if ( TFGameRules() && TFGameRules()->IsMannVsMachineMode() )
	{
		if ( m_class == TF_CLASS_ENGINEER && m_defaultAttributes.m_attributeFlags & CTFBot::TELEPORT_TO_HINT && CTFBotMvMEngineerHintFinder::FindHint( true, false ) == false )
		{
			if ( tf_populator_debug.GetBool() ) 
			{
				DevMsg( "CTFBotSpawner: %3.2f: *** No teleporter hint for engineer\n", gpGlobals->curtime );
			}

			return false;
		}
	}
	*/
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (TF2_GetClientTeam(client) != TFTeam_Spectator)
			continue;
		
		newPlayer = client;
		g_PlayerAttributes[newPlayer].attributeFlags = 0;
		break;
	}
	
	// if ( newBot == NULL )
	// TODO: A lot of shit
	if (newPlayer == -1)
	{
		LogMessage("Not enough players in the server to spawn a robot");
	}
	else
	{
		LogMessage("Spawning %N as robot", newPlayer);
	}
	
	if (newPlayer != -1)
	{
		// Remove any player attributes
		SDKCall_RemovePlayerAttributes(newPlayer, false);
		
		/*
		// clear any old TeleportWhere settings 
		newBot->ClearTeleportWhere();
		*/
		
		if (g_InternalSpawnPoint == INVALID_ENT_REFERENCE || EntRefToEntIndex(g_InternalSpawnPoint) == -1)
		{
			g_InternalSpawnPoint = EntIndexToEntRef(CreateEntityByName("populator_internal_spawn_point"));
			DispatchSpawn(g_InternalSpawnPoint);
		}
		
		DispatchKeyValueVector(g_InternalSpawnPoint, "origin", here);
		g_PlayerAttributes[newPlayer].spawnPoint = g_InternalSpawnPoint;
		
		TFTeam team = TFTeam_Red;
		
		if (IsMannVsMachineMode())
		{
			team = TFTeam_Blue;
		}
		
		// TODO: CTFBot::ChangeTeam does a little bit more, like making team switches silent
		TF2_ChangeClientTeam(newPlayer, team);
		
		SetEntProp(newPlayer, Prop_Data, "m_bAllowInstantSpawn", true);
		FakeClientCommand(newPlayer, "joinclass %s", g_aRawPlayerClassNames[m_class]);
		PrintToChatAll("Setting %N icon as %s", newPlayer, m_iszClassIcon);
		//SetEntPropString(newPlayer, Prop_Send, "m_iszClassIcon", m_iszClassIcon);
		
		int index = g_Populators.FindValue(spawner, PopulatorData::spawner);
		if (index != -1)
		{
			Address populator = g_Populators.Get(index);
			PrintToChatAll("Populator used for spawn: %X", populator);
		}
		else
		{
			LogError("No populator found for spawner with address %X", spawner);
		}
		
		// TODO: Implement the EventChangeAttributes system
		//ClearEventChangeAttributes();
		/*CUtlVector eventChangeAttributes = CUtlVector(address + view_as<Address>(0x0A4));
		PrintToChatAll("m_eventChangeAttributes:size %d",eventChangeAttributes.Count());
		for ( int i=0; i<eventChangeAttributes.Count(); ++i )
		{
			PrintToChatAll("%i: %i", i, eventChangeAttributes.Get(i, 11));
			int skill = LoadFromAddress(eventChangeAttributes.Get(i, 11) + 0x14, NumberType_Int32);
			PrintToServer("skill %d", skill);
			//3C LInux
			//newBot->AddEventChangeAttributes( &m_eventChangeAttributes[i] );
		}*/
		
		// newBot->SetTeleportWhere( m_teleportWhereName );
		
		if (m_defaultAttributes.m_attributeFlags & MINIBOSS)
		{
			SetEntProp(newPlayer, Prop_Send, "m_bIsMiniBoss", true);
		}
		
		if (m_defaultAttributes.m_attributeFlags & USE_BOSS_HEALTH_BAR)
		{
			SetEntProp(newPlayer, Prop_Send, "m_bUseBossHealthBar", true);
		}
		
		if (m_defaultAttributes.m_attributeFlags & BULLET_IMMUNE)
		{
			TF2_AddCondition(newPlayer, TFCond_BulletImmune);
		}
		
		if (m_defaultAttributes.m_attributeFlags & BLAST_IMMUNE)
		{
			TF2_AddCondition(newPlayer, TFCond_BlastImmune);
		}
		
		if (m_defaultAttributes.m_attributeFlags & FIRE_IMMUNE)
		{
			TF2_AddCondition(newPlayer, TFCond_FireImmune);
		}
		
		OnEventChangeAttributes(newPlayer, m_defaultAttributes);
		
		if (IsMannVsMachineMode())
		{
			// initialize currency to be dropped on death to zero
			SetEntProp(newPlayer, Prop_Send, "m_nCurrency", 0);
			
			// announce Spies
			if (m_class == TFClass_Spy)
			{
				int spyCount = 0;
				for (int client = 1; client <= MaxClients; client++)
				{
					if (IsClientInGame(client) && IsPlayerAlive(client) && TF2_GetClientTeam(client) == TFTeam_Blue)
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
		
		// SetScaleOverride
		// TODO: Can be done better
		g_PlayerAttributes[newPlayer].scaleOverride = m_scale;
		SetModelScale(newPlayer, m_scale > 0.0 ? m_scale : 1.0);
		
		int nHealth = m_health;
		
		if (nHealth <= 0.0)
		{
			nHealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, newPlayer);
		}
		
		// TODO: Support populator health multiplier
		// nHealth *= g_pPopulationManager->GetHealthMultiplier( false );
		ModifyMaxHealth(newPlayer, nHealth);
		//PrintToChat(newPlayer, "%N MAX HEALTH %f", newPlayer, nHealth);
		
		Player(newPlayer).StartIdleSound();
		
		// TODO: Spawn with full charge
		
		TFClassType nClassIndex = TF2_GetPlayerClass(newPlayer);
		
		bool halloweenPopFile = false;
		if (halloweenPopFile)
		{
			// TODO: Implement Halloween Pop File
		}
		else
		{
			if (nClassIndex >= TFClass_Scout && nClassIndex <= TFClass_Engineer)
			{
				if (m_scale >= FindConVar("tf_mvm_miniboss_scale").FloatValue || GetEntProp(newPlayer, Prop_Send, "m_bIsMiniBoss") && FileExists(g_szBotBossModels[nClassIndex], true))
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
		
		// Code that normally gets executed in CMissionPopulator::UpdateMission after the spawner is done.
		// We don't have easy access to that, so we do it right here instead.
		PostRobotSpawn(newPlayer);
	}
	
	// Finally, suppress the original function
	ret.Value = false;
	return MRES_Supercede;
}

public MRESReturn DHookCallback_GetTeamAssignmentOverride_Pre(DHookReturn ret, DHookParam params)
{
	GameRules_SetProp("m_bPlayingMannVsMachine", false);
	
	return MRES_Ignored;
}

public MRESReturn DHookCallback_GetTeamAssignmentOverride_Post(DHookReturn ret, DHookParam params)
{
	GameRules_SetProp("m_bPlayingMannVsMachine", true);
	
	return MRES_Ignored;
}

public MRESReturn DHookCallback_EventKilled_Pre(int client, DHookParam params)
{
	// TODO: Only do this for BLU team
	SetEntityFlags(client, GetEntityFlags(client) | FL_FAKECLIENT);
	
	return MRES_Ignored;
}

public MRESReturn DHookCallback_EventKilled_Post(int client, DHookParam params)
{
	SetEntityFlags(client, GetEntityFlags(client) & ~FL_FAKECLIENT);
	
	return MRES_Ignored;
}
