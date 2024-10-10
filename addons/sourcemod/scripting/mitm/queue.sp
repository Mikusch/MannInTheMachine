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

ArrayList Queue_GetDefenderQueue()
{
	ArrayList queue = new ArrayList(sizeof(QueueData));
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (IsClientSourceTV(client))
			continue;
		
		if (TF2_GetClientTeam(client) == TFTeam_Unassigned)
			continue;
		
		// ignore players in a party, they get handled separately
		if (CTFPlayer(client).IsInAParty() && CTFPlayer(client).GetParty().GetMemberCount() > 1)
			continue;
		
		if (CTFPlayer(client).HasPreference(PREF_DEFENDER_DISABLE_QUEUE) || CTFPlayer(client).HasPreference(PREF_SPECTATOR_MODE))
			continue;
		
		if (!IsFakeClient(client) && (GetClientAvgLatency(client, NetFlow_Outgoing) * 1000.0) >= sm_mitm_defender_ping_limit.FloatValue)
			continue;
		
		if (!Forwards_OnIsValidDefender(client))
			continue;
		
		QueueData data;
		data.m_points = CTFPlayer(client).GetQueuePoints();
		data.m_client = client;
		data.m_party = NULL_PARTY;
		
		queue.PushArray(data);
	}
	
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
	
	// sort by queue points
	queue.Sort(Sort_Descending, Sort_Integer);
	
	return queue;
}
