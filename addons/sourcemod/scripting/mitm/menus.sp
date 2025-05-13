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

#define MENU_INFO_QUEUE			"queue"
#define MENU_INFO_PREFERENCES	"preferences"
#define MENU_INFO_PARTY			"party"
#define MENU_INFO_CONTRIBUTORS	"contributors"

#define STEAM_PROFILE_URL	"https://steamcommunity.com/profiles/%s"

static ArrayList g_contributors;

enum struct ContributorInfo
{
	char name[MAX_NAME_LENGTH];
	char steam_id[64];
}

void Menus_Init()
{
	g_contributors = new ArrayList(sizeof(ContributorInfo));
	
	ContributorInfo info;
	
	info.name = "Mikusch";
	info.steam_id = "76561198071478507";
	g_contributors.PushArray(info);
	
	info.name = "Kenzzer";
	info.steam_id = "76561198059675572";
	g_contributors.PushArray(info);
	
	info.name = "trigger_hurt";
	info.steam_id = "76561198036209556";
	g_contributors.PushArray(info);
}

void Menus_DisplayMainMenu(int client)
{
	Menu menu = new Menu(MenuHandler_MainMenu, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
	
	menu.SetTitle("%T\n%T", "Menu_Header", client, "Menu_Main_Title", client);
	
	if (Queue_IsEnabled())
		menu.AddItem(MENU_INFO_QUEUE, "Menu_Main_Queue");
	
	menu.AddItem(MENU_INFO_PREFERENCES, "Menu_Main_Preferences");
	
	if (Party_IsEnabled())
		menu.AddItem(MENU_INFO_PARTY, "Menu_Main_Party");
	
	menu.AddItem(MENU_INFO_CONTRIBUTORS, "Menu_Main_Contributors");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

static int MenuHandler_MainMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			
			if (StrEqual(info, MENU_INFO_QUEUE))
			{
				Menus_DisplayQueueMenu(param1);
			}
			else if (StrEqual(info, MENU_INFO_PREFERENCES))
			{
				Menus_DisplayPreferencesMenu(param1);
			}
			else if (StrEqual(info, MENU_INFO_PARTY))
			{
				Menus_DisplayPartyMenu(param1);
			}
			else if (StrEqual(info, MENU_INFO_CONTRIBUTORS))
			{
				Menus_DisplayContributorsMenu(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_DisplayItem:
		{
			return Menus_OnItemDisplayed(menu, param1, param2);
		}
	}
	
	return 0;
}

void Menus_DisplayQueueMenu(int client)
{
	ArrayList queue = Queue_GetDefenderQueue();
	if (queue.Length > 0)
	{
		Menu menu = new Menu(MenuHandler_QueueMenu, MenuAction_Select | MenuAction_Cancel | MenuAction_End);
		menu.ExitBackButton = true;
		
		char title[128];
		Format(title, sizeof(title), "%T\n%T", "Menu_Header", client, "Menu_Queue_Title", client);
		
		int index = queue.FindValue(client, QueueData::m_client);
		if (index != -1)
		{
			// player is in queue
			Format(title, sizeof(title), "%s\n%T", title, "Menu_Queue_Title_QueuePoints", client, queue.Get(index, QueueData::m_points), index + 1);
		}
		else
		{
			if (CTFPlayer(client).IsInAParty())
			{
				index = queue.FindValue(CTFPlayer(client).GetParty(), QueueData::m_party);
				if (index != -1)
				{
					// player is in a party and queuing with others
					Format(title, sizeof(title), "%s\n%T", title, "Menu_Queue_Title_PartyQueuePoints", client, queue.Get(index, QueueData::m_points), index + 1);
				}
				else
				{
					// player is in a party but members aren't eligible to queue
					Format(title, sizeof(title), "%s\n%T", title, "Menu_Queue_Title_NotInQueue", client);
				}
			}
			else
			{
				// player is not in queue and not in a party
				Format(title, sizeof(title), "%s\n%T", title, "Menu_Queue_Title_NotInQueue", client);
			}
		}
		
		menu.SetTitle(title);
		
		for (int i = 0; i < queue.Length; i++)
		{
			int points = queue.Get(i, QueueData::m_points);
			int other = queue.Get(i, QueueData::m_client);
			Party party = queue.Get(i, QueueData::m_party);
			
			char info[32], display[64];
			
			if (party.IsValid())
			{
				char name[MAX_NAME_LENGTH];
				party.GetName(name, sizeof(name));
				
				if (CTFPlayer(client).IsInAParty() && CTFPlayer(client).GetParty() == party)
				{
					strcopy(display, sizeof(display), party.IsLeader(client) ? SYMBOL_PARTY_LEADER : SYMBOL_PARTY_MEMBER);
				}
				else
				{
					strcopy(display, sizeof(display), SYMBOL_PARTY_OTHER);
				}
				
				Format(info, sizeof(info), "party_%d", party.m_id);
				Format(display, sizeof(display), "%s %s (%d)", display, name, points);
				
				menu.AddItem(info, display, ITEMDRAW_DEFAULT);
			}
			else
			{
				Format(info, sizeof(info), "player_%d", other);
				Format(display, sizeof(display), "%N (%d)", other, points);
				
				menu.AddItem(info, display, ITEMDRAW_DISABLED);
			}
		}
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		PrintHintText(client, "%t", "Menu_Queue_NoPlayers");
		Menus_DisplayMainMenu(client);
	}
	delete queue;
}

static int MenuHandler_QueueMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			
			// display party members
			if (!strncmp(info, "party_", 6))
			{
				int id = StringToInt(info[6]);
				
				Party party = Party(id);
				if (party.IsValid())
				{
					char name[MAX_NAME_LENGTH], strMembers[128];
					party.GetName(name, sizeof(name));
					
					int[] members = new int[MaxClients];
					int count = party.CollectMembers(members);
					
					for (int i = 0; i < count; i++)
					{
						char strMember[MAX_MESSAGE_LENGTH];
						
						Format(strMember, sizeof(strMember), "%N (%d)", members[i], CTFPlayer(members[i]).GetQueuePoints());
						
						if (i < count - 1)
							StrCat(strMember, sizeof(strMember), ", ");
						
						StrCat(strMembers, sizeof(strMembers), strMember);
					}
					
					CPrintToChat(param1, "%s {cyan}%s{default}: %s", PLUGIN_TAG, name, strMembers);
				}
				else
				{
					CPrintToChat(param1, "%s %t", PLUGIN_TAG, "Party_DoesNotExist");
				}
				
				Menus_DisplayQueueMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Menus_DisplayMainMenu(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

void Menus_DisplayPreferencesMenu(int client)
{
	Menu menu = new Menu(MenuHandler_PreferencesMenu, MenuAction_Select | MenuAction_Cancel | MenuAction_End | MenuAction_DisplayItem);
	menu.SetTitle("%T\n%T", "Menu_Header", client, "Menu_Preferences_Title", client);
	menu.ExitBackButton = true;
	
	AddPreferenceToMenu(menu, PREF_DEFENDER_DISABLE_QUEUE, "Preference_DisableDefender");
	AddPreferenceToMenu(menu, PREF_SPECTATOR_MODE, "Preference_SpectatorMode");
	AddPreferenceToMenu(menu, PREF_INVADER_DISABLE_MINIBOSS, "Preference_DisableMiniBoss");
	AddPreferenceToMenu(menu, PREF_DISABLE_ANNOTATIONS, "Preference_DisableAnnotations");
	
	if (Party_IsEnabled())
		AddPreferenceToMenu(menu, PREF_IGNORE_PARTY_INVITES, "Preference_IgnorePartyInvites");
	
	AddPreferenceToMenu(menu, PREF_DEFENDER_DISABLE_REPLACEMENT, "Preference_DisableDefenderReplacement");
	AddPreferenceToMenu(menu, PREF_INVADER_DISABLE_CUSTOM_VIEWMODELS, "Preference_DisableCustomViewModels");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

static void AddPreferenceToMenu(Menu menu, MannInTheMachinePreference preference, const char[] display)
{
	char info[32];
	if (IntToString(view_as<int>(preference), info, sizeof(info)))
		menu.AddItem(info, display);
}

static int MenuHandler_PreferencesMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			
			MannInTheMachinePreference preference = view_as<MannInTheMachinePreference>(StringToInt(info));
			
			CTFPlayer(param1).SetPreference(preference, !CTFPlayer(param1).HasPreference(preference));
			
			Menus_DisplayPreferencesMenu(param1);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Menus_DisplayMainMenu(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_DisplayItem:
		{
			char info[32], display[64];
			menu.GetItem(param2, info, sizeof(info), _, display, sizeof(display));
			
			MannInTheMachinePreference preference = view_as<MannInTheMachinePreference>(StringToInt(info));
			
			Format(display, sizeof(display), "%s %T", CTFPlayer(param1).HasPreference(preference) ? "☑" : "☐", display, param1);
			
			return RedrawMenuItem(display);
		}
	}
	
	return 0;
}

void Menus_DisplayPartyMenu(int client)
{
	Menu menu = new Menu(MenuHandler_PartyMenu, MenuAction_Display | MenuAction_Select | MenuAction_Cancel | MenuAction_End | MenuAction_DisplayItem);
	menu.ExitBackButton = true;
	
	// show title
	char title[512];
	Format(title, sizeof(title), "%T\n%T\n", "Menu_Header", client, "Party_Menu_Title", client);
	
	if (CTFPlayer(client).IsInAParty())
	{
		Party party = CTFPlayer(client).GetParty();
		
		// show party name
		char name[MAX_NAME_LENGTH];
		party.GetName(name, sizeof(name));
		Format(title, sizeof(title), "%s%T\n", title, "Party_Menu_CurrentParty", client, name);
		
		// show queue points
		ArrayList queue = Queue_GetDefenderQueue();
		int index = queue.FindValue(party, QueueData::m_party);
		if (index != -1)
		{
			Format(title, sizeof(title), "%s%T", title, "Party_Menu_QueuePoints", client, queue.Get(index, QueueData::m_points), index + 1);
		}
		else
		{
			Format(title, sizeof(title), "%s%T", title, "Party_Menu_NotEnoughMembersForQueue", client);
		}
		delete queue;
		
		StrCat(title, sizeof(title), "\n \n");
		
		// show member count
		Format(title, sizeof(title), "%s%T\n", title, "Party_Menu_Members", client, party.GetMemberCount(), party.GetMaxPlayers());
		
		// show party members
		int[] members = new int[MaxClients];
		int count = party.CollectMembers(members);
		for (int i = 0; i < count; i++)
		{
			int member = members[i];
			Format(title, sizeof(title), "%s%s %N", title, party.IsLeader(member) ? SYMBOL_PARTY_LEADER : SYMBOL_PARTY_MEMBER, member);
			Format(title, sizeof(title), "%s (%d)\n", title, CTFPlayer(member).GetQueuePoints());
		}
	}
	else
	{
		Format(title, sizeof(title), "%s%T", title, "Party_Menu_NotInAParty", client);
	}
	
	// final newline so it looks nicer
	StrCat(title, sizeof(title), " \n");
	
	menu.SetTitle(title);
	
	if (CTFPlayer(client).IsInAParty())
	{
		// party leader options come first
		if (CTFPlayer(client).GetParty().IsLeader(client))
		{
			menu.AddItem("manage_party", "Party_Menu_ManageParty");
		}
	}
	else
	{
		menu.AddItem("create_party", "Party_Menu_CreateParty");
	}
	
	if (CTFPlayer(client).IsInAParty())
	{
		menu.AddItem(NULL_STRING, NULL_STRING, ITEMDRAW_SPACER);
		menu.AddItem("leave_party", "Party_Menu_LeaveParty");
	}
	else
	{
		menu.AddItem("view_invites", "Party_Menu_ViewPartyInvites");
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

static int MenuHandler_PartyMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Display:
		{
			CTFPlayer(param1).SetPartyMenuActive(true);
		}
		case MenuAction_Select:
		{
			CTFPlayer(param1).SetPartyMenuActive(false);
			
			char info[64];
			menu.GetItem(param2, info, sizeof(info));
			
			if (StrEqual(info, "create_party"))
			{
				FakeClientCommand(param1, "sm_party_create");
			}
			else if (StrEqual(info, "leave_party"))
			{
				FakeClientCommand(param1, "sm_party_leave");
				Menus_DisplayPartyMenu(param1);
			}
			else if (StrEqual(info, "manage_party"))
			{
				Menus_DisplayPartyManageMenu(param1);
			}
			else if (StrEqual(info, "view_invites"))
			{
				Menus_DisplayPartyInviteMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			CTFPlayer(param1).SetPartyMenuActive(false);
			
			if (param2 == MenuCancel_ExitBack)
			{
				Menus_DisplayMainMenu(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_DisplayItem:
		{
			return Menus_OnItemDisplayed(menu, param1, param2);
		}
	}
	
	return 0;
}

void Menus_DisplayPartyManageMenu(int client)
{
	Menu menu = new Menu(MenuHandler_PartyManageMenu, MenuAction_Select | MenuAction_Cancel | MenuAction_End | MenuAction_DisplayItem);
	menu.SetTitle("%T\n%T", "Menu_Header", client, "Party_ManageMenu_Title", client);
	menu.ExitBackButton = true;
	
	menu.AddItem("invite_members", "Party_ManageMenu_InviteMembers");
	menu.AddItem("kick_members", "Party_ManageMenu_KickMembers");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

static int MenuHandler_PartyManageMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[64];
			menu.GetItem(param2, info, sizeof(info));
			
			if (StrEqual(info, "invite_members"))
			{
				Menus_DisplayPartyManageInviteMenu(param1);
			}
			else if (StrEqual(info, "kick_members"))
			{
				Menus_DisplayPartyManageKickMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Menus_DisplayPartyMenu(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_DisplayItem:
		{
			return Menus_OnItemDisplayed(menu, param1, param2);
		}
	}
	
	return 0;
}

void Menus_DisplayPartyManageInviteMenu(int client)
{
	Menu menu = new Menu(MenuHandler_PartyManageInviteMenu, MenuAction_Select | MenuAction_Cancel | MenuAction_End | MenuAction_DisplayItem);
	menu.SetTitle("%T\n%T", "Menu_Header", client, "Party_ManageInviteMenu_Title", client);
	menu.ExitBackButton = true;
	
	for (int other = 1; other <= MaxClients; other++)
	{
		if (!IsClientInGame(other))
			continue;
		
		if (other == client)
			continue;
		
		if (CTFPlayer(other).HasPreference(PREF_IGNORE_PARTY_INVITES))
			continue;
		
		if (!Forwards_OnIsValidDefender(other))
			continue;
		
		Party party = CTFPlayer(client).GetParty();
		
		char userid[32];
		IntToString(GetClientUserId(other), userid, sizeof(userid));
		
		char display[64];
		int style = ITEMDRAW_DEFAULT;
		
		if (CTFPlayer(other).IsInAParty())
		{
			// show party members (including others)
			if (CTFPlayer(other).GetParty() == party)
			{
				Format(display, sizeof(display), SYMBOL_PARTY_MEMBER ... " %N", other);
				style = ITEMDRAW_DISABLED;
			}
			else
			{
				Format(display, sizeof(display), SYMBOL_PARTY_OTHER ... " %N", other);
			}
		}
		else
		{
			Format(display, sizeof(display), "%N", other);
		}
		
		if (party.IsInvited(other))
		{
			// show already invited
			Format(display, sizeof(display), "%s %T", display, "Party_ManageInviteMenu_AlreadyInvited", other);
			style = ITEMDRAW_DISABLED;
		}
		
		menu.AddItem(userid, display, style);
	}
	
	if (menu.ItemCount == 0)
	{
		menu.AddItem(NULL_STRING, "Party_ManageInviteMenu_NoPlayers", ITEMDRAW_DISABLED);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

static int MenuHandler_PartyManageInviteMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[32];
			int userid;
			
			menu.GetItem(param2, info, sizeof(info));
			userid = StringToInt(info);
			
			if (GetClientOfUserId(userid) == 0)
			{
				PrintToChat(param1, "[SM] %t", "Player no longer available");
			}
			else
			{
				FakeClientCommand(param1, "sm_party_invite #%d", userid);
			}
			
			Menus_DisplayPartyManageInviteMenu(param1);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Menus_DisplayPartyManageMenu(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_DisplayItem:
		{
			return Menus_OnItemDisplayed(menu, param1, param2);
		}
	}
	
	return 0;
}

void Menus_DisplayPartyManageKickMenu(int client)
{
	Party party = CTFPlayer(client).GetParty();
	
	Menu menu = new Menu(MenuHandler_PartyKickMenu, MenuAction_Select | MenuAction_Cancel | MenuAction_End | MenuAction_DisplayItem);
	menu.SetTitle("%T\n%T", "Menu_Header", client, "Party_KickMenu_Title", client);
	menu.ExitBackButton = true;
	
	int[] members = new int[MaxClients];
	int count = party.CollectMembers(members);
	
	for (int i = 0; i < count; i++)
	{
		int member = members[i];
		
		if (member == client)
			continue;
		
		char userid[16];
		IntToString(GetClientUserId(member), userid, sizeof(userid));
		
		char name[MAX_NAME_LENGTH];
		GetClientName(member, name, sizeof(name));
		
		menu.AddItem(userid, name);
	}
	
	if (menu.ItemCount == 0)
	{
		menu.AddItem(NULL_STRING, "Party_KickMenu_NoMembers", ITEMDRAW_DISABLED);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

static int MenuHandler_PartyKickMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[32];
			int userid;
			
			menu.GetItem(param2, info, sizeof(info));
			userid = StringToInt(info);
			
			if (GetClientOfUserId(userid) == 0)
			{
				PrintToChat(param1, "[SM] %t", "Player no longer available");
			}
			else
			{
				FakeClientCommand(param1, "sm_party_kick #%d", userid);
			}
			
			Menus_DisplayPartyManageKickMenu(param1);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Menus_DisplayPartyManageMenu(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_DisplayItem:
		{
			return Menus_OnItemDisplayed(menu, param1, param2);
		}
	}
	
	return 0;
}

void Menus_DisplayPartyInviteMenu(int client)
{
	Menu menu = new Menu(MenuHandler_PartyInviteMenu, MenuAction_Select | MenuAction_Cancel | MenuAction_End | MenuAction_DisplayItem);
	menu.SetTitle("%T\n%T", "Menu_Header", client, "Party_InviteMenu_Title", client);
	menu.ExitBackButton = true;
	
	ArrayList parties = Party_GetAllActiveParties();
	for (int i = 0; i < parties.Length; i++)
	{
		PartyInfo info;
		if (!parties.GetArray(i, info))
			continue;
		
		Party party = Party(info.m_id);
		
		if (!party.IsInvited(client))
			continue;
		
		char id[32];
		IntToString(info.m_id, id, sizeof(id));
		
		char display[64], name[MAX_NAME_LENGTH];
		party.GetName(name, sizeof(name));
		Format(display, sizeof(display), "%s (" ... SYMBOL_PARTY_LEADER ... " %N)", name, party.GetLeader());
		
		menu.AddItem(id, display);
	}
	delete parties;
	
	if (menu.ItemCount == 0)
	{
		menu.AddItem(NULL_STRING, "Party_InviteMenu_NoPendingInvites", ITEMDRAW_DISABLED);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

static int MenuHandler_PartyInviteMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			
			FakeClientCommand(param1, "sm_party_join %s", info);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Menus_DisplayPartyMenu(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_DisplayItem:
		{
			return Menus_OnItemDisplayed(menu, param1, param2);
		}
	}
	
	return 0;
}

void Menus_DisplayContributorsMenu(int client)
{
	Menu menu = new Menu(MenuHandler_ContributorsMenu, MenuAction_Select | MenuAction_Cancel | MenuAction_End | MenuAction_DisplayItem);
	menu.SetTitle("%T\n%T", "Menu_Header", client, "Menu_Contributors_Title", client);
	menu.ExitBackButton = true;
	
	for (int i = 0; i < g_contributors.Length; i++)
	{
		ContributorInfo info;
		if (g_contributors.GetArray(i, info))
		{
			char phrase[64], display[64];
			Format(phrase, sizeof(phrase), "Menu_Contributors_%s", info.name);
			Format(display, sizeof(display), "%s: %T", info.name, phrase, client);
			
			menu.AddItem(info.name, display);
		}
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

static int MenuHandler_ContributorsMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			
			int index = g_contributors.FindString(info, ContributorInfo::name);
			if (index != -1)
			{
				ContributorInfo contributor;
				if (g_contributors.GetArray(index, contributor))
				{
					char url[192];
					Format(url, sizeof(url), STEAM_PROFILE_URL, contributor.steam_id);
					ShowMOTDPanel(param1, contributor.name, url, MOTDPANEL_TYPE_URL);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Menus_DisplayMainMenu(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_DisplayItem:
		{
			return Menus_OnItemDisplayed(menu, param1, param2);
		}
	}
	
	return 0;
}

static int Menus_OnItemDisplayed(Menu menu, int param1, int param2)
{
	char info[32], display[64];
	menu.GetItem(param2, info, sizeof(info), _, display, sizeof(display));
	
	if (!TranslationPhraseExists(display))
		return 0;
	
	Format(display, sizeof(display), "%T", display, param1);
	return RedrawMenuItem(display);
}
