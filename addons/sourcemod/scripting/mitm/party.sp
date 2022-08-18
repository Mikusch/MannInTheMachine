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

#define NULL_PARTY	Party(0)

static ArrayList g_parties;

/**
 * Property container for Party.
 *
 */
enum struct PartyInfo
{
	int m_id;
	
	char name[MAX_NAME_LENGTH];
	
	ArrayList m_members;
	ArrayList m_invites;
	int m_leader;
	
	void Initialize(int id)
	{
		this.m_id = id;
		this.m_leader = -1;
		this.m_members = new ArrayList();
		this.m_invites = new ArrayList();
	}
	
	void Delete()
	{
		delete this.m_members;
	}
}

methodmap Party
{
	public Party(int id)
	{
		return view_as<Party>(id);
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
			return g_parties.FindValue(this.m_id, PartyInfo::m_id);
		}
	}
	
	property ArrayList m_members
	{
		public get()
		{
			return g_parties.Get(this.m_listIndex, PartyInfo::m_members);
		}
		public set(ArrayList members)
		{
			g_parties.Set(this.m_listIndex, members, PartyInfo::m_members);
		}
	}
	
	property ArrayList m_invites
	{
		public get()
		{
			return g_parties.Get(this.m_listIndex, PartyInfo::m_invites);
		}
		public set(ArrayList invites)
		{
			g_parties.Set(this.m_listIndex, invites, PartyInfo::m_invites);
		}
	}
	
	property int m_leader
	{
		public get()
		{
			return g_parties.Get(this.m_listIndex, PartyInfo::m_leader);
		}
		public set(int leader)
		{
			g_parties.Set(this.m_listIndex, leader, PartyInfo::m_leader);
		}
	}
	
	public int GetLeader()
	{
		return this.m_leader;
	}
	
	public void GetName(char[] buffer, int maxlen)
	{
		PartyInfo info;
		if (g_parties.GetArray(this.m_listIndex, info) && strlen(info.name) != 0)
		{
			strcopy(buffer, maxlen, info.name);
		}
		else
		{
			Format(buffer, maxlen, "Party #%d", this.m_id);
		}
	}
	
	public void SetName(const char[] name)
	{
		PartyInfo info;
		if (g_parties.GetArray(this.m_listIndex, info))
		{
			strcopy(info.name, sizeof(info.name), name);
			CRemoveTags(info.name, sizeof(info.name));
			
			g_parties.SetArray(this.m_listIndex, info);
		}
	}
	
	public void AddInvite(int client)
	{
		this.m_invites.Push(client);
	}
	
	public void RemoveInvite(int client)
	{
		int index = this.m_invites.FindValue(client);
		if (index == -1)
			return;
		
		this.m_invites.Erase(index);
	}
	
	public bool IsInvited(int client)
	{
		return this.m_invites.FindValue(client) != -1;
	}
	
	public void Join(int client)
	{
		// first member is the leader
		if (this.m_members.Length == 0)
		{
			this.m_leader = client;
		}
		
		this.m_members.Push(client);
		
		// remove the invite
		int index = this.m_invites.FindValue(client);
		if (index != -1)
			this.m_invites.Erase(index);
	}
	
	public void Leave(int client)
	{
		int index = this.m_members.FindValue(client);
		if (index != -1)
			this.m_members.Erase(index);
		
		if (client == this.m_leader)
		{
			this.m_leader = -1;
			
			// pick the next leader that's left in the party
			ArrayList members = new ArrayList();
			this.CollectMembers(members);
			if (members.Length)
			{
				this.m_leader = members.Get(0);
			}
			delete members;
		}
		
		if (this.GetMemberCount() == 0)
		{
			this.DisbandAndDeleteParty();
		}
	}
	
	public void CollectMembers(ArrayList &memberList)
	{
		for (int i = 0; i < this.m_members.Length; ++i)
		{
			int member = this.m_members.Get(i);
			if (IsValidEntity(member))
			{
				memberList.Push(member);
			}
		}
	}
	
	public int GetMemberCount()
	{
		// count the non-NULL members
		int count = 0;
		for (int i = 0; i < this.m_members.Length; ++i)
		{
			int member = this.m_members.Get(i);
			if (IsValidEntity(member))
				++count;
		}
		
		return count;
	}
	
	public int CalculateQueuePoints()
	{
		int count = 0, points = 0;
		for (int i = 0; i < this.m_members.Length; ++i)
		{
			int member = this.m_members.Get(i);
			if (IsValidEntity(member) && !Player(member).HasPreference(PREF_DISABLE_DEFENDER) && !Player(member).HasPreference(PREF_DISABLE_SPAWNING))
			{
				++count;
				points += Player(member).m_defenderQueuePoints;
			}
		}
		
		return count != 0 ? (points / count) : 0;
	}
	
	public bool IsLeader(int client)
	{
		return this.m_leader == client;
	}
	
	public bool IsNull()
	{
		return this.m_listIndex == -1;
	}
	
	public void DisbandAndDeleteParty()
	{
		// Tell each member of the party to remove this reference
		for (int i = 0; i < this.m_members.Length; ++i)
		{
			int member = this.m_members.Get(i);
			if (IsValidEntity(member))
			{
				Player(member).DeleteParty();
			}
		}
		
		this.Delete();
	}
	
	public void Delete()
	{
		if (this.IsNull())
			return;
		
		PartyInfo info;
		g_parties.GetArray(this.m_listIndex, info);
		
		// free up memory and delete it from our internal list
		info.Delete();
		g_parties.Erase(this.m_listIndex);
	}
	
	public static Party Create()
	{
		// party id's do not get reused and simply increment each time
		static int s_id = 0;
		s_id++;
		
		// fill basic properties
		PartyInfo properties;
		properties.Initialize(s_id);
		
		g_parties.PushArray(properties);
		
		return Party(s_id);
	}
}

