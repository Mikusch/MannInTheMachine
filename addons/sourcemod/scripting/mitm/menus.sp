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

void Menus_DisplayMainMenu(int client)
{
	Menu menu = new Menu(MenuHandler_MainMenu, MenuAction_Select | MenuAction_End | MenuAction_DrawItem | MenuAction_DisplayItem);
	
	menu.SetTitle("%T", "Menu_Main_Title", client);
	
	menu.AddItem("queue", "Menu_Main_Queue");
	menu.AddItem("prefs", "Menu_Main_Preferences");
	menu.AddItem("party", "Menu_Main_Party");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

static int MenuHandler_MainMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[64];
			menu.GetItem(param2, info, sizeof(info));
			
			if (StrEqual(info, "queue"))
			{
				FakeClientCommand(param1, "sm_queue");
			}
			else if (StrEqual(info, "prefs"))
			{
				FakeClientCommand(param1, "sm_preferences");
			}
			else if (StrEqual(info, "party"))
			{
				FakeClientCommand(param1, "sm_party");
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
			
			if (!TranslationPhraseExists(display))
				return 0;
			
			Format(display, sizeof(display), "%T", display, param1);
			return RedrawMenuItem(display);
		}
	}
	
	return 0;
}

void Menus_DisplayQueueMenu(int client)
{
	ArrayList queueList = Queue_GetDefenderQueue();
	if (queueList.Length > 0)
	{
		Menu menu = new Menu(MenuHandler_QueueMenu, MenuAction_Cancel | MenuAction_End);
		menu.ExitBackButton = true;
		
		if (Player(client).m_defenderQueuePoints != -1)
			menu.SetTitle("%T\n%T", "Menu_Queue_Title", client, "Menu_Queue_Title_QueuePoints", client, Player(client).m_defenderQueuePoints);
		else
			menu.SetTitle("%T\n%T", "Menu_Queue_Title", client, "Menu_Queue_NotLoaded", client);
		
		for (int i = 0; i < queueList.Length; i++)
		{
			int points = queueList.Get(i, QueueData::m_points);
			int other = queueList.Get(i, QueueData::m_client);
			Party party = queueList.Get(i, QueueData::m_party);
			
			char display[64];
			
			if (party == NULL_PARTY)
			{
				Format(display, sizeof(display), "%N (%d)", other, points);
				
				menu.AddItem(NULL_STRING, display, client == other ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
			}
			else
			{
				char name[MAX_NAME_LENGTH];
				party.GetName(name, sizeof(name));
				
				if (Player(client).IsInAParty() && Player(client).GetParty() == party)
				{
					strcopy(display, sizeof(display), party.IsLeader(client) ? "★" : "☆");
				}
				else
				{
					strcopy(display, sizeof(display), "•");
				}
				
				Format(display, sizeof(display), "%s %s (%d)", name, points);
				
				menu.AddItem(NULL_STRING, display, Player(client).IsInAParty() && Player(client).GetParty() == party ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
			}
		}
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		PrintHintText(client, "%t", "Menu_Queue_NotLoaded");
		FakeClientCommand(client, "sm_mitm");
	}
	delete queueList;
}

static int MenuHandler_QueueMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
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
	if (Player(client).m_preferences != -1)
	{
		Menu menu = new Menu(MenuHandler_PreferencesMenu, MenuAction_Select | MenuAction_Cancel | MenuAction_End | MenuAction_DisplayItem);
		menu.SetTitle("%T", "Menu_Preferences_Title", client);
		menu.ExitBackButton = true;
		
		for (int i = 0; i < sizeof(g_PreferenceNames); i++)
		{
			char info[4];
			if (IntToString(i, info, sizeof(info)) > 0)
				menu.AddItem(info, g_PreferenceNames[i]);
		}
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		PrintHintText(client, "%t", "Menu_Preferences_NotLoaded");
		FakeClientCommand(client, "sm_mitm");
	}
}

static int MenuHandler_PreferencesMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[4];
			menu.GetItem(param2, info, sizeof(info));
			
			int i = StringToInt(info);
			PreferenceType preference = view_as<PreferenceType>(RoundToNearest(Pow(2.0, float(i))));
			
			Player(param1).SetPreference(preference, !Player(param1).HasPreference(preference));
			
			char name[64];
			Format(name, sizeof(name), "%T", g_PreferenceNames[i], param1);
			
			if (Player(param1).HasPreference(preference))
				CPrintToChat(param1, "%s %t", PLUGIN_TAG, "Preferences_Enabled", name);
			else
				CPrintToChat(param1, "%s %t", PLUGIN_TAG, "Preferences_Disabled", name);
			
			FakeClientCommand(param1, "sm_preferences");
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				FakeClientCommand(param1, "sm_mitm");
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_DisplayItem:
		{
			char info[4], display[64];
			menu.GetItem(param2, info, sizeof(info), _, display, sizeof(display));
			
			int i = StringToInt(info);
			PreferenceType preference = view_as<PreferenceType>(RoundToNearest(Pow(2.0, float(i))));
			
			if (Player(param1).HasPreference(preference))
				Format(display, sizeof(display), "☑ %T", g_PreferenceNames[i], param1);
			else
				Format(display, sizeof(display), "☐ %T", g_PreferenceNames[i], param1);
			
			return RedrawMenuItem(display);
		}
	}
	
	return 0;
}

