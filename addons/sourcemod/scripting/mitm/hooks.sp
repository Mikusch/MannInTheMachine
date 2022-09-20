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
	AddNormalSoundHook(OnNormalSoundPlayed);
	
	HookUserMessage(GetUserMessageId("SayText2"), OnSayText2, true);
	HookUserMessage(GetUserMessageId("TextMsg"), OnTextMsg, true);
}

static Action OnNormalSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (StrEqual(sample, ")weapons/teleporter_ready.wav"))
	{
		if (IsBaseObject(entity) && ((TF2_GetObjectType(entity) == TFObject_Teleporter && TF2_GetObjectMode(entity) == TFObjectMode_Exit) || TF2_GetObjectType(entity) == TFObject_Sapper))
		{
			if (view_as<TFTeam>(GetEntProp(entity, Prop_Data, "m_iTeamNum")) == TFTeam_Invaders)
			{
				// Alert defenders that a robot teleporter is now active
				EmitSoundToAll(")mvm/mvm_tele_activate.wav", entity, SNDCHAN_STATIC, 150);
			}
		}
	}
	
	return Plugin_Continue;
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
		if (msg_dest == HUD_PRINTCONSOLE)
		{
			// Need to wait a frame to be able to send another UserMsg
			RequestFrame(RequestFrameCallback_PrintEndlessBotUpgrades);
		}
		
		// Prevent the game from printing its own text
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

static void RequestFrameCallback_PrintEndlessBotUpgrades()
{
	CPopulationManager populator = GetPopulationManager();
	
	if (populator.m_EndlessActiveBotUpgrades.Count() >= 1)
	{
		PrintCenterTextAll("%t", "Endless_BotUpgradesChanged");
		UTIL_ClientPrintAll(HUD_PRINTCONSOLE, "*** Bot Upgrades");
	}
	
	for (int i = 0; i < populator.m_EndlessActiveBotUpgrades.Count(); ++i)
	{
		CMvMBotUpgrade upgrade = populator.m_EndlessActiveBotUpgrades.Get(i, GetOffset("sizeof(CMvMBotUpgrade)"));
		
		if (upgrade.bIsBotAttr == true)
		{
			char szAttrib[MAX_ATTRIBUTE_DESCRIPTION_LENGTH];
			PtrToString(upgrade.szAttrib, szAttrib, sizeof(szAttrib));
			UTIL_ClientPrintAll(HUD_PRINTCONSOLE, szAttrib);
		}
		else if (upgrade.bIsSkillAttr == true)
		{
			char szAttrib[MAX_ATTRIBUTE_DESCRIPTION_LENGTH];
			PtrToString(upgrade.szAttrib, szAttrib, sizeof(szAttrib));
			UTIL_ClientPrintAll(HUD_PRINTCONSOLE, szAttrib);
		}
		else
		{
			Address pDef = TF2Econ_GetAttributeDefinitionAddress(upgrade.iAttribIndex);
			if (pDef)
			{
				char szDescription[255];
				PtrToString(Deref(pDef + GetOffset("CEconItemAttributeDefinition::m_pszDescriptionString")), szDescription, sizeof(szDescription));
				
				// If there's a localized description, use that, else use the internal attribute name
				if (szDescription[0])
				{
					int iFormat = Deref(pDef + GetOffset("CEconItemAttributeDefinition::m_iDescriptionFormat"));
					float flValue = TranslateAttributeValue(iFormat, upgrade.flValue);
					
					char szValue[16];
					IntToString(RoundToFloor(flValue), szValue, sizeof(szValue));
					UTIL_ClientPrintAll(HUD_PRINTCONSOLE, szDescription, szValue);
				}
				else if (TF2Econ_GetAttributeName(upgrade.iAttribIndex, szDescription, sizeof(szDescription)))
				{
					Format(szDescription, sizeof(szDescription), "%s [%.2f]", szDescription, upgrade.flValue);
					UTIL_ClientPrintAll(HUD_PRINTCONSOLE, szDescription);
				}
			}
		}
	}
	
	UTIL_ClientPrintAll(HUD_PRINTCONSOLE, " ");
}