void Party_Init()
{
	g_parties = new ArrayList(sizeof(PartyInfo));
	
	RegConsoleCmd("sm_party_create", ConCmd_PartyCreate, "Create a new party.");
	RegConsoleCmd("sm_party_join", ConCmd_PartyJoin, "Join a party.");
	RegConsoleCmd("sm_party_leave", ConCmd_PartyLeave, "Leave your party.");
	RegConsoleCmd("sm_party_invite", ConCmd_PartyInvite, "Invite a player to your party.");
	RegConsoleCmd("sm_party_manage", ConCmd_PartyManage, "Manage your party.");
	RegConsoleCmd("sm_party_kick", ConCmd_PartyKick, "Kick a player from your party.");
	RegConsoleCmd("sm_party_name", ConCmd_PartyName, "Rename your party.");
}

ArrayList Party_GetAllActiveParties()
{
	return g_parties.Clone();
}

static Action ConCmd_PartyCreate(int client, int args)
{
	Party party = Party.Create();
	if (party)
	{
		FakeClientCommand(client, "sm_party_join %d", party.m_id);
		
		char name[MAX_NAME_LENGTH];
		party.GetName(name, sizeof(name));
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_Created", name);
		ClientCommand(client, "play ui/message_update.wav");
	}
	
	return Plugin_Handled;
}

static Action ConCmd_PartyJoin(int client, int args)
{
	if (args < 1)
	{
		Menus_DisplayPartyInviteMenu(client);
		return Plugin_Handled;
	}
	
	int id = GetCmdArgInt(1);
	
	Party party = Party(id);
	if (party.IsNull())
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_DoesNotExist");
		return Plugin_Handled;
	}
	
	if (Player(client).m_party == party)
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_AlreadyMember");
		return Plugin_Handled;
	}
	
	// first player can always join, everyone else needs an invite
	if (party.GetMemberCount() > 0 && !party.IsInvited(client))
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_RequireInvite");
		return Plugin_Handled;
	}
	
	if (party.GetMemberCount() > 6)
	{
		party.RemoveInvite(client);
		
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_MaxMembers");
		return Plugin_Handled;
	}
	
	Player(client).JoinParty(party);
	
	// notify the new member
	if (!party.IsLeader(client))
	{
		party.RemoveInvite(client);
		
		char name[MAX_NAME_LENGTH];
		party.GetName(name, sizeof(name));
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_Joined", name);
		ClientCommand(client, "play ui/message_update.wav");
	}
	
	// notify all other members
	ArrayList members = new ArrayList();
	party.CollectMembers(members);
	for (int i = 0; i < members.Length; i++)
	{
		int member = members.Get(i);
		if (member == client)
			continue;
		
		CPrintToChat(member, "%s %t", PLUGIN_TAG, "Party_JoinedOther", client);
		ClientCommand(member, "play ui/message_update.wav");
	}
	delete members;
	
	return Plugin_Handled;
}