void Menus_DisplayPartyMenu(int client)
{
	Menu menu = new Menu(MenuHandler_PartyMenu, MenuAction_Select | MenuAction_Cancel | MenuAction_End | MenuAction_DisplayItem);
	
	// show title
	char title[256];
	Format(title, sizeof(title), "%T\n", "Party_Menu_Title", client);
	
	if (Player(client).IsInAParty())
	{
		Party party = Player(client).GetParty();
		
		// show party name
		char name[MAX_NAME_LENGTH];
		party.GetName(name, sizeof(name));
		Format(title, sizeof(title), "%s%T\n", title, "Party_Menu_CurrentParty", client, name);
		
		// show party members
		ArrayList members = new ArrayList();
		party.CollectMembers(members);
		for (int i = 0; i < members.Length; i++)
		{
			int member = members.Get(i);
			if (party.IsLeader(member))
			{
				Format(title, sizeof(title), "%s★ %N\n", title, member);
			}
			else
			{
				Format(title, sizeof(title), "%s☆ %N\n", title, member);
			}
		}
		delete members;
	}
	else
	{
		Format(title, sizeof(title), "%s%T", title, "Party_Menu_NotInAParty", client);
	}
	
	menu.SetTitle(title);
	menu.ExitBackButton = true;
	
	if (Player(client).IsInAParty())
	{
		// party leader options come first
		if (Player(client).GetParty().IsLeader(client))
		{
			menu.AddItem("manage_party", "Party_Menu_ManageParty");
		}
	}
	else
	{
		menu.AddItem("create_party", "Party_Menu_CreateParty");
	}
	
	if (Player(client).IsInAParty())
	{
		menu.AddItem("leave_party", "Party_Menu_LeaveParty");
	}
	
	menu.AddItem("view_invites", "Party_Menu_ViewPartyInvites");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

static int MenuHandler_PartyMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[64];
			menu.GetItem(param2, info, sizeof(info));
			
			if (StrEqual(info, "create_party"))
			{
				FakeClientCommand(param1, "sm_party_create");
				FakeClientCommand(param1, "sm_party");
			}
			else if (StrEqual(info, "leave_party"))
			{
				FakeClientCommand(param1, "sm_party_leave")
				FakeClientCommand(param1, "sm_party");
			}
			else if (StrEqual(info, "manage_party"))
			{
				FakeClientCommand(param1, "sm_party_manage");
			}
			else if (StrEqual(info, "view_invites"))
			{
				FakeClientCommand(param1, "sm_party_join");
			}
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				FakeClientCommand(param1, "sm_mitm");
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
			
			if (!TranslationPhraseExists(display))
				return 0;
			
			Format(display, sizeof(display), "%T", display, param1);
			return RedrawMenuItem(display);
		}
	}
	
	return 0;
}

void Menus_DisplayPartyManageMenu(int client)
{
	Menu menu = new Menu(MenuHandler_PartyManageMenu, MenuAction_Select | MenuAction_Cancel | MenuAction_End | MenuAction_DisplayItem);
	menu.SetTitle("%T", "Party_ManageMenu_Title", client);
	menu.ExitBackButton = true;
	
	menu.AddItem("invite_members", "Party_ManageMenu_InviteMembers");
	menu.AddItem("kick_members", "Party_ManageMenu_KickMembers")
	
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
				FakeClientCommand(param1, "sm_party_invite");
			}
			else if (StrEqual(info, "kick_members"))
			{
				FakeClientCommand(param1, "sm_party_kick");
			}
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				FakeClientCommand(param1, "sm_party");
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
			
			if (!TranslationPhraseExists(display))
				return 0;
			
			Format(display, sizeof(display), "%T", display, param1);
			return RedrawMenuItem(display);
		}
	}
	
	return 0;
}

