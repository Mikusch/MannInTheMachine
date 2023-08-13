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

#define MAX_PARTY_NAME_LENGTH	32

#define SYMBOL_PARTY_LEADER	"★"
#define SYMBOL_PARTY_MEMBER	"☆"
#define SYMBOL_PARTY_OTHER	"◆"

#define SOUND_PARTY_UPDATE	"ui/message_update.wav"
#define SOUND_PARTY_INVITE	"ui/notification_alert.wav"

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
	
	void Init(int id)
	{
		this.m_id = id;
		this.m_leader = -1;
		this.m_members = new ArrayList();
		this.m_invites = new ArrayList();
	}
	
	void Delete()
	{
		delete this.m_members;
		delete this.m_invites;
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
	
	public bool GetName(char[] buffer, int maxlen)
	{
		PartyInfo info;
		if (g_parties.GetArray(this.m_listIndex, info) && strlen(info.name) != 0)
		{
			return strcopy(buffer, maxlen, info.name) != 0;
		}
		else
		{
			return Format(buffer, maxlen, "%T", "Party_Name_Default", LANG_SERVER, this.GetLeader()) != 0;
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
	
	public int GetMaxPlayers()
	{
		int iMaxPartySize = sm_mitm_party_max_size.IntValue, iDefenderCount = tf_mvm_defenders_team_size.IntValue;
		return (iMaxPartySize == 0) ? iDefenderCount : Min(iMaxPartySize, iDefenderCount);
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
			int[] members = new int[MaxClients];
			if (this.CollectMembers(members, MaxClients))
			{
				this.m_leader = members[0];
			}
		}
		
		if (this.GetMemberCount() == 0)
		{
			this.DisbandAndDeleteParty();
		}
	}
	
	public int CollectMembers(int[] clients, int size, bool bIncludeSpectators = true)
	{
		int count = 0;
		
		for (int i = 0; i < this.m_members.Length; ++i)
		{
			int member = this.m_members.Get(i);
			
			if (!IsClientInGame(member))
				continue;
			
			if (!bIncludeSpectators && CTFPlayer(member).HasPreference(PREF_SPECTATOR_MODE))
				continue;
			
			clients[count++] = member;
		}
		
		return count;
	}
	
	public int GetMemberCount(bool bIncludeSpectators = true)
	{
		int[] members = new int[MaxClients];
		return this.CollectMembers(members, MaxClients, bIncludeSpectators);
	}
	
	public int CalculateQueuePoints()
	{
		int points = 0;
		
		int[] members = new int[MaxClients];
		int count = this.CollectMembers(members, MaxClients, false);
		for (int i = 0; i < count; ++i)
		{
			points += CTFPlayer(members[i]).m_defenderQueuePoints;
		}
		
		if (count)
		{
			// average of all members queue points
			points = (points / count);
		}
		
		return points;
	}
	
	public void OnPartyMemberLeave(int client)
	{
		if (this.m_members.FindValue(client) == -1)
			return;
		
		// fetch the name while the player is still in the party
		char name[MAX_NAME_LENGTH];
		this.GetName(name, sizeof(name));
		
		CTFPlayer(client).LeaveParty();
		CancelClientMenu(client);
		
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_Left", name);
		ClientCommand(client, "play %s", SOUND_PARTY_UPDATE);
		
		// the party might be disbanded now
		if (this.IsValid())
		{
			// notify all members
			int[] members = new int[MaxClients];
			int count = this.CollectMembers(members, MaxClients);
			for (int i = 0; i < count; ++i)
			{
				int member = members[i];
				
				// refresh party menu if active
				if (CTFPlayer(member).IsPartyMenuActive())
				{
					Menus_DisplayPartyMenu(member);
				}
				
				CPrintToChat(member, "%s %t", PLUGIN_TAG, "Party_LeftOther", client);
				ClientCommand(member, "play %s", SOUND_PARTY_UPDATE);
			}
		}
	}
	
	public bool IsLeader(int client)
	{
		return this.m_leader == client;
	}
	
	public bool IsValid()
	{
		if (this == NULL_PARTY)
			return false;
		
		return this.m_listIndex != -1;
	}
	
	public void DisbandAndDeleteParty()
	{
		// Tell each member of the party to remove this reference
		for (int i = 0; i < this.m_members.Length; ++i)
		{
			int member = this.m_members.Get(i);
			if (IsClientInGame(member))
			{
				CTFPlayer(member).DeleteParty();
			}
		}
		
		this.Delete();
	}
	
	public void Delete()
	{
		if (!this.IsValid())
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
		properties.Init(s_id);
		
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

bool Party_ShouldRunCommand(int client)
{
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return false;
	}
	
	if (!sm_mitm_party_enabled.BoolValue)
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_FeatureDisabled");
		return false;
	}
	
	return true;
}

static Action ConCmd_PartyCreate(int client, int args)
{
	if (!Party_ShouldRunCommand(client))
		return Plugin_Handled;
	
	Party party = Party.Create();
	if (party)
	{
		FakeClientCommand(client, "sm_party_join %d", party.m_id);
		
		char name[MAX_NAME_LENGTH];
		party.GetName(name, sizeof(name));
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_Created", name);
		ClientCommand(client, "play %s", SOUND_PARTY_UPDATE);
	}
	
	return Plugin_Handled;
}

static Action ConCmd_PartyJoin(int client, int args)
{
	if (!Party_ShouldRunCommand(client))
		return Plugin_Handled;
	
	if (args < 1)
	{
		Menus_DisplayPartyInviteMenu(client);
		return Plugin_Handled;
	}
	
	int id = GetCmdArgInt(1);
	
	Party party = Party(id);
	if (!party.IsValid())
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_DoesNotExist");
		return Plugin_Handled;
	}
	
	if (CTFPlayer(client).m_party == party)
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
	
	if (party.GetMemberCount() >= party.GetMaxPlayers())
	{
		party.RemoveInvite(client);
		
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_MaxMembers");
		return Plugin_Handled;
	}
	
	// leave current party
	if (CTFPlayer(client).IsInAParty())
	{
		FakeClientCommand(client, "sm_party_leave");
	}
	
	CTFPlayer(client).JoinParty(party);
	
	// notify the new member
	if (!party.IsLeader(client))
	{
		party.RemoveInvite(client);
		
		char name[MAX_NAME_LENGTH];
		party.GetName(name, sizeof(name));
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_Joined", name);
		ClientCommand(client, "play %s", SOUND_PARTY_UPDATE);
	}
	
	// display party
	Menus_DisplayPartyMenu(client);
	
	// notify all other members
	int[] members = new int[MaxClients];
	int count = party.CollectMembers(members, MaxClients);
	for (int i = 0; i < count; ++i)
	{
		int member = members[i];
		
		if (member == client)
			continue;
		
		// refresh party menu if active
		if (CTFPlayer(member).IsPartyMenuActive())
		{
			Menus_DisplayPartyMenu(member);
		}
		
		CPrintToChat(member, "%s %t", PLUGIN_TAG, "Party_JoinedOther", client);
		ClientCommand(member, "play %s", SOUND_PARTY_UPDATE);
	}
	
	return Plugin_Handled;
}

