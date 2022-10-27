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

methodmap CTFBotTaunt < NextBotAction
{
	public static void Init()
	{
		ActionFactory = new NextBotActionFactory("Taunt");
		ActionFactory.BeginDataMapDesc()
			.DefineIntField("m_tauntTimer")
			.DefineIntField("m_tauntEndTimer")
			.DefineBoolField("m_didTaunt")
		.EndDataMapDesc();
		ActionFactory.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
		ActionFactory.SetCallback(NextBotActionCallbackType_Update, Update);
		ActionFactory.SetCallback(NextBotActionCallbackType_OnEnd, OnEnd);
	}
	
	public CTFBotTaunt()
	{
		CTFBotTaunt action = view_as<CTFBotTaunt>(ActionFactory.Create());
		action.m_tauntTimer = new CountdownTimer();
		action.m_tauntEndTimer = new CountdownTimer();
		return action;
	}
	
	property CountdownTimer m_tauntTimer
	{
		public get()
		{
			return this.GetData("m_tauntTimer");
		}
		public set(CountdownTimer tauntTimer)
		{
			this.SetData("m_tauntTimer", tauntTimer);
		}
	}
	
	property CountdownTimer m_tauntEndTimer
	{
		public get()
		{
			return this.GetData("m_tauntEndTimer");
		}
		public set(CountdownTimer tauntEndTimer)
		{
			this.SetData("m_tauntEndTimer", tauntEndTimer);
		}
	}
	
	property bool m_didTaunt
	{
		public get()
		{
			return this.GetData("m_didTaunt");
		}
		public set(bool didTaunt)
		{
			this.SetData("m_didTaunt", didTaunt);
		}
	}
}

static int OnStart(CTFBotTaunt action, int actor, NextBotAction priorAction)
{
	action.m_tauntTimer.Start(GetRandomFloat(0.0, 1.0));
	action.m_didTaunt = false;
	
	return action.Continue();
}

static int Update(CTFBotTaunt action, int actor, float interval)
{
	if (action.m_tauntTimer.IsElapsed())
	{
		if (action.m_didTaunt)
		{
			// Stop taunting after a while
			if (action.m_tauntEndTimer.IsElapsed() && view_as<taunts_t>(GetEntProp(actor, Prop_Send, "m_iTauntIndex")) == TAUNT_LONG)
			{
				FakeClientCommand(actor, "stop_taunt");
			}
			
			if (TF2_IsPlayerInCondition(actor, TFCond_Taunting) == false)
			{
				return action.Done("Taunt finished");
			}
		}
		else
		{
			FakeClientCommand(actor, "taunt");
			// Start a timer to end our taunt in case we're still going after awhile
			action.m_tauntEndTimer.Start(GetRandomFloat(3.0, 5.0));
			
			action.m_didTaunt = true;
		}
	}
	
	return action.Continue();
}

static void OnEnd(CTFBotTaunt action, int actor, NextBotAction nextAction)
{
	delete action.m_tauntTimer;
	delete action.m_tauntEndTimer;
}
