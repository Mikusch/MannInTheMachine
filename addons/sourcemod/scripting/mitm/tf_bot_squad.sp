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
		else if (IsMannVsMachineMode())
		{
			Player(bot).SetFlagTarget(INVALID_ENT_REFERENCE);
		}
		
		this.m_roster.Push(bot);
	}
	
	public void Leave(int bot)
	{
		int index = this.m_roster.FindValue(bot);
		if (index != -1)
			this.m_roster.Erase(index);
		
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
		else if (IsMannVsMachineMode())
		{
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
	}
	
	public void CollectMembers(ArrayList &memberList)
	{
		for (int i = 0; i < this.m_roster.Length; ++i)
		{
			int member = this.m_roster.Get(i);
			if (IsClientInGame(member) && IsPlayerAlive(member))
			{
				memberList.Push(member);
			}
		}
	}
	
	public int GetMemberCount()
	{
		// count the non-NULL members
		int count = 0;
		for (int i = 0; i < this.m_roster.Length; ++i)
		{
			int member = this.m_roster.Get(i);
			if (IsClientInGame(member) && IsPlayerAlive(member))
				++count;
		}
		
		return count;
	}
	
	public float GetSlowestMemberSpeed(bool includeLeader = true)
	{
		float speed = FLT_MAX;
		
		int i = includeLeader ? 0 : 1;
		
		for (; i < this.m_roster.Length; ++i)
		{
			int member = this.m_roster.Get(i);
			if (IsClientInGame(member) && IsPlayerAlive(member))
			{
				float memberSpeed = GetEntPropFloat(member, Prop_Send, "m_flMaxspeed");
				if (memberSpeed < speed)
				{
					speed = memberSpeed;
				}
			}
		}
		
		return speed;
	}
	
	public void DisbandAndDeleteSquad()
	{
		// Tell each member of the squad to remove this reference
		for (int i = 0; i < this.m_roster.Length; ++i)
		{
			int member = this.m_roster.Get(i);
			if (IsClientInGame(member))
			{
				Player(member).DeleteSquad();
			}
		}
		
		this.Delete();
	}
	
	public void Delete()
	{
		if (this.m_listIndex == -1)
			return;
		
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
		properties.Init(id);
		
		g_squads.PushArray(properties);
		
		return CTFBotSquad(id);
	}
}
