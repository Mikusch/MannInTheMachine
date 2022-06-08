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

#define NULL_SQUAD	CTFBotSquad(0)

static ArrayList g_squads;

/**
 * Property container for CTFBotSquad.
 *
 */
enum struct CTFBotSquadInfo
{
	int m_id;
	
	ArrayList m_roster;
	int m_leader;
	
	float m_formationSize;
	bool m_bShouldPreserveSquad;
	
	void Initialize(int id)
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

/**
 * A methodmap that replicates the C++ class of the same name in SourcePawn.
 * The data is stored in the associated CTFBotSquadInfo enum struct.
 *
 * The CTFBotSquad::m_id property is used to unique identify different squad objects, with 0 being the NULL_SQUAD.
 *
 */
methodmap CTFBotSquad
{
	public CTFBotSquad(int id)
	{
		return view_as<CTFBotSquad>(id);
	}
	
	property int m_id
	{
		public get()
		{
			return view_as<int>(this);
		}
	}
	
	property int m_listIndex
	{
		public get()
		{
			return g_squads.FindValue(this.m_id, CTFBotSquadInfo::m_id);
		}
	}
	
	property ArrayList m_roster
	{
		public get()
		{
			return g_squads.Get(this.m_listIndex, CTFBotSquadInfo::m_roster);
		}
		public set(ArrayList roster)
		{
			g_squads.Set(this.m_listIndex, roster, CTFBotSquadInfo::m_roster);
		}
	}
	
	property int m_leader
	{
		public get()
		{
			return g_squads.Get(this.m_listIndex, CTFBotSquadInfo::m_leader);
		}
		public set(int leader)
		{
			g_squads.Set(this.m_listIndex, leader, CTFBotSquadInfo::m_leader);
		}
	}
	
	property float m_formationSize
	{
		public get()
		{
			return g_squads.Get(this.m_listIndex, CTFBotSquadInfo::m_formationSize);
		}
		public set(float formationSize)
		{
			g_squads.Set(this.m_listIndex, formationSize, CTFBotSquadInfo::m_formationSize);
		}
	}
	
	property bool m_bShouldPreserveSquad
	{
		public get()
		{
			return g_squads.Get(this.m_listIndex, CTFBotSquadInfo::m_bShouldPreserveSquad);
		}
		public set(bool bShouldPreserveSquad)
		{
			g_squads.Set(this.m_listIndex, bShouldPreserveSquad, CTFBotSquadInfo::m_bShouldPreserveSquad);
		}
	}
	
	public int GetLeader()
	{
		return this.m_leader;
	}
	
	public bool IsLeader(int bot)
	{
		return this.m_leader == bot;
	}
	
	public float GetFormationSize()
	{
		return this.m_formationSize;
	}
	
	public void SetFormationSize(float formationSize)
	{
		this.m_formationSize = formationSize;
	}
	
	public bool ShouldPreserveSquad()
	{
		return this.m_bShouldPreserveSquad;
	}
	
	public void SetShouldPreserveSquad(bool bShouldPreserveSquad)
	{
		this.m_bShouldPreserveSquad = bShouldPreserveSquad;
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
			Player(bot).SetFlagTarget(-1);
		}
		
		this.m_roster.Push(bot);
		
		LogMessage("%N has joined bot squad %d.", bot, this);
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
					LogMessage("%N is the new leader of squad %d.", this.m_leader, this);
				}
				delete members;
			}
		}
		else if (GameRules_IsMannVsMachineMode())
		{
			if (Player(bot).HasFlagTarget())
			{
				ThrowError("Squad member shouldn't have a flag target. Always follow the leader.");
			}
			
			int flag = Player(bot).GetFlagToFetch();
			if (flag != -1)
			{
				Player(bot).SetFlagTarget(flag);
			}
		}
		
		if (this.GetMemberCount() == 0)
		{
			this.DisbandAndDeleteSquad();
		}
		
		LogMessage("%N has left bot squad %d.", bot, this);
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
		
		LogMessage("Disbanding squad %d.", this);
		this.Delete();
	}
	
	public void Delete()
	{
		if (this.m_listIndex == -1)
		{
			ThrowError("Failed to delete squad because it wasn't in our list, wtf?");
		}
		
		CTFBotSquadInfo info;
		g_squads.GetArray(this.m_listIndex, info);
		
		// free up memory and delete it from our internal list
		info.Delete();
		g_squads.Erase(this.m_listIndex);
	}
	
	public static CTFBotSquad Create()
	{
		if (!g_squads)
		{
			g_squads = new ArrayList(sizeof(CTFBotSquadInfo));
		}
		
		// find lowest unused id to assign
		int id = 1;
		while (g_squads.FindValue(id, CTFBotSquadInfo::m_id) != -1)
		{
			id++;
		}
		
		// fill basic properties
		CTFBotSquadInfo properties;
		properties.Initialize(id);
		
		g_squads.PushArray(properties);
		
		return CTFBotSquad(id);
	}
}
