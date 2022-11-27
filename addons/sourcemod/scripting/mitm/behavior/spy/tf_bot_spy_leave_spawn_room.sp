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

methodmap CTFBotSpyLeaveSpawnRoom < NextBotAction
{
	public static void Init()
	{
		ActionFactory = new NextBotActionFactory("SpyLeaveSpawnRoom");
		ActionFactory.BeginDataMapDesc()
			.DefineIntField("m_waitTimer")
			.DefineIntField("m_attempt")
		.EndDataMapDesc();
		ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
		ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
		ActionFactory.SetCallback(NextBotActionCallbackType_OnEnd, OnEnd);
	}
	
	public CTFBotSpyLeaveSpawnRoom()
	{
		CTFBotSpyLeaveSpawnRoom action = view_as<CTFBotSpyLeaveSpawnRoom>(ActionFactory.Create());
		action.m_waitTimer = new CountdownTimer();
		return action;
	}
	
	property CountdownTimer m_waitTimer
	{
		public get()
		{
			return this.GetData("m_waitTimer");
		}
		public set(CountdownTimer waitTimer)
		{
			this.SetData("m_waitTimer", waitTimer);
		}
	}
	
	property int m_attempt
	{
		public get()
		{
			return this.GetData("m_attempt");
		}
		public set(int attempt)
		{
			this.SetData("m_attempt", attempt);
		}
	}
}

static int OnStart(CTFBotSpyLeaveSpawnRoom action, int actor, NextBotAction prevAction)
{
	// disguise as enemy team
	Player(actor).DisguiseAsMemberOfEnemyTeam();
	
	// cloak
	SDKCall_DoClassSpecialSkill(actor);
	
	// wait a few moments to guarantee a minimum time between announcing Spies and their attack
	action.m_waitTimer.Start(2.0 + GetRandomFloat(0.0, 1.0));
	
	action.m_attempt = 0;
	
	return action.Continue();
}

static int Update(CTFBotSpyLeaveSpawnRoom action, int actor, float interval)
{
	if (action.m_waitTimer.HasStarted() && action.m_waitTimer.IsElapsed())
	{
		int victim = -1;
		
		ArrayList enemyList = new ArrayList();
		CollectPlayers(enemyList, GetEnemyTeam(TF2_GetClientTeam(actor)), COLLECT_ONLY_LIVING_PLAYERS);
		
		// randomly shuffle our enemies
		enemyList.Sort(Sort_Random, Sort_Integer);
		
		for (int i = 0; i < enemyList.Length; ++i)
		{
			if (TeleportNearVictim(actor, enemyList.Get(i), action.m_attempt))
			{
				victim = enemyList.Get(i);
				break;
			}
		}
		
		// if we didn't find a victim, try again in a bit
		if (!IsValidEntity(victim))
		{
			action.m_waitTimer.Start(1.0);
			
			++action.m_attempt;
			
			delete enemyList;
			return action.Continue();
		}
		
		delete enemyList;
		return action.Done();
	}
	
	return action.Continue();
}

static void OnEnd(CTFBotSpyLeaveSpawnRoom action, int actor, NextBotAction nextAction)
{
	delete action.m_waitTimer;
}

static bool TeleportNearVictim(int actor, int victim, int attempt)
{
	if (victim == -1)
	{
		return false;
	}
	
	if (!CBaseCombatCharacter(victim).GetLastKnownArea())
	{
		return false;
	}
	
	ArrayList ambushList = new ArrayList(); // vector of hidden but near-to-victim areas
	
	const float maxSurroundTravelRange = 6000.0;
	
	float surroundTravelRange = 1500.0 + 500.0 * attempt;
	if (surroundTravelRange > maxSurroundTravelRange)
	{
		surroundTravelRange = maxSurroundTravelRange;
	}
	
	// collect walkable areas surrounding this victim
	SurroundingAreasCollector areas;
	areas = TheNavMesh.CollectSurroundingAreas(CBaseCombatCharacter(victim).GetLastKnownArea(), surroundTravelRange, sv_stepsize.FloatValue, sv_stepsize.FloatValue);
	
	// keep subset that isn't visible to the victim's team
	for (int i = 0; i < areas.Count(); i++)
	{
		CTFNavArea area = view_as<CTFNavArea>(areas.Get(i));
		
		if (!IsAreaValidForWanderingPopulation(area))
		{
			continue;
		}
		
		if (IsAreaPotentiallyVisibleToTeam(area, TF2_GetClientTeam(victim)))
		{
			continue;
		}
		
		ambushList.Push(area);
	}
	
	delete areas;
	
	if (ambushList.Length == 0)
	{
		delete ambushList;
		return false;
	}
	
	int maxTries = Min(10, ambushList.Length);
	
	for (int retry = 0; retry < maxTries; ++retry)
	{
		int which = GetRandomInt(0, ambushList.Length - 1);
		CNavArea area = ambushList.Get(which);
		float where[3];
		area.GetCenter(where);
		AddVectors(where, Vector(0.0, 0.0, sv_stepsize.FloatValue), where);
		
		if (SDKCall_IsSpaceToSpawnHere(where))
		{
			TeleportEntity(actor, where, ZERO_VECTOR, ZERO_VECTOR);
			delete ambushList;
			return true;
		}
	}
	
	delete ambushList;
	return false;
}
