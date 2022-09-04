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
	RegConsoleCmd("mitm", ConCmd_OpenMainMenu, "Opens the main menu.");
	RegConsoleCmd("queue", ConCmd_OpenQueueMenu, "Opens the queue menu.");
	RegConsoleCmd("preferences", ConCmd_OpenPreferencesMenu, "Opens the preferences menu.");
	
	RegAdminCmd("sm_addqueue", ConCmd_AddQueuePoints, ADMFLAG_CHEATS, "Adds defender queue points to a player.");
	
	AddCommandListener(CommandListener_Suicide, "explode");
	AddCommandListener(CommandListener_Suicide, "kill");
	AddCommandListener(CommandListener_Build, "build");
	AddCommandListener(CommandListener_DropItem, "dropitem");
}

static Action ConCmd_OpenMainMenu(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	Menus_DisplayMainMenu(client);
	return Plugin_Handled;
}

static Action ConCmd_OpenQueueMenu(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	Menus_DisplayQueueMenu(client);
	return Plugin_Handled;
}

static Action ConCmd_OpenPreferencesMenu(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	Menus_DisplayPreferencesMenu(client);
	return Plugin_Handled;
}

static Action ConCmd_AddQueuePoints(int client, int args)
{
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
	
	if ((target_count = ProcessTargetString(target, client, target_list, MaxClients + 1, COMMAND_TARGET_NONE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		Queue_AddPoints(target_list[i], amount);
	}
	
	if (tn_is_ml)
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Queue_AddedPoints", amount, target_name);
	}
	else
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Queue_AddedPoints", amount, "_s", target_name);
	}
	
	return Plugin_Handled;
}

static Action CommandListener_Suicide(int client, const char[] command, int argc)
{
	if (TF2_GetClientTeam(client) == TFTeam_Invaders && !mitm_invader_allow_suicide.BoolValue)
	{
		// invaders may not suicide
		PrintCenterText(client, "%t", "Invader_NotAllowedToSuicide");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

static Action CommandListener_Build(int client, const char[] command, int argc)
{
	if (TF2_GetClientTeam(client) == TFTeam_Invaders)
	{
		TFObjectType type = view_as<TFObjectType>(GetCmdArgInt(1));
		TFObjectMode mode = view_as<TFObjectMode>(GetCmdArgInt(2));
		
		switch (type)
		{
			// Dispenser: Never allow for Engineer Bots
			case TFObject_Dispenser:
			{
				PrintCenterText(client, "%t", "Engineer_NotAllowedToBuild");
				return Plugin_Handled;
			}
			// Teleporter: Never allow entrances, and only allow exits if we have a teleporter hint
			case TFObject_Teleporter:
			{
				if (mode == TFObjectMode_Entrance)
				{
					PrintCenterText(client, "%t", "Engineer_NotAllowedToBuild");
					return Plugin_Handled;
				}
				
				if (FindTeleporterHintForPlayer(client) == -1)
				{
					PrintCenterText(client, "%t", "Engineer_NotAllowedToBuild_NoHint");
					return Plugin_Handled;
				}
			}
			// Sentry Gun: Only allow if we have a sentry hint
			case TFObject_Sentry:
			{
				if (FindSentryHintForPlayer(client) == -1)
				{
					PrintCenterText(client, "%t", "Engineer_NotAllowedToBuild_NoHint");
					return Plugin_Handled;
				}
			}
			// Sapper: Actually a teleporter exit for Engineers, so treat it that way
			case TFObject_Sapper:
			{
				if (TF2_GetPlayerClass(client) == TFClass_Engineer && FindTeleporterHintForPlayer(client) == -1)
				{
					PrintCenterText(client, "%t", "Engineer_NotAllowedToBuild_NoHint");
					return Plugin_Handled;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

static Action CommandListener_DropItem(int client, const char[] command, int argc)
{
	if (Player(client).GetDeployingBombState() != TF_BOMB_DEPLOYING_NONE)
	{
		// do not allow dropping the bomb while deploying
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
