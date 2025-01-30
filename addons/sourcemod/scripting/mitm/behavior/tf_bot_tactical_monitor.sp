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

methodmap CTFBotTacticalMonitor < NextBotAction
{
	public static void Init()
	{
		ActionFactory = new NextBotActionFactory("TacticalMonitor");
		ActionFactory.SetCallback(NextBotActionCallbackType_InitialContainedAction, InitialContainedAction);
		ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
	}
	
	public CTFBotTacticalMonitor()
	{
		return view_as<CTFBotTacticalMonitor>(ActionFactory.Create());
	}
}

static NextBotAction InitialContainedAction(CTFBotTacticalMonitor action, int actor)
{
	return CTFBotScenarioMonitor();
}

static int Update(CTFBotTacticalMonitor action, int actor, float interval)
{
	NextBotAction result = CTFPlayer(actor).OpportunisticallyUseWeaponAbilities();
	if (result)
	{
		return action.SuspendFor(result, "Opportunistically using buff item");
	}
	
	CTFPlayer(actor).UpdateDelayedThreatNotices();
	
	return action.Continue();
}
