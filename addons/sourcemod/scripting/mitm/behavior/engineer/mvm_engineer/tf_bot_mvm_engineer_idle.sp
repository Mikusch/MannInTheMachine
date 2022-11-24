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

methodmap CTFBotMvMEngineerIdle < NextBotAction
{
	public static void Init()
	{
		ActionFactory = new NextBotActionFactory("MvMEngineerIdle");
		ActionFactory.BeginDataMapDesc()
			.DefineIntField("m_findHintTimer")
			.DefineIntField("m_reevaluateNestTimer")
			.DefineEntityField("m_sentryHint")
			.DefineEntityField("m_teleporterHint")
			.DefineEntityField("m_nestHint")
			.DefineIntField("m_nTeleportedCount")
			.DefineBoolField("m_bTeleportedToHint")
			.DefineBoolField("m_bTriedToDetonateStaleNest")
		.EndDataMapDesc();
		ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
		ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
		ActionFactory.SetCallback(NextBotActionCallbackType_OnEnd, OnEnd);
	}
	
	public CTFBotMvMEngineerIdle()
	{
		CTFBotMvMEngineerIdle action = view_as<CTFBotMvMEngineerIdle>(ActionFactory.Create());
		action.m_findHintTimer = new CountdownTimer();
		action.m_reevaluateNestTimer = new CountdownTimer();
		return action;
	}
	
	property CountdownTimer m_findHintTimer
	{
		public get()
		{
			return this.GetData("m_findHintTimer");
		}
		public set(CountdownTimer findHintTimer)
		{
			this.SetData("m_findHintTimer", findHintTimer);
		}
	}
	
	property CountdownTimer m_reevaluateNestTimer
	{
		public get()
		{
			return this.GetData("m_reevaluateNestTimer");
		}
		public set(CountdownTimer reevaluateNestTimer)
		{
			this.SetData("m_reevaluateNestTimer", reevaluateNestTimer);
		}
	}
	
	property int m_sentryHint
	{
		public get()
		{
			return this.GetDataEnt("m_sentryHint");
		}
		public set(int sentryHint)
		{
			this.SetDataEnt("m_sentryHint", sentryHint);
		}
	}
	
	property int m_teleporterHint
	{
		public get()
		{
			return this.GetDataEnt("m_teleporterHint");
		}
		public set(int teleporterHint)
		{
			this.SetDataEnt("m_teleporterHint", teleporterHint);
		}
	}
	
	property int m_nestHint
	{
		public get()
		{
			return this.GetDataEnt("m_nestHint");
		}
		public set(int nestHint)
		{
			this.SetDataEnt("m_nestHint", nestHint);
		}
	}
	
	property int m_nTeleportedCount
	{
		public get()
		{
			return this.GetData("m_nTeleportedCount");
		}
		public set(int nTeleportedCount)
		{
			this.SetData("m_nTeleportedCount", nTeleportedCount);
		}
	}
	
	property bool m_bTeleportedToHint
	{
		public get()
		{
			return this.GetData("m_bTeleportedToHint");
		}
		public set(bool bTeleportedToHint)
		{
			this.SetData("m_bTeleportedToHint", bTeleportedToHint);
		}
	}
	
	property bool m_bTriedToDetonateStaleNest
	{
		public get()
		{
			return this.GetData("m_bTriedToDetonateStaleNest");
		}
		public set(bool bTriedToDetonateStaleNest)
		{
			this.SetData("m_bTriedToDetonateStaleNest", bTriedToDetonateStaleNest);
		}
	}
}

static int OnStart(CTFBotMvMEngineerIdle action, int actor, NextBotAction priorAction)
{
	action.m_sentryHint = -1;
	action.m_teleporterHint = -1;
	action.m_nestHint = -1;
	action.m_nTeleportedCount = 0;
	action.m_bTeleportedToHint = false;
	action.m_bTriedToDetonateStaleNest = false;
	
	return action.Continue();
}

