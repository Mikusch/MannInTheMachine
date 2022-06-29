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

static NextBotActionFactory ActionFactory;

static int m_hintEntity[MAXPLAYERS + 1];
static bool m_bFirstTeleportSpawn[MAXPLAYERS + 1];
static CountdownTimer m_teleportDelay[MAXPLAYERS + 1];

void CTFBotMvMEngineerTeleportSpawn_Init()
{
	ActionFactory = new NextBotActionFactory("MvMEngineerTeleportSpawn");
	ActionFactory.BeginDataMapDesc()
	// TODO
	.EndDataMapDesc();
	ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, CTFBotMvMEngineerTeleportSpawn_OnStart);
	ActionFactory.SetCallback(NextBotActionCallbackType_Update, CTFBotMvMEngineerTeleportSpawn_Update);
}

NextBotAction CTFBotMvMEngineerTeleportSpawn_Create(int player, int hint, bool bFirstTeleportSpawn)
{
	m_hintEntity[player] = hint;
	m_bFirstTeleportSpawn[player] = bFirstTeleportSpawn;
	
	return ActionFactory.Create();
}

static int CTFBotMvMEngineerTeleportSpawn_OnStart(NextBotAction action, int actor, NextBotAction priorAction)
{
	if (!Player(actor).HasAttribute(TELEPORT_TO_HINT))
	{
		return action.Done("Cannot teleport to hint with out Attributes TeleportToHint");
	}
	
	return action.Continue();
}

static int CTFBotMvMEngineerTeleportSpawn_Update(NextBotAction action, int actor, float interval)
{
	if (!m_teleportDelay[actor].HasStarted())
	{
		float origin[3];
		GetEntPropVector(m_hintEntity[actor], Prop_Data, "m_vecAbsOrigin", origin);
		
		m_teleportDelay[actor].Start(0.1);
		if (m_hintEntity[actor] != -1)
			SDKCall_PushAllPlayersAway(origin, 400.0, 500.0, TFTeam_Defenders);
	}
	else if (m_teleportDelay[actor].IsElapsed())
	{
		if (m_hintEntity[actor] == -1)
			return action.Done("Cannot teleport to hint as m_hintEntity is NULL");
		
		// teleport the engineer to the sentry spawn point
		float angles[3], origin[3];
		GetEntPropVector(m_hintEntity[actor], Prop_Data, "m_angAbsRotation", angles);
		GetEntPropVector(m_hintEntity[actor], Prop_Data, "m_vecAbsOrigin", origin);
		origin[2] += 10.0; // move up off the around a little bit to prevent the engineer from getting stuck in the ground
		
		TeleportEntity(actor, origin, angles);
		
		TE_TFParticleEffect("teleported_blue", origin);
		TE_TFParticleEffect("player_sparkles_blue", origin);
		
		if (m_bFirstTeleportSpawn[actor])
		{
			// notify players that engineer's teleported into the map
			TE_TFParticleEffect("teleported_mvm_bot", origin);
			EmitGameSoundToAll("Engineer.MVM_BattleCry07", actor);
			EmitGameSoundToAll("MVM.Robot_Engineer_Spawn", m_hintEntity[actor]);
			
			if (GetPopulationManager())
			{
				CWave pWave = GetPopulationManager().GetCurrentWave();
				if (pWave)
				{
					if (pWave.m_nNumEngineersTeleportSpawned == 0)
					{
						TFGameRules_BroadcastSound(255, "Announcer.MVM_First_Engineer_Teleport_Spawned");
					}
					else
					{
						TFGameRules_BroadcastSound(255, "Announcer.MVM_Another_Engineer_Teleport_Spawned");
					}
					
					pWave.m_nNumEngineersTeleportSpawned++;
				}
			}
		}
		
		return action.Done("Teleported");
	}
	
	return action.Continue();
}
