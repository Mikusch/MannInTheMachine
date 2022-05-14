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
	AddCommandListener(CommandListener_Suicide, "explode");
	AddCommandListener(CommandListener_Suicide, "kill");
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
