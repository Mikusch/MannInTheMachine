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

void SendProxy_OnClientPutInServer(int client)
{
	if (!LibraryExists(SENDPROXY_LIB))
		return;
	
	SendProxy_HookArrayProp(client, "m_nModelIndexOverrides", 0, Prop_Int, SendProxyCallback_ModelIndexOverrides);
}

static Action SendProxyCallback_ModelIndexOverrides(const int entity, const char[] propName, int &value, const int element, const int client)
{
	if (TF2_IsPlayerInCondition(entity, TFCond_Disguised) &&
		Player(entity).GetDisguiseTeam() == TFTeam_Invaders &&
		GetEnemyTeam(TF2_GetClientTeam(entity)) == TF2_GetClientTeam(client))
	{
		// when disguised as an invader, appear as a robot to enemies
		int nDisguiseClass = GetEntProp(entity, Prop_Send, "m_nDisguiseClass");
		value = PrecacheModel(g_szBotModels[nDisguiseClass]);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}
