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

static ArrayList g_squads;

// Container struct for our values
enum struct CTFBotSquadProperties
{
	int m_id;
	
	ArrayList m_roster;
	int m_leader;
	
	float m_formationSize;
	bool m_bShouldPreserveSquad;
	
	void Init(int id)
	{
		this.m_id = id;
		this.m_leader = -1;
		this.m_bShouldPreserveSquad = false;
		this.m_roster = new ArrayList();
	}
	
	void Delete()
	{
		delete this.m_roster;
	}
}

methodmap CTFBotSquad
{
	public CTFBotSquad(int id)
	{
		return view_as<CTFBotSquad>(id);
	}
	
	property int _id
	{
		public get()
		{
			return view_as<int>(this);
		}
	}
	
	property int _listIndex
	{
		public get()
		{
			return g_squads.FindValue(this._id, CTFBotSquadProperties::m_id);
		}
	}
	
	property ArrayList m_roster
	{
		public get()
		{
			return g_squads.Get(this._listIndex, CTFBotSquadProperties::m_roster);
		}
		public set(ArrayList roster)
		{
			g_squads.Set(this._listIndex, roster, CTFBotSquadProperties::m_roster);
		}
	}
	
	property int m_leader
	{
		public get()
		{
			return g_squads.Get(this._listIndex, CTFBotSquadProperties::m_leader);
		}
		public set(int leader)
		{
			g_squads.Set(this._listIndex, leader, CTFBotSquadProperties::m_leader);
		}
	}
	
	property float m_formationSize
	{
		public get()
		{
			return g_squads.Get(this._listIndex, CTFBotSquadProperties::m_formationSize);
		}
		public set(float formationSize)
		{
			g_squads.Set(this._listIndex, formationSize, CTFBotSquadProperties::m_formationSize);
		}
	}
	
	property bool m_bShouldPreserveSquad
	{
		public get()
		{
			return g_squads.Get(this._listIndex, CTFBotSquadProperties::m_bShouldPreserveSquad);
		}
		public set(bool bShouldPreserveSquad)
		{
			g_squads.Set(this._listIndex, bShouldPreserveSquad, CTFBotSquadProperties::m_bShouldPreserveSquad);
		}
	}
	
	public void Join(int bot)
	{
		// first member is the leader
		if (this.m_roster.Length == 0)
		{
			this.m_leader = bot;
		}
		else if (GameRules_IsMannVsMachineMode())
		{
			//bot->SetFlagTarget( NULL );
		}
		
		PrintToChatAll("%N has joined squad %d", bot, this);
		this.m_roster.Push(bot);
	}
	
	public void Leave(int bot)
	{
		if (this.m_roster.FindValue(bot) != -1)
			this.m_roster.Erase(this.m_roster.FindValue(bot));
		
		if (bot == this.m_leader)
		{
			this.m_leader = -1;
			
			// pick the next living leader that's left in the squad
			if (this.m_bShouldPreserveSquad)
			{
				ArrayList members = new ArrayList();
				this.CollectMembers(members);
				if (members.Length)
				{
					this.m_leader = members.Get(0);
				}
				delete members;
			}
		}
		else if (GameRules_IsMannVsMachineMode())
		{
			/*AssertMsg( !bot->HasFlagTaget(), "Squad member shouldn't have a flag target. Always follow the leader." );
		CCaptureFlag *pFlag = bot->GetFlagToFetch();
		if ( pFlag )
		{
			bot->SetFlagTarget( pFlag );
		}*/
		}
		
		if (this.GetMemberCount() == 0)
		{
			this.DisbandAndDeleteSquad();
		}
		
		PrintToChatAll("%N has left squad %d", bot, this);
	}
	
	public int GetLeader()
	{
		return this.m_leader;
	}
	
	public void CollectMembers(ArrayList &memberList)
	{
		for (int i = 0; i < this.m_roster.Length; ++i)
		{
			if (this.m_roster.Get(i) != -1 && IsPlayerAlive(this.m_roster.Get(i)))
			{
				memberList.Push(this.m_roster.Get(i));
			}
		}
	}
	
	public int GetMemberCount()
	{
		// count the non-NULL members
		int count = 0;
		for (int i = 0; i < this.m_roster.Length; ++i)
		{
			if (this.m_roster.Get(i) != -1 && IsPlayerAlive(this.m_roster.Get(i)))
				++count;
		}
		
		return count;
	}
	
	public bool IsLeader(int bot)
	{
		return this.m_leader == bot;
	}
	
	public void DisbandAndDeleteSquad()
	{
		// Tell each member of the squad to remove this reference
		for (int i = 0; i < this.m_roster.Length; ++i)
		{
			if (this.m_roster.Get(i) != -1)
			{
				Player(this.m_roster.Get(i)).DeleteSquad();
			}
		}
		
		PrintToChatAll("Disbanding squad %d", this);
		this.Delete();
	}
	
	public void Delete()
	{
		if (this._listIndex == -1)
		{
			ThrowError("Failed to delete squad because it wasn't in our list, wtf?");
		}
		
		CTFBotSquadProperties properties;
		g_squads.GetArray(this._listIndex, properties);
		
		properties.Delete();
		g_squads.Erase(this._listIndex);
	}
}

void Squads_Initialize()
{
	g_squads = new ArrayList(sizeof(CTFBotSquadProperties));
}

CTFBotSquad Squads_Create()
{
	// find lowest unused id to assign
	int id = 1;
	while (g_squads.FindValue(id, CTFBotSquadProperties::m_id) != -1)
	{
		id++;
	}
	
	// fill basic properties
	CTFBotSquadProperties properties;
	properties.Init(id);
	
	// store it internally
	g_squads.PushArray(properties);
	
	return CTFBotSquad(id);
}
