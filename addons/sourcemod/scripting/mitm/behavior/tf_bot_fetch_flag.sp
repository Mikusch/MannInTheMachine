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

void CTFBotFetchFlag_Update(int me)
{
	int flag = Player(me).GetFlagToFetch();
	
	if (flag == -1)
	{
		// no flag
		return;
	}
	
	if (GameRules_IsMannVsMachineMode() && GetEntProp(flag, Prop_Send, "m_nFlagStatus") == TF_FLAGINFO_HOME)
	{
		if (GetGameTime() - GetEntDataFloat(me, GetOffset("CTFPlayer::m_flSpawnTime")) < 1.0 && TF2_GetClientTeam(me) != TFTeam_Spectator)
		{
			// we just spawned - give us the flag
			SDKCall_PickUp(flag, me, true);
		}
	}
}