static int Update(CTFBotMvMEngineerIdle action, int actor, float interval)
{
	if (!IsPlayerAlive(actor))
	{
		// don't do anything when I'm dead
		return action.Done();
	}
	
	if (!IsValidEntity(action.m_sentryHint) || ShouldAdvanceNestSpot(action, actor))
	{
		if (action.m_findHintTimer.HasStarted() && !action.m_findHintTimer.IsElapsed())
		{
			// too soon
			return action.Continue();
		}
		
		action.m_findHintTimer.Start(GetRandomFloat(1.0, 2.0));
		
		// figure out where to teleport into the map
		bool bShouldTeleportToHint = Player(actor).HasAttribute(TELEPORT_TO_HINT);
		bool bShouldCheckForBlockingObject = !action.m_bTeleportedToHint && bShouldTeleportToHint;
		int newNest = -1;
		if (!SDKCall_FindHint(bShouldCheckForBlockingObject, !bShouldTeleportToHint, newNest))
		{
			// try again next time
			return action.Continue();
		}
		
		// unown the old nest
		if (IsValidEntity(action.m_nestHint))
		{
			SetEntityOwner(action.m_nestHint, -1);
		}
		
		action.m_nestHint = newNest;
		SetEntityOwner(action.m_nestHint, actor);
		action.m_sentryHint = SDKCall_GetSentryHint(action.m_nestHint);
		TakeOverStaleNest(action.m_sentryHint, actor);
		
		if (Player(actor).m_teleportWhereName.Length > 0)
		{
			action.m_teleporterHint = SDKCall_GetTeleporterHint(action.m_nestHint);
			TakeOverStaleNest(action.m_teleporterHint, actor);
		}
	}
	
	if (!action.m_bTeleportedToHint && Player(actor).HasAttribute(TELEPORT_TO_HINT))
	{
		action.m_nTeleportedCount++;
		bool bFirstTeleportSpawn = action.m_nTeleportedCount == 1;
		action.m_bTeleportedToHint = true;
		
		return action.SuspendFor(CTFBotMvMEngineerTeleportSpawn(action.m_nestHint, bFirstTeleportSpawn), "In spawn area - teleport to the teleporter hint");
	}
	
	int mySentry = -1;
	if (IsValidEntity(action.m_sentryHint))
	{
		int owner = GetEntPropEnt(action.m_sentryHint, Prop_Send, "m_hOwnerEntity");
		if (owner != -1 && IsBaseObject(owner))
		{
			mySentry = owner;
		}
		
		if (mySentry == -1)
		{
			// check if there's a stale object on the hint
			if (owner != -1 && IsBaseObject(owner))
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

static void OnEnd(CTFBotMvMEngineerIdle action, int actor, NextBotAction nextAction)
{
	delete action.m_findHintTimer;
	delete action.m_reevaluateNestTimer;
}

static void TakeOverStaleNest(int hint, int actor)
{
	if (IsValidEntity(hint) && CBaseTFBotHintEntity(hint).OwnerObjectHasNoOwner())
	{
		int obj = GetEntPropEnt(hint, Prop_Send, "m_hOwnerEntity");
		SetEntityOwner(obj, actor);
		AcceptEntityInput(obj, "SetBuilder", actor);
	}
}

static bool ShouldAdvanceNestSpot(CTFBotMvMEngineerIdle action, int actor)
{
	if (!IsValidEntity(action.m_nestHint))
	{
		return false;
	}
	
	if (!action.m_reevaluateNestTimer.HasStarted())
	{
		action.m_reevaluateNestTimer.Start(5.0);
		return false;
	}
	
	for (int i = 0; i < TF2Util_GetPlayerObjectCount(actor); ++i)
	{
		int obj = TF2Util_GetPlayerObject(actor, i);
		if (obj != -1 && GetEntProp(obj, Prop_Data, "m_iHealth") < GetEntProp(obj, Prop_Data, "m_iMaxHealth"))
		{
			// if the nest is under attack, don't advance the nest
			action.m_reevaluateNestTimer.Start(5.0);
			return false;
		}
	}
	
	if (action.m_reevaluateNestTimer.IsElapsed())
	{
		action.m_reevaluateNestTimer.Invalidate();
	}
	
	BombInfo_t bombInfo = malloc(GetOffset(NULL_STRING, "sizeof(BombInfo_t)"));
	if (SDKCall_GetBombInfo(bombInfo))
	{
		if (IsValidEntity(action.m_nestHint))
		{
			float origin[3];
			GetEntPropVector(action.m_nestHint, Prop_Data, "m_vecAbsOrigin", origin);
			
			CNavArea hintArea = TheNavMesh.GetNearestNavArea(origin, false, 1000.0);
			if (hintArea)
			{
				float hintDistanceToTarget = Deref(hintArea + GetOffset("CTFNavArea", "m_distanceToBombTarget"));
				
				bool bShouldAdvance = (hintDistanceToTarget > bombInfo.m_flMaxBattleFront);
				
				return bShouldAdvance;
			}
		}
	}
	free(bombInfo);
	
	return false;
}

static void TryToDetonateStaleNest(CTFBotMvMEngineerIdle action)
{
	if (action.m_bTriedToDetonateStaleNest)
		return;
	
	// wait until the engy finish building his nest
	if ((IsValidEntity(action.m_sentryHint) && !CBaseTFBotHintEntity(action.m_sentryHint).OwnerObjectFinishBuilding()) || 
		(IsValidEntity(action.m_teleporterHint) && !CBaseTFBotHintEntity(action.m_teleporterHint).OwnerObjectFinishBuilding()))
		return;
	
	ArrayList activeEngineerNest = new ArrayList();
	
	// collect all existing and active teleporter hints
	int hint = -1;
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
	
	action.m_bTriedToDetonateStaleNest = true;
	
	delete activeEngineerNest;
}
