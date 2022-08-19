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

ArrayList Queue_GetDefenderQueue()
{
	ArrayList queueList = new ArrayList(sizeof(QueueData));
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (IsClientSourceTV(client))
			continue;
		
		// do not include players in parties, they get handled separately
		if (Player(client).IsInAParty() && Player(client).GetParty().GetMemberCount() > 1)
			continue;
		
		if (TF2_GetClientTeam(client) == TFTeam_Unassigned)
			continue;
		
		if (Player(client).HasPreference(PREF_DISABLE_DEFENDER) || Player(client).HasPreference(PREF_DISABLE_SPAWNING))
			continue;
		
		if (Player(client).m_defenderQueuePoints == -1)
			continue;
		
		QueueData data;
		data.m_points = Player(client).m_defenderQueuePoints;
		data.m_client = client;
		
		queueList.PushArray(data);
	}
	
	ArrayList parties = Party_GetAllActiveParties();
	for (int i = 0; i < parties.Length; i++)
	{
		PartyInfo info;
		if (!parties.GetArray(i, info))
			continue;
		
		Party party = Party(info.m_id);
		
		// do not include one-person parties
		if (party.GetMemberCount() <= 1)
			continue;
		
		QueueData data;
		data.m_points = party.CalculateQueuePoints();
		data.m_party = party;
		
		queueList.PushArray(data);
	}
	delete parties;
	
	// sorts by queue points
	queueList.Sort(Sort_Descending, Sort_Integer);
	
	return queueList;
}

void Queue_AddPoints(int client, int points)
{
	Player(client).m_defenderQueuePoints += points;
	ClientPrefs_SaveQueue(client, Player(client).m_defenderQueuePoints);
}

void Queue_SetPoints(int client, int points)
{
	Player(client).m_defenderQueuePoints = points;
	ClientPrefs_SaveQueue(client, Player(client).m_defenderQueuePoints);
}
