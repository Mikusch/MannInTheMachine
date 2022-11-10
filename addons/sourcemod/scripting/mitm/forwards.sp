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

static GlobalForward g_forwardOnIsValidDefender;
static GlobalForward g_forwardOnIsValidInvader;

void Forwards_Init()
{
	g_forwardOnIsValidDefender = new GlobalForward("MannInTheMachine_OnIsValidDefender", ET_Single, Param_Cell);
	g_forwardOnIsValidInvader = new GlobalForward("MannInTheMachine_OnIsValidInvader", ET_Single, Param_Cell, Param_Cell);
}

bool Forwards_OnIsValidDefender(int client)
{
	bool bReturnVal = true;
	
	Call_StartForward(g_forwardOnIsValidDefender);
	Call_PushCell(client);
	Call_Finish(bReturnVal);
	
	return bReturnVal;
}

bool Forwards_OnIsValidInvader(int client, bool bIsMiniboss)
{
	bool bReturnVal = true;
	
	Call_StartForward(g_forwardOnIsValidInvader);
	Call_PushCell(client);
	Call_PushCell(bIsMiniboss);
	Call_Finish(bReturnVal);
	
	return bReturnVal;
}