static Action ConCmd_PartyLeave(int client, int args)
{
	if (!Player(client).IsInAParty())
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_RequireMember");
		return Plugin_Handled;
	}
	
	Party party = Player(client).GetParty();
	
	char name[MAX_NAME_LENGTH];
	party.GetName(name, sizeof(name));
	
	Player(client).LeaveParty();
	
	// party might be gone now
	if (!party.IsNull())
	{
		// notify all members
		ArrayList members = new ArrayList();
		party.CollectMembers(members);
		for (int i = 0; i < members.Length; i++)
		{
			int member = members.Get(i);
			CPrintToChat(member, "%s %t", PLUGIN_TAG, "Party_LeftOther", client);
			ClientCommand(member, "play ui/message_update.wav");
		}
		delete members;
	}
	
	CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_Left", name);
	ClientCommand(client, "play ui/message_update.wav");
	return Plugin_Handled;
}

static Action ConCmd_PartyInvite(int client, int args)
{
	if (!Player(client).IsInAParty())
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_RequireMember");
		return Plugin_Handled;
	}
	
	Party party = Player(client).GetParty();
	
	if (!party.IsLeader(client))
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_RequireLeader");
		return Plugin_Handled;
	}
	
	if (party.GetMemberCount() > 6)
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_MaxMembers");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		Menus_DisplayPartyManageInviteMenu(client);
		return Plugin_Handled;
	}
	
	char target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(target, 0, target_list, MaxClients + 1, COMMAND_TARGET_NONE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	char name[MAX_NAME_LENGTH];
	party.GetName(name, sizeof(name));
	
	for (int i = 0; i < target_count; i++)
	{
		if (target_list[i] == client)
			continue;
		
		if (Player(target_list[i]).IsInAParty())
			continue;
		
		if (party.IsInvited(target_list[i]))
			continue;
		
		Player(target_list[i]).InviteToParty(party);
		
		CPrintToChat(target_list[i], "%s %t", PLUGIN_TAG, "Party_IncomingInvite", name, client);
		ClientCommand(target_list[i], "play ui/notification_alert.wav");
	}
	
	if (tn_is_ml)
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_InvitedPlayers", target_name, name);
	}
	else
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_InvitedPlayers", "_s", target_name, name);
	}
	
	return Plugin_Handled;
}

static Action ConCmd_PartyManage(int client, int args)
{
	if (!Player(client).IsInAParty())
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_RequireMember");
		return Plugin_Handled;
	}
	
	if (!Player(client).GetParty().IsLeader(client))
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_RequireLeader");
		return Plugin_Handled;
	}
	
	Menus_DisplayPartyManageMenu(client);
	return Plugin_Handled;
}

static Action ConCmd_PartyKick(int client, int args)
{
	if (!Player(client).IsInAParty())
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_RequireMember");
		return Plugin_Handled;
	}
	
	if (!Player(client).GetParty().IsLeader(client))
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_RequireLeader");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		Menus_DisplayPartyManageKickMenu(client);
		return Plugin_Handled;
	}
	
	char target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(target, 0, target_list, MaxClients + 1, COMMAND_TARGET_NONE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	Party party = Player(client).GetParty();
	
	for (int i = 0; i < target_count; i++)
	{
		if (target_list[i] == client)
			continue;
		
		if (Player(target_list[i]).GetParty() != party)
			continue;
		
		Player(target_list[i]).LeaveParty();
		
		char name[MAX_NAME_LENGTH];
		party.GetName(name, sizeof(name));
		CPrintToChat(target_list[i], "%s %t", PLUGIN_TAG, "Party_Kicked", name);
		ClientCommand(target_list[i], "play ui/message_update.wav");
		
		// notify all other members
		ArrayList members = new ArrayList();
		party.CollectMembers(members);
		for (int j = 0; j < members.Length; j++)
		{
			int member = members.Get(j);
			CPrintToChat(member, "%s %t", PLUGIN_TAG, "Party_KickedOther", target_list[i]);
			ClientCommand(member, "play ui/message_update.wav");
		}
		delete members;
	}
	
	return Plugin_Handled;
}

static Action ConCmd_PartyName(int client, int args)
{
	if (!Player(client).IsInAParty())
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_RequireMember");
		return Plugin_Handled;
	}
	
	Party party = Player(client).GetParty();
	
	if (!party.IsLeader(client))
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_RequireLeader");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_party_name <name>");
		return Plugin_Handled;
	}
	
	char name[MAX_NAME_LENGTH];
	GetCmdArg(1, name, sizeof(name));
	party.SetName(name);
	
	CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_Renamed", name);
	return Plugin_Handled;
}
