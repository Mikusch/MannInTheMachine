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

static CountdownTimer m_waitTimer[MAXPLAYERS + 1];
static int m_attempt[MAXPLAYERS + 1];

void SpyLeaveSpawnRoomStart(int me)
{
	// disguise as enemy team
	Player(me).DisguiseAsMemberOfEnemyTeam();
	
	// cloak
	SDKCall_DoClassSpecialSkill(me);
	
	// wait a few moments to guarantee a minimum time between announcing Spies and their attack
	m_waitTimer[me].Start(2.0 + GetRandomFloat(0.0, 1.0));
	
	m_attempt[me] = 0;
}

void SpyLeaveSpawnRoomUpdate(int me)
{
	if (m_waitTimer[me].HasStarted() && m_waitTimer[me].IsElapsed())
	{
		int victim = -1;
		
		ArrayList enemyVector = new ArrayList(MaxClients);
		
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client))
				continue;
			
			if (TF2_GetClientTeam(client) == TF2_GetClientTeam(me))
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
			if (TeleportNearVictim(me, enemyVector.Get(i), m_attempt[me]))
			{
				victim = enemyVector.Get(i);
				break;
			}
		}
		
		// if we didn't find a victim, try again in a bit
		if (victim == -1)
		{
			m_waitTimer[me].Start(1.0);
			
			++m_attempt[me];
			
			delete enemyVector;
			return;
		}
		
		m_waitTimer[me].Invalidate();
		delete enemyVector;
		return;
	}
}

bool TeleportNearVictim(int me, int victim, int attempt)
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
			TeleportEntity(me, where, ZERO_VECTOR, ZERO_VECTOR);
			delete ambushVector;
			return true;
		}
	}
	
	delete ambushVector;
	return false;
}
