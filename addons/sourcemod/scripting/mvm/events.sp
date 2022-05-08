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

void Events_Initialize()
{
	HookEvent("player_death", EventHook_PlayerDeath);
}

public void EventHook_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int victim = GetClientOfUserId(userid);
	
	if (TF2_GetClientTeam(victim) == TFTeam_Invaders)
	{
		Player(victim).StopIdleSound();
		
		// CTFBotDead::Update
		CreateTimer(5.0, Timer_DeadTimer, userid);
	}
}

public Action Timer_DeadTimer(Handle timer, int userid)
{
	int player = GetClientOfUserId(userid);
	if (player == 0)
		return Plugin_Continue;
	
	if (Player(player).HasAttribute(REMOVE_ON_DEATH))
	{
		ServerCommand("kickid %d", userid);
	}
	else if (Player(player).HasAttribute(BECOME_SPECTATOR_ON_DEATH))
	{
		TF2_ChangeClientTeam(player, TFTeam_Spectator);
	}
	
	return Plugin_Continue;
}
