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
static CountdownTimer m_reevaluateNestTimer[MAXPLAYERS + 1];

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
	
	if (m_sentryHint[me] == -1 || ShouldAdvanceNestSpot(me))
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
		
		int mySentry = -1;
		if (m_sentryHint[me] != -1)
		{
			int owner = GetEntPropEnt(m_sentryHint[me], Prop_Send, "m_hOwnerEntity");
			if (owner != -1 && HasEntProp(owner, Prop_Send, "m_hBuilder"))
			{
				mySentry = owner;
			}
			
			if (mySentry == -1)
			{
				// check if there's a stale object on the hint
				if (owner != -1 && HasEntProp(owner, Prop_Send, "m_hBuilder"))
				{
					mySentry = owner;
					AcceptEntityInput(mySentry, "SetBuilder", me);
				}
				else
				{
					return true;
				}
			}
		}
	}
	
	TryToDetonateStaleNest(me);
	
	return true;
}

static void TakeOverStaleNest(int hint, int me)
{
	if (hint != -1 && CBaseTFBotHintEntity(hint).OwnerObjectHasNoOwner())
	{
		int obj = GetEntPropEnt(hint, Prop_Send, "m_hOwnerEntity");
		SetEntityOwner(obj, me);
		AcceptEntityInput(obj, "SetBuilder", me);
	}
}

static bool ShouldAdvanceNestSpot(int me)
{
	if (m_nestHint[me] == -1)
	{
		return false;
	}
	
	if (!m_reevaluateNestTimer[me].HasStarted())
	{
		m_reevaluateNestTimer[me].Start(5.0);
		return false;
	}
	
	for (int i = 0; i < TF2Util_GetPlayerObjectCount(me); ++i)
	{
		int obj = TF2Util_GetPlayerObject(me, i);
		if (obj != -1 && GetEntProp(obj, Prop_Data, "m_iHealth") < GetEntProp(obj, Prop_Data, "m_iMaxHealth"))
		{
			// if the nest is under attack, don't advance the nest
			m_reevaluateNestTimer[me].Start(5.0);
			return false;
		}
	}
	
	if (m_reevaluateNestTimer[me].IsElapsed())
	{
		m_reevaluateNestTimer[me].Invalidate();
	}
	
	BombInfo_t bombInfo = view_as<BombInfo_t>(Malloc(20)); // sizeof(BombInfo_t)
	if (SDKCall_GetBombInfo(bombInfo))
	{
		if (m_nestHint[me] != -1)
		{
			float origin[3];
			GetEntPropVector(m_nestHint[me], Prop_Data, "m_vecAbsOrigin", origin);
			
			CNavArea hintArea = TheNavMesh.GetNearestNavArea(origin, false, 1000.0);
			if (hintArea)
			{
				float hintDistanceToTarget = Deref(hintArea + GetOffset("CTFNavArea::m_distanceToBombTarget"));
				
				bool bShouldAdvance = (hintDistanceToTarget > bombInfo.m_flMaxBattleFront);
				
				return bShouldAdvance;
			}
		}
	}
	
	return false;
}

static void TryToDetonateStaleNest(int me)
{
	if (m_bTriedToDetonateStaleNest[me])
		return;
	
	// wait until the engy finish building his nest
	if ((m_sentryHint[me] != -1 && !CBaseTFBotHintEntity(m_sentryHint[me]).OwnerObjectFinishBuilding()) ||
		(m_teleporterHint[me] != -1 && !CBaseTFBotHintEntity(m_teleporterHint[me]).OwnerObjectFinishBuilding()))
		return;
	
	ArrayList activeEngineerNest = new ArrayList();
	
	// collect all existing and active teleporter hints
	int hint = MaxClients + 1;
	while ((hint = FindEntityByClassname(hint, "bot_hint_engineer_nest*")) != -1)
	{
		if (CBaseTFBotHintEntity(hint).IsEnabled() && GetEntPropEnt(hint, Prop_Send, "m_hOwnerEntity") == -1)
		{
			activeEngineerNest.Push(hint);
		}
	}
	
	// try to detonate stale nest that's out of range, when engineer finished building his nest
	for (int i = 0; i < activeEngineerNest.Length; ++i)
	{
		int nest = activeEngineerNest.Get(i);
		if (SDKCall_IsStaleNest(nest))
		{
			SDKCall_DetonateStaleNest(nest);
		}
	}
	
	m_bTriedToDetonateStaleNest[me] = true;
	
	delete activeEngineerNest;
}

int GetNestSentryHint(int player)
{
	return m_sentryHint[player];
}

int GetNestTeleporterHint(int player)
{
	return m_teleporterHint[player];
}
