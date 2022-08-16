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
	
	public void AddInvite(int client)
	{
		this.m_invites.Push(client);
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
	
	RegConsoleCmd("sm_party", ConCmd_Party);
}

ArrayList Party_GetAllActiveParties()
{
	return g_parties.Clone();
}

Action ConCmd_Party(int client, int args)
{
	char subcommand[64];
	GetCmdArg(1, subcommand, sizeof(subcommand));
	
	if (StrEqual(subcommand, "create"))
	{
		return HandleCommand_CreateParty(client);
	}
	else if (StrEqual(subcommand, "join"))
	{
		return HandleCommand_JoinParty(client);
	}
	else if (StrEqual(subcommand, "leave"))
	{
		return HandleCommand_LeaveParty(client);
	}
	else if (StrEqual(subcommand, "invite"))
	{
		return HandleCommand_InviteToParty(client, args);
	}
	else if (StrEqual(subcommand, "invites"))
	{
		return HandleCommand_ViewPartyInvites(client, args);
	}
	else if (StrEqual(subcommand, "manage"))
	{
		return HandleCommand_ManageParty(client);
	}
	else if (StrEqual(subcommand, "kick"))
	{
		return HandleCommand_KickFromParty(client, args);
	}
	else
	{
		Menus_DisplayPartyMenu(client);
	}
	
	return Plugin_Handled;
}

static Action HandleCommand_CreateParty(int client)
{
	Party party = Party.Create();
	if (party)
	{
		FakeClientCommand(client, "sm_party join %d", party.m_id);
		ReplyToCommand(client, "%t", "Party_Created", party.m_id);
	}
	
	return Plugin_Handled;
}

static Action HandleCommand_JoinParty(int client)
{
	int id = GetCmdArgInt(2);
	
	Party party = Party(id);
	if (party.IsNull())
	{
		ReplyToCommand(client, "%t", "Party_DoesNotExist");
		return Plugin_Handled;
	}
	
	if (Player(client).m_party == party)
	{
		ReplyToCommand(client, "%t", "Party_AlreadyMember");
		return Plugin_Handled;
	}
	
	// first player can always join, everyone else needs an invite
	if (party.GetMemberCount() > 0 && !party.IsInvited(client))
	{
		ReplyToCommand(client, "%t", "Party_RequireInvite");
		return Plugin_Handled;
	}
	
	if (party.GetMemberCount() > 6)
	{
		ReplyToCommand(client, "%t", "Party_MaxMembers");
		return Plugin_Handled;
	}
	
	Player(client).JoinParty(party);
	
	if (!party.IsLeader(client))
	{
		ReplyToCommand(client, "%t", "Party_Joined", id);
	}
	
	return Plugin_Handled;
}

static Action HandleCommand_LeaveParty(int client)
{
	if (!Player(client).IsInAParty())
	{
		ReplyToCommand(client, "%t", "Party_RequireMember");
		return Plugin_Handled;
	}
	
	Party party = Player(client).GetParty();
	
	Player(client).LeaveParty();
	ReplyToCommand(client, "%t", "Party_Left", party.m_id);
	
	return Plugin_Handled;
}

static Action HandleCommand_InviteToParty(int client, int args)
{
	if (!Player(client).IsInAParty())
	{
		ReplyToCommand(client, "%t", "Party_RequireMember");
		return Plugin_Handled;
	}
	
	if (!Player(client).GetParty().IsLeader(client))
	{
		ReplyToCommand(client, "%t", "Party_RequireLeader");
		return Plugin_Handled;
	}
	
	if (Player(client).GetParty().GetMemberCount() > 6)
	{
		ReplyToCommand(client, "%t", "Party_MaxMembers");
		return Plugin_Handled;
	}
	
	if (args >= 2)
	{
		char target[MAX_TARGET_LENGTH];
		GetCmdArg(2, target, sizeof(target));
		
		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		
		if ((target_count = ProcessTargetString(target, client, target_list, MaxClients + 1, COMMAND_TARGET_NONE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		for (int i = 0; i < target_count; i++)
		{
			if (target_list[i] == client)
				continue;
			
			if (Player(target_list[i]).IsInAParty())
				continue;
			
			Player(target_list[i]).InviteToParty(Player(client).GetParty());
		}
		
		if (tn_is_ml)
		{
			CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_InvitedPlayers", target_name);
		}
		else
		{
			CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_InvitedPlayers", "_s", target_name);
		}
	}
	else
	{
		Menus_OpenPartyManageInviteMenu(client);
	}
	
	return Plugin_Handled;
}

static Action HandleCommand_ViewPartyInvites(int client, int args)
{
	Menus_DisplayPartyInviteMenu(client);
	
	return Plugin_Handled;
}

static Action HandleCommand_ManageParty(int client)
{
	if (!Player(client).IsInAParty())
	{
		ReplyToCommand(client, "%t", "Party_RequireMember");
		return Plugin_Handled;
	}
	
	if (!Player(client).GetParty().IsLeader(client))
	{
		ReplyToCommand(client, "%t", "Party_RequireLeader");
		return Plugin_Handled;
	}
	
	Menus_DisplayPartyManageMenu(client);
	
	return Plugin_Handled;
}

static Action HandleCommand_KickFromParty(int client, int args)
{
	if (!Player(client).IsInAParty())
	{
		ReplyToCommand(client, "%t", "Party_RequireMember");
		return Plugin_Handled;
	}
	
	if (!Player(client).GetParty().IsLeader(client))
	{
		ReplyToCommand(client, "%t", "Party_RequireLeader");
		return Plugin_Handled;
	}
	
	if (args >= 2)
	{
		char target[MAX_TARGET_LENGTH];
		GetCmdArg(2, target, sizeof(target));
		
		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		
		if ((target_count = ProcessTargetString(target, client, target_list, MaxClients + 1, COMMAND_TARGET_NONE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		for (int i = 0; i < target_count; i++)
		{
			if (target_list[i] == client)
				continue;
			
			if (Player(target_list[i]).GetParty() != Player(client).GetParty())
				continue;
			
			Player(target_list[i]).LeaveParty();
			PrintToChat(target_list[i], "%t", "Party_Kicked");
		}
		
		if (tn_is_ml)
		{
			CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_KickedPlayers", target_name);
		}
		else
		{
			CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_KickedPlayers", "_s", target_name);
		}
	}
	else
	{
		Menus_OpenPartyManageKickMenu(client);
	}
	
	return Plugin_Handled;
}
