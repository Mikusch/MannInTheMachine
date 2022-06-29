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

static CountdownTimer m_waitTimer[MAXPLAYERS + 1];

void CTFBotSpyLeaveSpawnRoom_Init()
{
	ActionFactory = new NextBotActionFactory("SpyLeaveSpawnRoom");
	ActionFactory.BeginDataMapDesc()
		.DefineIntField("m_attempt")
	.EndDataMapDesc();
	ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, CTFBotSpyLeaveSpawnRoom_OnStart);
	ActionFactory.SetCallback(NextBotActionCallbackType_Update, CTFBotSpyLeaveSpawnRoom_Update);
}

NextBotAction CTFBotSpyLeaveSpawnRoom_Create()
{
	return ActionFactory.Create();
}

static int CTFBotSpyLeaveSpawnRoom_OnStart(NextBotAction action, int actor, NextBotAction prevAction)
{
	// disguise as enemy team
	Player(actor).DisguiseAsMemberOfEnemyTeam();
	
	// cloak
	SDKCall_DoClassSpecialSkill(actor);
	
	// wait a few moments to guarantee a minimum time between announcing Spies and their attack
	m_waitTimer[actor].Start(2.0 + GetRandomFloat(0.0, 1.0));
	
	action.SetData("m_attempt", 0);
	
	return action.Continue();
}

static int CTFBotSpyLeaveSpawnRoom_Update(NextBotAction action, int actor, float interval)
{
	if (m_waitTimer[actor].HasStarted() && m_waitTimer[actor].IsElapsed())
	{
		int victim = -1;
		
		ArrayList enemyVector = new ArrayList(MaxClients);
		
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client))
				continue;
			
			if (TF2_GetClientTeam(client) == TF2_GetClientTeam(actor))
				continue;
			
			if (!IsPlayerAlive(client))
				continue;
			
			enemyVector.Push(client);
		}
		
		// randomly shuffle our enemies
		enemyVector.Sort(Sort_Random, Sort_Integer);
		
		int n = enemyVector.Length;
		while (n > 1)
		{
			int k = GetRandomInt(0, n - 1);
			n--;
			
			int tmp = enemyVector.Get(n);
			enemyVector.Set(n, enemyVector.Get(k));
			enemyVector.Set(k, tmp);
		}
		
		for (int i = 0; i < enemyVector.Length; ++i)
		{
			if (TeleportNearVictim(actor, enemyVector.Get(i), action.GetData("m_attempt")))
			{
				victim = enemyVector.Get(i);
				break;
			}
		}
		
		// if we didn't find a victim, try again in a bit
		if (victim == -1)
		{
			m_waitTimer[actor].Start(1.0);
			
			action.SetData("m_attempt", action.GetData("m_attempt") + 1);
			
			delete enemyVector;
			return action.Continue();
		}
		
		delete enemyVector;
		return action.Done();
	}
	
	return action.Continue();
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
	
	ArrayList ambushVector = new ArrayList(); // vector of hidden but near-to-victim areas
	
	const float maxSurroundTravelRange = 6000.0;
	
	float surroundTravelRange = 1500.0 + 500.0 * attempt;
	if (surroundTravelRange > maxSurroundTravelRange)
	{
		surroundTravelRange = maxSurroundTravelRange;
	}
	
	// collect walkable areas surrounding this victim
	SurroundingAreasCollector areaVector;
	areaVector = TheNavMesh.CollectSurroundingAreas(CBaseCombatCharacter(victim).GetLastKnownArea(), surroundTravelRange, sv_stepsize.FloatValue, sv_stepsize.FloatValue);
	
	// keep subset that isn't visible to the victim's team
	for (int i = 0; i < areaVector.Count(); i++)
	{
		CTFNavArea area = view_as<CTFNavArea>(areaVector.Get(i));
		
		if (!IsAreaValidForWanderingPopulation(area))
		{
			continue;
		}
		
		if (IsAreaPotentiallyVisibleToTeam(area, TF2_GetClientTeam(victim)))
		{
			continue;
		}
		
		ambushVector.Push(area);
	}
	
	delete areaVector;
	
	if (ambushVector.Length == 0)
	{
		delete ambushVector;
		return false;
	}
	
	int maxTries = Min(10, ambushVector.Length);
	
	for (int retry = 0; retry < maxTries; ++retry)
	{
		int which = GetRandomInt(0, ambushVector.Length - 1);
		CNavArea area = ambushVector.Get(which);
		float where[3];
		area.GetCenter(where);
		AddVectors(where, Vector(0.0, 0.0, sv_stepsize.FloatValue), where);
		
		if (SDKCall_IsSpaceToSpawnHere(where))
		{
			TeleportEntity(actor, where, ZERO_VECTOR, ZERO_VECTOR);
			delete ambushVector;
			return true;
		}
	}
	
	delete ambushVector;
	return false;
}
