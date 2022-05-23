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

static MvMBombDeploy g_bombDeploy[MAXPLAYERS + 1];

void SDKHooks_Initialize()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		g_bombDeploy[client].player = client;
	}
}

void SDKHooks_OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "func_capturezone"))
	{
		SDKHook(entity, SDKHook_StartTouch, SDKHookCB_CaptureZone_StartTouch);
		SDKHook(entity, SDKHook_EndTouch, SDKHookCB_CaptureZone_EndTouch);
		SDKHook(entity, SDKHook_Touch, SDKHookCB_CaptureZone_Touch);
	}
}

public Action SDKHookCB_CaptureZone_StartTouch(int zone, int other)
{
	if (0 < other <= MaxClients && SDKCall_HasTheFlag(other))
	{
		g_bombDeploy[other].Start();
	}
	
	return Plugin_Continue;
}

public Action SDKHookCB_CaptureZone_EndTouch(int zone, int other)
{
	if (0 < other <= MaxClients && SDKCall_HasTheFlag(other))
	{
		g_bombDeploy[other].End();
	}
	
	return Plugin_Continue;
}

public Action SDKHookCB_CaptureZone_Touch(int zone, int other)
{
	if (0 < other <= MaxClients && SDKCall_HasTheFlag(other))
	{
		g_bombDeploy[other].Update();
	}
	
	return Plugin_Continue;
}
