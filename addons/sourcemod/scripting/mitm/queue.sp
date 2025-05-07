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

enum struct QueueData
{
	int m_points;
	int m_client;
	Party m_party;
}

bool Queue_IsEnabled()
{
	return mitm_queue_enabled.BoolValue;
}

/**
 * Returns the defender queue, sorted by queue points.
 *
 * @return	ArrayList<QueueData>
 */
ArrayList Queue_GetDefenderQueue()
{
	ArrayList queue = new ArrayList(sizeof(QueueData));
	
	ArrayList parties = Party_GetAllActiveParties();
	for (int i = 0; i < parties.Length; i++)
	{
		PartyInfo info;
		if (!parties.GetArray(i, info))
			continue;
		
		Party party = Party(info.m_id);
		
		// do not include parties with only one member
		if (party.GetMemberCount() <= 1)
			continue;
		
		QueueData data;
		data.m_points = party.CalculateQueuePoints();
		data.m_client = -1;
		data.m_party = party;
		
		queue.PushArray(data);
	}
	delete parties;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		// ignore party clients (see above)
		if (CTFPlayer(client).IsInAParty() && CTFPlayer(client).GetParty().GetMemberCount() > 1)
			continue;
		
		if (!CTFPlayer(client).IsValidDefender())
			continue;
		
		QueueData data;
		data.m_points = CTFPlayer(client).GetQueuePoints();
		data.m_client = client;
		data.m_party = NULL_PARTY;
		
		queue.PushArray(data);
	}
	
	// sort by queue points
	queue.Sort(Sort_Descending, Sort_Integer);
	
	return queue;
}

void Queue_SelectDefenders()
{
	ArrayList players = new ArrayList();
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (IsClientSourceTV(client))
			continue;
		
		if (CTFPlayer(client).HasPreference(PREF_SPECTATOR_MODE))
			continue;
		
		players.Push(client);
	}
	
	ArrayList queue = Queue_GetDefenderQueue();
	int iDefenderCount = 0, iReqDefenderCount = tf_mvm_defenders_team_size.IntValue;
	
	// Select our defenders
	for (int i = 0; i < queue.Length; i++)
	{
		int client = queue.Get(i, QueueData::m_client);
		Party party = queue.Get(i, QueueData::m_party);
		
		// All members of a party queue together
		if (party.IsValid())
		{
			// Only let parties play if all members have space to join
			if (iReqDefenderCount - iDefenderCount - party.GetMemberCount(false) < 0)
				continue;
			
			int[] members = new int[MaxClients];
			int count = party.CollectMembers(members, false);
			for (int j = 0; j < count; j++)
			{
				int member = members[j];
				
				CTFPlayer(member).SetAsDefender();
				CTFPlayer(member).SetQueuePoints(0);
				CPrintToChat(member, "%s %t %t", PLUGIN_TAG, "SelectedAsDefender", "Queue_PointsReset");
				
				players.Erase(players.FindValue(member));
				++iDefenderCount;
			}
		}
		else
		{
			CTFPlayer(client).SetAsDefender();
			CTFPlayer(client).SetQueuePoints(0);
			CPrintToChat(client, "%s %t %t", PLUGIN_TAG, "SelectedAsDefender", "Queue_PointsReset");
			
			players.Erase(players.FindValue(client));
			++iDefenderCount;
		}
		
		// If we have enough defenders, early out
		if (iReqDefenderCount <= iDefenderCount)
			break;
	}
	
	// We have less defenders than we wanted.
	// Pick random players, regardless of their defender preference.
	if (iDefenderCount < iReqDefenderCount)
	{
		players.Sort(Sort_Random, Sort_Integer);
		
		for (int i = 0; i < players.Length; i++)
		{
			int client = players.Get(i);
			
			// Keep filling slots until our quota is met
			if (iDefenderCount++ >= iReqDefenderCount)
				break;
			
			CTFPlayer(client).SetAsDefender();
			CPrintToChat(client, "%s %t %t", PLUGIN_TAG, "SelectedAsDefender_Forced", "Queue_NotReset");
			
			players.Erase(i);
		}
	}
	
	if (iDefenderCount < iReqDefenderCount)
	{
		LogError("Not enough players to meet defender quota (%d/%d)", iDefenderCount, iReqDefenderCount);
	}
	
	int points = mitm_queue_points.IntValue;
	
	// Move everyone else to the spectator team
	for (int i = 0; i < players.Length; i++)
	{
		int client = players.Get(i);
		
		CTFPlayer player = CTFPlayer(client);
		
		player.ForceChangeTeam(TFTeam_Spectator);
		CPrintToChat(client, "%s %t", PLUGIN_TAG, "SelectedAsInvader");
		
		if (!CTFPlayer(client).HasPreference(PREF_DEFENDER_DISABLE_QUEUE))
		{
			player.AddQueuePoints(points);
			CPrintToChat(client, "%s %t", PLUGIN_TAG, "Queue_PointsAwarded", points, player.GetQueuePoints());
		}
	}
	
	// Free the memory
	delete players;
	delete queue;
}

void Queue_FindReplacementDefender()
{
	ArrayList queue = Queue_GetDefenderQueue();
	for (int i = 0; i < queue.Length; i++)
	{
		int client = queue.Get(i, QueueData::m_client);
		
		// Exclude parties in queue
		if (client == -1)
			continue;
		
		if (!CTFPlayer(client).IsValidReplacementDefender())
			continue;
		
		// Don't force switch because we want GetTeamAssignmentOverride to decide
		TF2_ChangeClientTeam(client, TFTeam_Defenders);
		
		// Validate that they were successfully switched
		if (TF2_GetClientTeam(client) == TFTeam_Defenders)
		{
			CTFPlayer(client).SetQueuePoints(0);
			CPrintToChat(client, "%s %t %t", PLUGIN_TAG, "SelectedAsDefender_Replacement", "Queue_PointsReset");
			break;
		}
	}
	
	delete queue;
}
