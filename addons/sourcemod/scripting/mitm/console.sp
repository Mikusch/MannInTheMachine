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

void Console_Init()
{
	RegConsoleCmd("sm_mitm", ConCmd_MannInTheMachine, "Opens the main menu.");
	RegConsoleCmd("sm_queue", ConCmd_Queue, "Opens the queue menu.");
	RegConsoleCmd("sm_preferences", ConCmd_Settings, "Opens the preferences menu.");
	RegConsoleCmd("sm_party", ConCmd_Party, "Opens the party menu.");
	RegConsoleCmd("sm_contributors", ConCmd_Contributors, "Opens the contributor menu.");
	RegConsoleCmd("sm_afk", ConCmd_ToggleSpectatorMode, "Toggles spectator mode.");
	
	RegAdminCmd("sm_addqueue", ConCmd_AddQueuePoints, ADMFLAG_CHEATS, "Adds defender queue points to a player.");
	
	PSM_AddCommandListener(CommandListener_Suicide, "explode");
	PSM_AddCommandListener(CommandListener_Suicide, "kill");
	PSM_AddCommandListener(CommandListener_DropItem, "dropitem");
	PSM_AddCommandListener(CommandListener_AutoTeam, "autoteam");
	PSM_AddCommandListener(CommandListener_JoinTeam, "jointeam");
	PSM_AddCommandListener(CommandListener_JoinClass, "joinclass");
	PSM_AddCommandListener(CommandListener_Buyback, "td_buyback");
	
	PSM_AddMultiTargetFilter("@defenders", MultiTargetFilter_Defenders, "Target_Defenders", true);
	PSM_AddMultiTargetFilter("@invaders", MultiTargetFilter_Invaders, "Target_Invaders", true);
}

static Action ConCmd_MannInTheMachine(int client, int args)
{
	if (!PSM_IsEnabled())
		return Plugin_Continue;
	
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	Menus_DisplayMainMenu(client);
	return Plugin_Handled;
}

static Action ConCmd_Queue(int client, int args)
{
	if (!PSM_IsEnabled())
		return Plugin_Continue;
	
	if (!Queue_IsEnabled())
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Queue_FeatureDisabled");
		return Plugin_Continue;
	}
	
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	Menus_DisplayQueueMenu(client);
	return Plugin_Handled;
}

static Action ConCmd_Settings(int client, int args)
{
	if (!PSM_IsEnabled())
		return Plugin_Continue;
	
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	Menus_DisplayPreferencesMenu(client);
	return Plugin_Handled;
}

static Action ConCmd_Party(int client, int args)
{
	if (!PSM_IsEnabled())
		return Plugin_Continue;
	
	if (!Party_ShouldRunCommand(client))
		return Plugin_Handled;
	
	Menus_DisplayPartyMenu(client);
	return Plugin_Handled;
}

static Action ConCmd_Contributors(int client, int args)
{
	if (!PSM_IsEnabled())
		return Plugin_Continue;
	
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	Menus_DisplayContributorsMenu(client);
	return Plugin_Handled;
}

static Action ConCmd_ToggleSpectatorMode(int client, int args)
{
	if (!PSM_IsEnabled())
		return Plugin_Continue;
	
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	bool enabled = CTFPlayer(client).TogglePreference(PREF_SPECTATOR_MODE);
	CPrintToChat(client, "%s %t", PLUGIN_TAG, enabled ? "SpectatorMode_Enabled" : "SpectatorMode_Disabled");
	
	return Plugin_Handled;
}

static Action ConCmd_AddQueuePoints(int client, int args)
{
	if (!PSM_IsEnabled())
		return Plugin_Continue;
	
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addqueue <#userid|name> <amount>");
		return Plugin_Handled;
	}
	
	char target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	int amount = GetCmdArgInt(2);
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(target, client, target_list, sizeof(target_list), COMMAND_TARGET_NONE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		CTFPlayer(target_list[i]).AddQueuePoints(amount);
	}
	
	if (tn_is_ml)
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Queue_PointsAdded", amount, target_name);
	}
	else
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Queue_PointsAdded", amount, "_s", target_name);
	}
	
	return Plugin_Handled;
}

static Action CommandListener_Suicide(int client, const char[] command, int argc)
{
	if (TF2_GetClientTeam(client) == TFTeam_Invaders && !mitm_bot_allow_suicide.BoolValue && !developer.BoolValue)
	{
		// Allow suicide during round transitions (game over, pregame)
		RoundState roundState = GameRules_GetRoundState();
		if (roundState == RoundState_GameOver || roundState == RoundState_Pregame)
		{
			return Plugin_Continue;
		}
		
		// invaders may not suicide
		PrintCenterText(client, "%t", "Invader_NotAllowedToSuicide");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

static Action CommandListener_AutoTeam(int client, const char[] command, int argc)
{
	if (TF2_GetClientTeam(client) == TFTeam_Invaders)
	{
		// autoteam does NOT call GetTeamAssignmentOverride! just axe it entirely.
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

static Action CommandListener_DropItem(int client, const char[] command, int argc)
{
	if (CTFPlayer(client).GetDeployingBombState() != TF_BOMB_DEPLOYING_NONE)
	{
		// do not allow dropping the bomb while deploying
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

static Action CommandListener_JoinTeam(int client, const char[] command, int argc)
{
	if (argc >= 1)
	{
		char arg[16];
		GetCmdArg(1, arg, sizeof(arg));
		
		if (StrEqual(arg, "spectate", false) || StrEqual(arg, "auto", false))
			return Plugin_Continue;
		
		// never allow joining invader team directly
		if (StrEqual(arg, "blue", false))
			return Plugin_Handled;
		
		// allow CTFPlayer::GetAutoTeam to set currency for new defenders
		FakeClientCommand(client, "%s %s", command, "auto");
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

static Action CommandListener_JoinClass(int client, const char[] command, int argc)
{
	if (TF2_GetClientTeam(client) == TFTeam_Invaders && IsPlayerAlive(client))
	{
		// some maps have a func_respawnroom in robot spawn and allow class switching
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

static Action CommandListener_Buyback(int client, const char[] command, int argc)
{
	if (TF2_GetClientTeam(client) == TFTeam_Invaders)
	{
		// prevent a rare case where robots can buy back into the game
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

static bool MultiTargetFilter_Defenders(const char[] pattern, ArrayList clients)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && TF2_GetClientTeam(client) == TFTeam_Defenders)
			clients.Push(client);
	}
	
	return clients.Length > 0;
}

static bool MultiTargetFilter_Invaders(const char[] pattern, ArrayList clients)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && CTFPlayer(client).IsInvader())
			clients.Push(client);
	}
	
	return clients.Length > 0;
}
