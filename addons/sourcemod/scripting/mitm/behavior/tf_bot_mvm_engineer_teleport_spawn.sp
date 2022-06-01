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

// public
bool m_bIsTeleportingIn[MAXPLAYERS + 1];

static int m_hintEntity[MAXPLAYERS + 1];
static bool m_bFirstTeleportSpawn[MAXPLAYERS + 1];
static CountdownTimer m_teleportDelay[MAXPLAYERS + 1];

void CTFBotMvMEngineerTeleportSpawn_Create(int player, int hint, bool bFirstTeleportSpawn)
{
	m_hintEntity[player] = hint;
	m_bFirstTeleportSpawn[player] = bFirstTeleportSpawn;
	
	if (CTFBotMvMEngineerTeleportSpawn_OnStart(player))
	{
		m_bIsTeleportingIn[player] = true;
	}
}

bool CTFBotMvMEngineerTeleportSpawn_OnStart(int me)
{
	if (!Player(me).HasAttribute(TELEPORT_TO_HINT))
	{
		// Cannot teleport to hint with out Attributes TeleportToHint
		return false;
	}
	
	return true;
}

bool CTFBotMvMEngineerTeleportSpawn_Update(int me)
{
	if (!m_teleportDelay[me].HasStarted())
	{
		m_teleportDelay[me].Start(0.1);
		if (m_hintEntity[me] != -1)
		{
			float origin[3];
			GetEntPropVector(m_hintEntity[me], Prop_Data, "m_vecAbsOrigin", origin);
			
			SDKCall_PushAllPlayersAway(origin, 400.0, 500.0, TFTeam_Defenders);
		}
	}
	else if (m_teleportDelay[me].IsElapsed())
	{
		if (m_hintEntity[me] == -1)
			return false;
		
		// teleport the engineer to the sentry spawn point
		float angles[3], origin[3];
		GetEntPropVector(m_hintEntity[me], Prop_Data, "m_angAbsRotation", angles);
		GetEntPropVector(m_hintEntity[me], Prop_Data, "m_vecAbsOrigin", origin);
		origin[2] += 10.0; // move up off the around a little bit to prevent the engineer from getting stuck in the ground
		
		TeleportEntity(me, origin, angles);
		
		TE_TFParticleEffect("teleported_blue", origin);
		TE_TFParticleEffect("player_sparkles_blue", origin);
		
		if (m_bFirstTeleportSpawn[me])
		{
			// notify players that engineer's teleported into the map
			TE_TFParticleEffect("teleported_mvm_bot", origin);
			EmitGameSoundToAll("Engineer.MVM_BattleCry07", me);
			EmitGameSoundToAll("MVM.Robot_Engineer_Spawn", m_hintEntity[me]);
			
			if (GetPopulator())
			{
				CWave pWave = CWave(SDKCall_GetCurrentWave(GetPopulator()));
				if (pWave)
				{
					if (pWave.m_nNumEngineersTeleportSpawned == 0)
					{
						EmitGameSoundToAll("Announcer.MVM_First_Engineer_Teleport_Spawned");
					}
					else
					{
						EmitGameSoundToAll("Announcer.MVM_Another_Engineer_Teleport_Spawned");
					}
					
					pWave.m_nNumEngineersTeleportSpawned++;
				}
			}
		}
		
		return false;
	}
	
	return true;
}
