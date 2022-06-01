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

static int m_sentryHint[MAXPLAYERS + 1];
static int m_teleporterHint[MAXPLAYERS + 1];
static int m_nestHint[MAXPLAYERS + 1];
static int m_nTeleportedCount[MAXPLAYERS + 1];
static bool m_bTeleportedToHint[MAXPLAYERS + 1];
static bool m_bTriedToDetonateStaleNest[MAXPLAYERS + 1];
static CountdownTimer m_findHintTimer[MAXPLAYERS + 1];

void CTFBotMvMEngineerIdle_OnStart(int me)
{
	m_sentryHint[me] = -1;
	m_teleporterHint[me] = -1;
	m_nestHint[me] = -1;
	m_nTeleportedCount[me] = 0;
	m_bTeleportedToHint[me] = false;
	m_bTriedToDetonateStaleNest[me] = false;
}

bool CTFBotMvMEngineerIdle_Update(int me)
{
	if (!IsPlayerAlive(me))
	{
		// don't do anything when I'm dead
		return false;
	}
	
	if (m_sentryHint[me] == -1)
	{
		if (m_findHintTimer[me].HasStarted() && !m_findHintTimer[me].IsElapsed())
		{
			// too soon
			return true;
		}
		
		m_findHintTimer[me].Start(GetRandomFloat(1.0, 2.0));
		
		// figure out where to teleport into the map
		bool bShouldTeleportToHint = Player(me).HasAttribute(TELEPORT_TO_HINT);
		bool bShouldCheckForBlockingObject = !m_bTeleportedToHint[me] && bShouldTeleportToHint;
		int newNest = -1;
		if (!SDKCall_FindHint(bShouldCheckForBlockingObject, !bShouldTeleportToHint, newNest))
		{
			// try again next time
			return true;
		}
		
		// unown the old nest
		if (m_nestHint[me] != -1)
		{
			SetEntityOwner(m_nestHint[me], -1);
		}
		
		m_nestHint[me] = newNest;
		SetEntityOwner(m_nestHint[me], me);
		m_sentryHint[me] = SDKCall_GetSentryHint(m_nestHint[me]);
		TakeOverStaleNest(m_sentryHint[me], me);
		
		if (Player(me).m_teleportWhereName.Length > 0)
		{
			m_teleporterHint[me] = SDKCall_GetTeleporterHint(m_nestHint[me]);
			TakeOverStaleNest(m_teleporterHint[me], me);
		}
		
		if (!m_bTeleportedToHint[me] && Player(me).HasAttribute(TELEPORT_TO_HINT))
		{
			m_nTeleportedCount[me]++;
			bool bFirstTeleportSpawn = m_nTeleportedCount[me] == 1;
			m_bTeleportedToHint[me] = true;
			
			CTFBotMvMEngineerTeleportSpawn_Create(me, m_nestHint[me], bFirstTeleportSpawn);
			return true;
		}
	}
	
	return true;
}

static void TakeOverStaleNest(int hint, int me)
{
	if (hint != -1 && OwnerObjectHasNoOwner(hint))
	{
		int obj = GetEntPropEnt(hint, Prop_Send, "m_hOwnerEntity");
		SetEntityOwner(obj, me);
		AcceptEntityInput(obj, "SetBuilder", me);
	}
}

static bool OwnerObjectHasNoOwner(int hint)
{
	int owner = GetEntPropEnt(hint, Prop_Send, "m_hOwnerEntity");
	if (owner != -1 && HasEntProp(owner, Prop_Send, "m_hBuilder"))
	{
		if (GetEntPropEnt(owner, Prop_Send, "m_hBuilder") == -1)
		{
			return true;
		}
		else
		{
			if (TF2_GetPlayerClass(GetEntPropEnt(owner, Prop_Send, "m_hBuilder")) != TFClass_Engineer)
			{
				LogError("Object has an owner that's not engineer.");
			}
		}
	}
	return false;
}

int GetNestSentryHint(int player)
{
	return m_sentryHint[player];
}

int GetNestTeleporterHint(int player)
{
	return m_teleporterHint[player];
}
