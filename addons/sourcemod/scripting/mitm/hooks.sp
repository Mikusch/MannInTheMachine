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

void Hooks_Init()
{
	HookUserMessage(GetUserMessageId("SayText2"), OnSayText2, true);
	HookUserMessage(GetUserMessageId("TextMsg"), OnTextMsg, true);
	
	HookEntityOutput("tf_gamerules", "OnStateEnterBetweenRounds", EntityOutput_OnStateEnterBetweenRounds);
}

static Action OnSayText2(UserMsg msg_id, BfRead msg, const int[] players, int clientsNum, bool reliable, bool init)
{
	if (!mitm_rename_robots.BoolValue)
		return Plugin_Continue;
	
	int client = msg.ReadByte();
	bool bWantsToChat = view_as<bool>(msg.ReadByte());
	
	if (!bWantsToChat && Player(client).IsInvader())
	{
		char szBuf[MAX_MESSAGE_LENGTH];
		msg.ReadString(szBuf, sizeof(szBuf));
		
		if (StrEqual(szBuf, "#TF_Name_Change"))
		{
			// Prevent rename message spam in chat
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

static Action OnTextMsg(UserMsg msg_id, BfRead msg, const int[] players, int clientsNum, bool reliable, bool init)
{
	int msg_dest = msg.ReadByte();
	
	if (g_bPrintEndlessBotUpgrades)
	{
		// Need to wait a frame to be able to send another UserMsg
		RequestFrame(RequestFrameCallback_PrintEndlessBotUpgrades, msg_dest);
		
		// Prevent the game from printing its own text
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

static void RequestFrameCallback_PrintEndlessBotUpgrades(int msg_dest)
{
	if (g_pPopulationManager.IsValid())
	{
		// Reserve enough space, including null terminator and extra char to detect overflow
		char szMessage[TEXTMSG_MAX_MESSAGE_LENGTH + 2];
		
		if (g_pPopulationManager.m_EndlessActiveBotUpgrades.Count() >= 1)
		{
			if (msg_dest == HUD_PRINTCONSOLE)
			{
				UTIL_ClientPrintAll(msg_dest, "*** Bot Upgrades");
			}
			else if (msg_dest == HUD_PRINTCENTER)
			{
				strcopy(szMessage, sizeof(szMessage), "*** Bot Upgrades\n");
			}
		}
		
		for (int i = 0; i < g_pPopulationManager.m_EndlessActiveBotUpgrades.Count(); ++i)
		{
			CMvMBotUpgrade upgrade = g_pPopulationManager.m_EndlessActiveBotUpgrades.Get(i, GetOffset(NULL_STRING, "sizeof(CMvMBotUpgrade)"));
			
			if (upgrade.bIsBotAttr == true)
			{
				char szAttrib[MAX_ATTRIBUTE_DESCRIPTION_LENGTH];
				PtrToString(upgrade.szAttrib, szAttrib, sizeof(szAttrib));
				
				if (msg_dest == HUD_PRINTCONSOLE)
				{
					UTIL_ClientPrintAll(msg_dest, szAttrib);
				}
				else if (msg_dest == HUD_PRINTCENTER)
				{
					Format(szMessage, sizeof(szMessage), "%s- %s\n", szMessage, szAttrib);
				}
			}
			else if (upgrade.bIsSkillAttr == true)
			{
				char szAttrib[MAX_ATTRIBUTE_DESCRIPTION_LENGTH];
				PtrToString(upgrade.szAttrib, szAttrib, sizeof(szAttrib));
				
				if (msg_dest == HUD_PRINTCONSOLE)
				{
					UTIL_ClientPrintAll(msg_dest, szAttrib);
				}
				else if (msg_dest == HUD_PRINTCENTER)
				{
					Format(szMessage, sizeof(szMessage), "%s- %s\n", szMessage, szAttrib);
				}
			}
			else
			{
				Address pDef = TF2Econ_GetAttributeDefinitionAddress(upgrade.iAttribIndex);
				if (pDef)
				{
					char szDescription[TEXTMSG_MAX_MESSAGE_LENGTH];
					PtrToString(Deref(pDef + GetOffset("CEconItemAttributeDefinition", "m_pszDescriptionString")), szDescription, sizeof(szDescription));
					
					// If there's a localized description, use that, else use the internal attribute name
					if (szDescription[0] && msg_dest == HUD_PRINTCONSOLE)
					{
						int iFormat = Deref(pDef + GetOffset("CEconItemAttributeDefinition", "m_iDescriptionFormat"));
						float flValue = TranslateAttributeValue(iFormat, upgrade.flValue);
						
						char szValue[16];
						IntToString(RoundToFloor(flValue), szValue, sizeof(szValue));
						
						UTIL_ClientPrintAll(msg_dest, szDescription, szValue);
					}
					else if (TF2Econ_GetAttributeName(upgrade.iAttribIndex, szDescription, sizeof(szDescription)))
					{
						Format(szDescription, sizeof(szDescription), "%s [%.2f]", szDescription, upgrade.flValue);
						
						if (msg_dest == HUD_PRINTCONSOLE)
						{
							UTIL_ClientPrintAll(msg_dest, szDescription);
						}
						else if (msg_dest == HUD_PRINTCENTER)
						{
							Format(szMessage, sizeof(szMessage), "%s- %s\n", szMessage, szDescription);
						}
					}
				}
			}
		}
		
		if (msg_dest == HUD_PRINTCENTER)
		{
			// If the text is too long for a single TextMsg, shorten it
			if (strlen(szMessage) > TEXTMSG_MAX_MESSAGE_LENGTH)
			{
				char buffers[16][128], szExtra[16];
				int numStrings = ExplodeString(szMessage, "\n", buffers, sizeof(buffers), sizeof(buffers[]));
				
				// Find out how many parts we can keep
				int i, length = 0;
				for (i = 0; i < numStrings; ++i)
				{
					length += strlen(buffers[i]) + strlen("\n");
					
					if (length + sizeof(szExtra) >= TEXTMSG_MAX_MESSAGE_LENGTH)
						break;
				}
				
				szMessage[0] = EOS;
				
				// Stitch the pieces back together until we reach the byte limit
				for (int j = 0; j < i; j++)
				{
					Format(szMessage, sizeof(szMessage), "%s%s\n", szMessage, buffers[j]);
				}
				
				// Tell players how many are missing from the list
				Format(szExtra, sizeof(szExtra), "%T", "Endless_MoreAttributes", LANG_SERVER, g_pPopulationManager.m_EndlessActiveBotUpgrades.Count() - (i - 1));
				Format(szMessage, sizeof(szMessage), "%s%s", szMessage, szExtra);
			}
			
			UTIL_ClientPrintAll(msg_dest, szMessage);
		}
	}
}

static void EntityOutput_OnStateEnterBetweenRounds(const char[] output, int caller, int activator, float delay)
{
	if (!g_bInWaitingForPlayers && mitm_setup_time.IntValue > 0)
	{
		CreateTimer(0.1, Timer_StartReadyTimer);
	}
}

static void Timer_StartReadyTimer(Handle timer)
{
	// Automatically start the ready timer
	GameRules_SetPropFloat("m_flRestartRoundTime", GetGameTime() + mitm_setup_time.FloatValue);
	GameRules_SetProp("m_bAwaitingReadyRestart", false);
	
	Event event = CreateEvent("teamplay_round_restart_seconds");
	if (event)
	{
		event.SetInt("seconds", mitm_setup_time.IntValue);
		event.Fire();
	}
}
