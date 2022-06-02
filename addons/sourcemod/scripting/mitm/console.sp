/*
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

void Console_Initialize()
{
	RegConsoleCmd("mitm", ConCmd_OpenMainMenu, "Opens the main menu.");
	RegConsoleCmd("queue", ConCmd_OpenQueueMenu, "Opens the queue menu.");
	RegConsoleCmd("preferences", ConCmd_OpenPreferencesMenu, "Opens the preferences menu.");
	
	AddCommandListener(CommandListener_Suicide, "explode");
	AddCommandListener(CommandListener_Suicide, "kill");
	AddCommandListener(CommandListener_Build, "build");
}

public Action ConCmd_OpenMainMenu(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	Menus_DisplayMainMenu(client);
	return Plugin_Handled;
}

public Action ConCmd_OpenQueueMenu(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	Menus_DisplayQueueMenu(client);
	return Plugin_Handled;
}

public Action ConCmd_OpenPreferencesMenu(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	Menus_DisplayPreferencesMenu(client);
	return Plugin_Handled;
}

public Action CommandListener_Suicide(int client, const char[] command, int argc)
{
	if (TF2_GetClientTeam(client) == TFTeam_Invaders)
	{
		// invaders may not suicide
		PrintCenterText(client, "You are not allowed to suicide as a robot.");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action CommandListener_Build(int client, const char[] command, int argc)
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
				
				if (GetNestTeleporterHint(client) == -1)
				{
					PrintCenterText(client, "%t", "Engineer_NotAllowedToBuild_NoHint");
					return Plugin_Handled;
				}
			}
			// Sentry Gun: Only allow if we have a sentry hint
			case TFObject_Sentry:
			{
				if (GetNestSentryHint(client) == -1)
				{
					PrintCenterText(client, "%t", "Engineer_NotAllowedToBuild_NoHint");
					return Plugin_Handled;
				}
			}
		}
	}
	
	return Plugin_Continue;
}
