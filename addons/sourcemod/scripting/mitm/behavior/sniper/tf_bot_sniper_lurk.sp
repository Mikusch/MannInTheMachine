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

static NextBotActionFactory ActionFactory;

methodmap CTFBotSniperLurk < NextBotAction
{
	public static void Init()
	{
		ActionFactory = new NextBotActionFactory("SniperLurk");
		ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
	}
	
	public CTFBotSniperLurk()
	{
		return view_as<CTFBotSniperLurk>(ActionFactory.Create());
	}
}

static int OnStart(CTFBotSniperLurk action, int actor, NextBotAction priorAction)
{
	// This action is only here to avoid Sniper bots spawning with the flag.
	// Maybe in the future we have something to put here.
	return action.Done();
}
