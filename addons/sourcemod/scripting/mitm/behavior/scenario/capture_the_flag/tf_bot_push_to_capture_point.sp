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

methodmap CTFBotPushToCapturePoint < NextBotAction
{
	public static void Init()
	{
		ActionFactory = new NextBotActionFactory("PushToCapturePoint");
		ActionFactory.BeginDataMapDesc()
			.DefineIntField("m_nextAction")
		.EndDataMapDesc();
		ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
	}
	
	public CTFBotPushToCapturePoint(NextBotAction nextAction = NULL_ACTION)
	{
		CTFBotPushToCapturePoint action = view_as<CTFBotPushToCapturePoint>(ActionFactory.Create());
		action.m_nextAction = nextAction;
		return action;
	}
	
	property NextBotAction m_nextAction
	{
		public get()
		{
			return this.GetData("m_nextAction");
		}
		public set(NextBotAction nextAction)
		{
			this.SetData("m_nextAction", nextAction);
		}
	}
}

static int Update(CTFBotPushToCapturePoint action, int actor, float interval)
{
	// flag collection and delivery is handled by our parent behavior, ScenarioMonitor
	
	int zone = CTFPlayer(actor).GetFlagCaptureZone();
	
	if (!IsValidEntity(zone))
	{
		if (action.m_nextAction)
		{
			return action.ChangeTo(action.m_nextAction, "No flag capture zone exists!");
		}
		
		return action.Done("No flag capture zone exists!");
	}
	
	float zoneCenter[3], actorOrigin[3];
	CBaseEntity(zone).WorldSpaceCenter(zoneCenter);
	GetClientAbsOrigin(actor, actorOrigin);
	
	float toZone[3];
	SubtractVectors(zoneCenter, actorOrigin, toZone);
	if (GetVectorLength(toZone) < 50.0)
	{
		if (action.m_nextAction)
		{
			return action.ChangeTo(action.m_nextAction, "At destination");
		}
		
		return action.Done("At destination");
	}
	
	return action.Continue();
}
