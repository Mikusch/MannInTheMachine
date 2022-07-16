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

static CountdownTimer m_findHintTimer[MAXPLAYERS + 1];
static CountdownTimer m_reevaluateNestTimer[MAXPLAYERS + 1];

void CTFBotMvMEngineerIdle_Init()
{
	ActionFactory = new NextBotActionFactory("MvMEngineerIdle");
	ActionFactory.BeginDataMapDesc()
		.DefineEntityField("m_sentryHint")
		.DefineEntityField("m_teleporterHint")
		.DefineEntityField("m_nestHint")
		.DefineIntField("m_nTeleportedCount")
		.DefineBoolField("m_bTeleportedToHint")
		.DefineBoolField("m_bTriedToDetonateStaleNest")
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
	action.SetDataEnt("m_sentryHint", -1);
	action.SetDataEnt("m_teleporterHint", -1);
	action.SetDataEnt("m_nestHint", -1);
	action.SetData("m_nTeleportedCount", 0);
	action.SetData("m_bTeleportedToHint", false);
	action.SetData("m_bTriedToDetonateStaleNest", false);
	
	return action.Continue();
}

static int CTFBotMvMEngineerIdle_Update(NextBotAction action, int actor, float interval)
{
	if (!IsPlayerAlive(actor))
	{
		// don't do anything when I'm dead
		return action.Done();
	}
	
	if (action.GetDataEnt("m_sentryHint") == -1 || ShouldAdvanceNestSpot(action, actor))
	{
		if (m_findHintTimer[actor].HasStarted() && !m_findHintTimer[actor].IsElapsed())
		{
			// too soon
			return action.Continue();
		}
		
		m_findHintTimer[actor].Start(GetRandomFloat(1.0, 2.0));
		
		// figure out where to teleport into the map
		bool bShouldTeleportToHint = Player(actor).HasAttribute(TELEPORT_TO_HINT);
		bool bShouldCheckForBlockingObject = !action.GetData("m_bTeleportedToHint") && bShouldTeleportToHint;
		int newNest = -1;
		if (!SDKCall_FindHint(bShouldCheckForBlockingObject, !bShouldTeleportToHint, newNest))
		{
			// try again next time
			return action.Continue();
		}
		
		// unown the old nest
		if (action.GetDataEnt("m_nestHint") != -1)
		{
			SetEntityOwner(action.GetDataEnt("m_nestHint"), -1);
		}
		
		action.SetDataEnt("m_nestHint", newNest);
		SetEntityOwner(action.GetDataEnt("m_nestHint"), actor);
		action.SetDataEnt("m_sentryHint", SDKCall_GetSentryHint(action.GetDataEnt("m_nestHint")));
		TakeOverStaleNest(action.GetDataEnt("m_sentryHint"), actor);
		
		if (Player(actor).m_teleportWhereName.Length > 0)
		{
			action.SetDataEnt("m_teleporterHint", SDKCall_GetTeleporterHint(action.GetDataEnt("m_nestHint")));
			TakeOverStaleNest(action.GetDataEnt("m_teleporterHint"), actor);
		}
	}
	
	if (!action.GetData("m_bTeleportedToHint") && Player(actor).HasAttribute(TELEPORT_TO_HINT))
	{
		action.SetData("m_nTeleportedCount", action.GetData("m_nTeleportedCount") + 1);
		bool bFirstTeleportSpawn = action.GetData("m_nTeleportedCount") == 1;
		action.SetData("m_bTeleportedToHint", true);
		
		return action.SuspendFor(CTFBotMvMEngineerTeleportSpawn_Create(action.GetDataEnt("m_nestHint"), bFirstTeleportSpawn), "In spawn area - teleport to the teleporter hint");
	}
	
	int mySentry = -1;
	if (action.GetDataEnt("m_sentryHint") != -1)
	{
		int owner = GetEntPropEnt(action.GetDataEnt("m_sentryHint"), Prop_Send, "m_hOwnerEntity");
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
	
	TryToDetonateStaleNest(action);
	
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

static bool ShouldAdvanceNestSpot(NextBotAction action, int actor)
{
	if (action.GetDataEnt("m_nestHint") == -1)
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
		if (action.GetDataEnt("m_nestHint") != -1)
		{
			float origin[3];
			GetEntPropVector(action.GetDataEnt("m_nestHint"), Prop_Data, "m_vecAbsOrigin", origin);
			
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

static void TryToDetonateStaleNest(NextBotAction action)
{
	if (action.GetData("m_bTriedToDetonateStaleNest"))
		return;
	
	// wait until the engy finish building his nest
	if ((action.GetDataEnt("m_sentryHint") != -1 && !CBaseTFBotHintEntity(action.GetDataEnt("m_sentryHint")).OwnerObjectFinishBuilding()) || 
		(action.GetDataEnt("m_teleporterHint") != -1 && !CBaseTFBotHintEntity(action.GetDataEnt("m_teleporterHint")).OwnerObjectFinishBuilding()))
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
	
	action.SetData("m_bTriedToDetonateStaleNest", true);
	
	delete activeEngineerNest;
}
