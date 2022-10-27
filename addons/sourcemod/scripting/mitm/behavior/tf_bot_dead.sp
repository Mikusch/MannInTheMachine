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

methodmap CTFBotDead < NextBotAction
{
	public static void Init()
	{
		ActionFactory = new NextBotActionFactory("Dead");
		ActionFactory.BeginDataMapDesc()
			.DefineIntField("m_deadTimer")
		.EndDataMapDesc();
		ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
		ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
		ActionFactory.SetCallback(NextBotActionCallbackType_OnEnd, OnEnd);
	}
	
	public CTFBotDead()
	{
		CTFBotDead action = view_as<CTFBotDead>(ActionFactory.Create());
		action.m_deadTimer = new IntervalTimer();
		return action;
	}
	
	property IntervalTimer m_deadTimer
	{
		public get()
		{
			return this.GetData("m_deadTimer");
		}
		public set(IntervalTimer deadTimer)
		{
			this.SetData("m_deadTimer", deadTimer);
		}
	}
}

static int OnStart(CTFBotDead action, int actor, NextBotAction priorAction)
{
	return action.Continue();
}

static int Update(CTFBotDead action, int actor, float interval)
{
	if (IsPlayerAlive(actor))
	{
		// how did this happen?
		return action.ChangeTo(CTFBotMainAction(), "This should not happen!");
	}
	
	if (action.m_deadTimer.IsGreaterThan(5.0))
	{
		if (Player(actor).HasAttribute(REMOVE_ON_DEATH))
		{
			// remove dead bots
			ServerCommand("kickid %d", GetClientUserId(actor));
		}
		else if (Player(actor).HasAttribute(BECOME_SPECTATOR_ON_DEATH))
		{
			g_bAllowTeamChange = true;
			TF2_ChangeClientTeam(actor, TFTeam_Spectator);
			g_bAllowTeamChange = false;
			return action.Done();
		}
	}
	
	return action.Continue();
}

static void OnEnd(CTFBotDead action, int actor, NextBotAction nextAction)
{
	delete action.m_deadTimer;
}