void Menus_DisplayPartyManageInviteMenu(int client)
{
	Menu menu = new Menu(MenuHandler_PartyManageInviteMenu, MenuAction_Select | MenuAction_Cancel | MenuAction_End | MenuAction_DisplayItem);
	menu.SetTitle("%T", "Party_ManageInviteMenu_Title", client);
	menu.ExitBackButton = true;
	
	for (int other = 1; other <= MaxClients; other++)
	{
		if (!IsClientInGame(other))
			continue;
		
		if (other == client)
			continue;
		
		Party party = Player(client).GetParty();
		
		char userid[32]
		IntToString(GetClientUserId(other), userid, sizeof(userid));
		
		char name[MAX_NAME_LENGTH];
		GetClientName(other, name, sizeof(name));
		
		char display[64];
		
		if (Player(other).IsInAParty())
		{
			// show party members (including others)
			if (Player(other).GetParty() == party)
			{
				Format(display, sizeof(display), "☆ %N", other);
			}
			else
			{
				Format(display, sizeof(display), "• %N", other);
			}
			
			menu.AddItem(userid, display, ITEMDRAW_DISABLED);
		}
		else if (party.IsInvited(other))
		{
			// show already invited
			Format(display, sizeof(display), "%N %T", other, "Party_ManageInviteMenu_AlreadyInvited", other);
			menu.AddItem(userid, display, ITEMDRAW_DISABLED);
		}
		else
		{
			// show everyone else
			menu.AddItem(userid, name);
		}
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
			
			FakeClientCommand(param1, "sm_party_invite");
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				FakeClientCommand(param1, "sm_party_manage");
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
			
			if (!TranslationPhraseExists(display))
				return 0;
			
			Format(display, sizeof(display), "%T", display, param1);
			return RedrawMenuItem(display);
		}
	}
	
	return 0;
}

void Menus_DisplayPartyManageKickMenu(int client)
{
	Party party = Player(client).GetParty();
	
	Menu menu = new Menu(MenuHandler_PartyKickMenu, MenuAction_Select | MenuAction_Cancel | MenuAction_End | MenuAction_DisplayItem);
	menu.SetTitle("%T", "Party_KickMenu_Title", client);
	menu.ExitBackButton = true;
	
	ArrayList memberList = new ArrayList();
	party.CollectMembers(memberList);
	
	for (int i = 0; i < memberList.Length; i++)
	{
		int member = memberList.Get(i);
		
		if (member == client)
			continue;
		
		char userid[16];
		IntToString(GetClientUserId(member), userid, sizeof(userid));
		
		char name[MAX_NAME_LENGTH];
		GetClientName(member, name, sizeof(name));
		
		menu.AddItem(userid, name);
	}
	delete memberList;
	
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
			
			FakeClientCommand(param1, "sm_party_kick");
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				FakeClientCommand(param1, "sm_party_manage");
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
			
			if (!TranslationPhraseExists(display))
				return 0;
			
			Format(display, sizeof(display), "%T", display, param1);
			return RedrawMenuItem(display);
		}
	}
	
	return 0;
}

void Menus_DisplayPartyInviteMenu(int client)
{
	Menu menu = new Menu(MenuHandler_PartyInviteMenu, MenuAction_Select | MenuAction_Cancel | MenuAction_End | MenuAction_DisplayItem);
	menu.SetTitle("%T", "Party_InviteMenu_Title", client);
	menu.ExitBackButton = true;
	
	ArrayList parties = Party_GetAllActiveParties();
	for (int i = 0; i < parties.Length; i++)
	{
		PartyInfo info;
		if (!parties.GetArray(i, info))
			continue;
		
		Party party = Party(info.m_id);
		if (party == Party(0))
			continue;
		
		if (!party.IsInvited(client))
			continue;
		
		char id[32];
		IntToString(info.m_id, id, sizeof(id));
		
		char display[64], name[MAX_NAME_LENGTH];
		party.GetName(name, sizeof(name));
		Format(display, sizeof(display), "%s (★ %N)", name, party.GetLeader());
		
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
			FakeClientCommand(param1, "sm_party");
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				FakeClientCommand(param1, "sm_party");
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
			
			if (!TranslationPhraseExists(display))
				return 0;
			
			Format(display, sizeof(display), "%T", display, param1);
			return RedrawMenuItem(display);
		}
	}
	
	return 0;
}
