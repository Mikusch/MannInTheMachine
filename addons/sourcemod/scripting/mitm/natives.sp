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

void Natives_Init()
{
	CreateNative("MannInTheMachinePlayer.HasPreference", Native_HasPreference);
	
	CreateNative("MannInTheMachine_IsInEndlessWaves", Native_IsInEndlessWaves);
	CreateNative("MannInTheMachine_IsInWaitingForPlayers", Native_IsInWaitingForPlayers);
}

static int Native_HasPreference(Handle plugin, int numParams)
{
	int client = GetNativeInGameClient(1);
	MannInTheMachinePreference preference = GetNativeCell(2);
	
	return CTFPlayer(client).HasPreference(preference);
}

static int Native_IsInEndlessWaves(Handle plugin, int numParams)
{
	if (!g_pPopulationManager.IsValid())
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Population manager entity %d is not valid", g_pPopulationManager.index);
	}
	
	return g_pPopulationManager.IsInEndlessWaves();
}

static int Native_IsInWaitingForPlayers(Handle plugin, int numParams)
{
	return g_bInWaitingForPlayers;
}

static int GetNativeInGameClient(int param)
{
	int client = GetNativeCell(param);
	if (!IsEntityClient(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is not valid (param %d)", client, param);
	}
	else if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is not in game (param %d)", client, param);
	}
	return client;
}
