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

static int g_InternalSpawnPoint = INVALID_ENT_REFERENCE;

void DHooks_Initialize(GameData gamedata)
{
	CreateDynamicDetour(gamedata, "CPopulationManager::AllocateBots", DHookCallback_AllocateBots_Pre);
	CreateDynamicDetour(gamedata, "CTFBotSpawner::Spawn", DHookCallback_Spawn_Pre);
	CreateDynamicDetour(gamedata, "CTFGameRules::GetTeamAssignmentOverride", DHookCallback_GetTeamAssignmentOverride_Pre, DHookCallback_GetTeamAssignmentOverride_Post);
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

public MRESReturn DHookCallback_AllocateBots_Pre(int populator)
{
	// No bots in MY home!
	return MRES_Supercede;
}

public MRESReturn DHookCallback_Spawn_Pre(Address address, DHookReturn ret, DHookParam params)
{
	// The player spawning logic. This is a massive function and a lot of it assumes that the player pointer is a CTFBot.
	// Let's rewrite it all to fit our needs.
	
	int newPlayer = -1;
	
	float here[3];
	params.GetVector(1, here);
	
	if (GameRules_IsMannVsMachineMode())
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
	if (newPlayer == -1)
	{
		LogMessage("Not enough players");
	}
	else
	{
		LogMessage("Spawning player");
	}
	
	if (newPlayer != -1)
	{
		// Remove any player attributes
		SDKCall_RemovePlayerAttributes(newPlayer, false);
		
		/*
		// clear any old TeleportWhere settings 
		newBot->ClearTeleportWhere();
		*/
		
		if (g_InternalSpawnPoint == INVALID_ENT_REFERENCE)
		{
			g_InternalSpawnPoint = EntIndexToEntRef(CreateEntityByName("populator_internal_spawn_point"));
			DispatchSpawn(g_InternalSpawnPoint);
		}
		
		DispatchKeyValueVector(g_InternalSpawnPoint, "origin", here);
		g_PlayerAttributes[newPlayer].spawnPoint = g_InternalSpawnPoint;
		
		TFTeam team = TFTeam_Red;
		
		if (GameRules_IsMannVsMachineMode())
		{
			team = TFTeam_Blue;
		}
		
		// TODO: CTFBot::ChangeTeam does a little bit more...
		TF2_ChangeClientTeam(newPlayer, team);
		
		SetEntProp(newPlayer, Prop_Data, "m_bAllowInstantSpawn", true);
		TF2_SetPlayerClass(newPlayer, GetClass(address));
	}
	
	// Finally, suppress the original function
	ret.Value = false;
	return MRES_Supercede;
}

public MRESReturn DHookCallback_GetTeamAssignmentOverride_Pre(DHookReturn ret, DHookParam params)
{
	GameRules_SetProp("m_bPlayingMannVsMachine", false);
}

public MRESReturn DHookCallback_GetTeamAssignmentOverride_Post(DHookReturn ret, DHookParam params)
{
	GameRules_SetProp("m_bPlayingMannVsMachine", true);
}
