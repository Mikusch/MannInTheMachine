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

static int m_sentryHint[MAXPLAYERS + 1];
static int m_teleporterHint[MAXPLAYERS + 1];
static int m_nestHint[MAXPLAYERS + 1];
static int m_nTeleportedCount[MAXPLAYERS + 1];
static bool m_bTeleportedToHint[MAXPLAYERS + 1];
static bool m_bTriedToDetonateStaleNest[MAXPLAYERS + 1];
static CountdownTimer m_findHintTimer[MAXPLAYERS + 1];
static CountdownTimer m_reevaluateNestTimer[MAXPLAYERS + 1];

void CTFBotMvMEngineerIdle_Init()
{
	ActionFactory = new NextBotActionFactory("MvMEngineerIdle");
	ActionFactory.BeginDataMapDesc()
	// TODO
	.EndDataMapDesc();
	ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, CTFBotMvMEngineerIdle_OnStart);
	ActionFactory.SetCallback(NextBotActionCallbackType_Update, CTFBotMvMEngineerIdle_Update);
}

NextBotAction CTFBotMvMEngineerIdle_Create()
{
	return ActionFactory.Create();
}

static int CTFBotMvMEngineerIdle_OnStart(NextBotAction action, int actor, NextBotAction priorAction)
{
	m_sentryHint[actor] = -1;
	m_teleporterHint[actor] = -1;
	m_nestHint[actor] = -1;
	m_nTeleportedCount[actor] = 0;
	m_bTeleportedToHint[actor] = false;
	m_bTriedToDetonateStaleNest[actor] = false;
	
	return action.Continue();
}

static int CTFBotMvMEngineerIdle_Update(NextBotAction action, int actor, float interval)
{
	if (!IsPlayerAlive(actor))
	{
		// don't do anything when I'm dead
		return action.Done();
	}
	
	if (m_sentryHint[actor] == -1 || ShouldAdvanceNestSpot(actor))
	{
		if (m_findHintTimer[actor].HasStarted() && !m_findHintTimer[actor].IsElapsed())
		{
			// too soon
			return action.Continue();
		}
		
		m_findHintTimer[actor].Start(GetRandomFloat(1.0, 2.0));
		
		// figure out where to teleport into the map
		bool bShouldTeleportToHint = Player(actor).HasAttribute(TELEPORT_TO_HINT);
		bool bShouldCheckForBlockingObject = !m_bTeleportedToHint[actor] && bShouldTeleportToHint;
		int newNest = -1;
		if (!SDKCall_FindHint(bShouldCheckForBlockingObject, !bShouldTeleportToHint, newNest))
		{
			// try again next time
			return action.Continue();
		}
		
		// unown the old nest
		if (m_nestHint[actor] != -1)
		{
			SetEntityOwner(m_nestHint[actor], -1);
		}
		
		m_nestHint[actor] = newNest;
		SetEntityOwner(m_nestHint[actor], actor);
		m_sentryHint[actor] = SDKCall_GetSentryHint(m_nestHint[actor]);
		TakeOverStaleNest(m_sentryHint[actor], actor);
		
		if (Player(actor).m_teleportWhereName.Length > 0)
		{
			m_teleporterHint[actor] = SDKCall_GetTeleporterHint(m_nestHint[actor]);
			TakeOverStaleNest(m_teleporterHint[actor], actor);
		}
		
		if (!m_bTeleportedToHint[actor] && Player(actor).HasAttribute(TELEPORT_TO_HINT))
		{
			m_nTeleportedCount[actor]++;
			bool bFirstTeleportSpawn = m_nTeleportedCount[actor] == 1;
			m_bTeleportedToHint[actor] = true;
			
			return action.SuspendFor(CTFBotMvMEngineerTeleportSpawn_Create(m_nestHint[actor], bFirstTeleportSpawn), "In spawn area - teleport to the teleporter hint");
		}
		
		int mySentry = -1;
		if (m_sentryHint[actor] != -1)
		{
			int owner = GetEntPropEnt(m_sentryHint[actor], Prop_Send, "m_hOwnerEntity");
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
					AcceptEntityInput(mySentry, "SetBuilder", actor);
				}
				else
				{
					return action.Continue();
				}
			}
		}
	}
	
	TryToDetonateStaleNest(actor);
	
	return action.Continue();
}

static void TakeOverStaleNest(int hint, int actor)
{
	if (hint != -1 && CBaseTFBotHintEntity(hint).OwnerObjectHasNoOwner())
	{
		int obj = GetEntPropEnt(hint, Prop_Send, "m_hOwnerEntity");
		SetEntityOwner(obj, actor);
		AcceptEntityInput(obj, "SetBuilder", actor);
	}
}

static bool ShouldAdvanceNestSpot(int actor)
{
	if (m_nestHint[actor] == -1)
	{
		return false;
	}
	
	if (!m_reevaluateNestTimer[actor].HasStarted())
	{
		m_reevaluateNestTimer[actor].Start(5.0);
		return false;
	}
	
	for (int i = 0; i < TF2Util_GetPlayerObjectCount(actor); ++i)
	{
		int obj = TF2Util_GetPlayerObject(actor, i);
		if (obj != -1 && GetEntProp(obj, Prop_Data, "m_iHealth") < GetEntProp(obj, Prop_Data, "m_iMaxHealth"))
		{
			// if the nest is under attack, don't advance the nest
			m_reevaluateNestTimer[actor].Start(5.0);
			return false;
		}
	}
	
	if (m_reevaluateNestTimer[actor].IsElapsed())
	{
		m_reevaluateNestTimer[actor].Invalidate();
	}
	
	BombInfo_t bombInfo = malloc(20); // sizeof(BombInfo_t)
	if (SDKCall_GetBombInfo(bombInfo))
	{
		if (m_nestHint[actor] != -1)
		{
			float origin[3];
			GetEntPropVector(m_nestHint[actor], Prop_Data, "m_vecAbsOrigin", origin);
			
			CNavArea hintArea = TheNavMesh.GetNearestNavArea(origin, false, 1000.0);
			if (hintArea)
			{
				float hintDistanceToTarget = Deref(hintArea + GetOffset("CTFNavArea::m_distanceToBombTarget"));
				
				bool bShouldAdvance = (hintDistanceToTarget > bombInfo.m_flMaxBattleFront);
				
				return bShouldAdvance;
			}
		}
	}
	free(bombInfo);
	
	return false;
}

static void TryToDetonateStaleNest(int actor)
{
	if (m_bTriedToDetonateStaleNest[actor])
		return;
	
	// wait until the engy finish building his nest
	if ((m_sentryHint[actor] != -1 && !CBaseTFBotHintEntity(m_sentryHint[actor]).OwnerObjectFinishBuilding()) || 
		(m_teleporterHint[actor] != -1 && !CBaseTFBotHintEntity(m_teleporterHint[actor]).OwnerObjectFinishBuilding()))
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
	
	m_bTriedToDetonateStaleNest[actor] = true;
	
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