static Action ConCmd_PartyLeave(int client, int args)
{
	if (!Party_ShouldRunCommand(client))
		return Plugin_Handled;
	
	if (!CTFPlayer(client).IsInAParty())
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_RequireMember");
		return Plugin_Handled;
	}
	
	Party party = CTFPlayer(client).GetParty();
	party.OnPartyMemberLeave(client);
	
	return Plugin_Handled;
}

static Action ConCmd_PartyInvite(int client, int args)
{
	if (!Party_ShouldRunCommand(client))
		return Plugin_Handled;
	
	if (!CTFPlayer(client).IsInAParty())
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_RequireMember");
		return Plugin_Handled;
	}
	
	Party party = CTFPlayer(client).GetParty();
	
	if (!party.IsLeader(client))
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_RequireLeader");
		return Plugin_Handled;
	}
	
	if (party.GetMemberCount() >= party.GetMaxPlayers())
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
	
	if ((target_count = ProcessTargetString(target, 0, target_list, sizeof(target_list), COMMAND_TARGET_NONE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	char name[MAX_NAME_LENGTH];
	party.GetName(name, sizeof(name));
	
	for (int i = 0; i < target_count; ++i)
	{
		if (target_list[i] == client)
			continue;
		
		if (party.IsInvited(target_list[i]))
			continue;
		
		if (CTFPlayer(target_list[i]).HasPreference(PREF_IGNORE_PARTY_INVITES))
			continue;
		
		CTFPlayer(target_list[i]).InviteToParty(party);
		
		CPrintToChat(target_list[i], "%s %t", PLUGIN_TAG, "Party_IncomingInvite", name, client);
		ClientCommand(target_list[i], "play %s", SOUND_PARTY_INVITE);
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
	if (!Party_ShouldRunCommand(client))
		return Plugin_Handled;
	
	if (!CTFPlayer(client).IsInAParty())
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_RequireMember");
		return Plugin_Handled;
	}
	
	if (!CTFPlayer(client).GetParty().IsLeader(client))
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_RequireLeader");
		return Plugin_Handled;
	}
	
	Menus_DisplayPartyManageMenu(client);
	return Plugin_Handled;
}

static Action ConCmd_PartyKick(int client, int args)
{
	if (!Party_ShouldRunCommand(client))
		return Plugin_Handled;
	
	if (!CTFPlayer(client).IsInAParty())
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_RequireMember");
		return Plugin_Handled;
	}
	
	if (!CTFPlayer(client).GetParty().IsLeader(client))
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
	
	if ((target_count = ProcessTargetString(target, 0, target_list, sizeof(target_list), COMMAND_TARGET_NONE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	Party party = CTFPlayer(client).GetParty();
	
	for (int i = 0; i < target_count; ++i)
	{
		if (target_list[i] == client)
			continue;
		
		if (CTFPlayer(target_list[i]).GetParty() != party)
			continue;
		
		CTFPlayer(target_list[i]).LeaveParty();
		
		CancelClientMenu(target_list[i]);
		
		char name[MAX_NAME_LENGTH];
		party.GetName(name, sizeof(name));
		CPrintToChat(target_list[i], "%s %t", PLUGIN_TAG, "Party_Kicked", name);
		ClientCommand(target_list[i], "play %s", SOUND_PARTY_UPDATE);
		
		// notify all other members
		int[] members = new int[MaxClients];
		int count = party.CollectMembers(members, MaxClients);
		for (int j = 0; j < count; j++)
		{
			int member = members[j];
			CPrintToChat(member, "%s %t", PLUGIN_TAG, "Party_KickedOther", target_list[i]);
			ClientCommand(member, "play %s", SOUND_PARTY_UPDATE);
		}
	}
	
	return Plugin_Handled;
}

static Action ConCmd_PartyName(int client, int args)
{
	if (!Party_ShouldRunCommand(client))
		return Plugin_Handled;
	
	if (!CTFPlayer(client).IsInAParty())
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_RequireMember");
		return Plugin_Handled;
	}
	
	Party party = CTFPlayer(client).GetParty();
	
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
	GetCmdArgString(name, sizeof(name));
	
	// truncate the name if it's too long
	if (strlen(name) > MAX_PARTY_NAME_LENGTH)
	{
		name[MAX_PARTY_NAME_LENGTH - 1] = EOS;
	}
	
	party.SetName(name);
	
	CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Party_Renamed", name);
	return Plugin_Handled;
}
