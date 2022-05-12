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
 
MvMBombDeploy bombDeploy;

void SDKHooks_HookClient(int client)
{
	SDKHook(client, SDKHook_WeaponCanSwitchTo, SDKHookCB_Client_WeaponCanSwitchTo);
}

void SDKHooks_OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "func_capturezone"))
	{
		SDKHook(entity, SDKHook_StartTouch, SDKHookCB_CaptureZone_StartTouch);
		SDKHook(entity, SDKHook_Touch, SDKHookCB_CaptureZone_Touch);
	}
}

public Action SDKHookCB_Client_WeaponCanSwitchTo(int client, int weapon)
{
	if (Player(client).IsWeaponRestricted(weapon))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action SDKHookCB_CaptureZone_StartTouch(int zone, int other)
{
	if (GameRules_IsMannVsMachineMode() && 0 < other <= MaxClients && SDKCall_HasTheFlag(other))
	{
		bombDeploy.Reset();
		bombDeploy.Start(other);
	}
	
	return Plugin_Continue;
}

public Action SDKHookCB_CaptureZone_Touch(int zone, int other)
{
	if (GameRules_IsMannVsMachineMode() && 0 < other <= MaxClients && SDKCall_HasTheFlag(other))
	{
		bombDeploy.Update(other);
	}
	
	return Plugin_Continue;
}
