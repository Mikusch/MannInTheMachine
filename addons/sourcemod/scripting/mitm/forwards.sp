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

static GlobalForward g_hForwardOnIsValidDefender;
static GlobalForward g_hForwardOnIsValidMiniBoss;
static GlobalForward g_hForwardOnSentryBusterDetonate;
static GlobalForward g_hForwardOnTankDeployed;

void Forwards_Init()
{
	g_hForwardOnIsValidDefender = new GlobalForward("MannInTheMachine_OnIsValidDefender", ET_Single, Param_Cell);
	g_hForwardOnIsValidMiniBoss = new GlobalForward("MannInTheMachine_OnIsValidMiniBoss", ET_Single, Param_Cell);
	g_hForwardOnSentryBusterDetonate = new GlobalForward("MannInTheMachine_OnSentryBusterDetonate", ET_Single, Param_Cell, Param_Cell);
	g_hForwardOnTankDeployed = new GlobalForward("MannInTheMachine_OnTankDeployed", ET_Single, Param_Cell);
}

bool Forwards_OnIsValidDefender(int client)
{
	bool bReturnVal = true;
	
	Call_StartForward(g_hForwardOnIsValidDefender);
	Call_PushCell(client);
	Call_Finish(bReturnVal);
	
	return bReturnVal;
}

bool Forwards_OnIsValidMiniBoss(int client)
{
	bool bReturnVal = true;
	
	Call_StartForward(g_hForwardOnIsValidMiniBoss);
	Call_PushCell(client);
	Call_Finish(bReturnVal);
	
	return bReturnVal;
}

void Forwards_OnSentryBusterDetonate(int client, int victim)
{
	Call_StartForward(g_hForwardOnSentryBusterDetonate);
	Call_PushCell(client);
	Call_PushCell(victim);
	Call_Finish();
}

void Forwards_OnTankDeployed(int tank)
{
	Call_StartForward(g_hForwardOnTankDeployed);
	Call_PushCell(tank);
	Call_Finish();
}
